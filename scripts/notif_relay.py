#!/usr/bin/env python3
"""
notif_relay.py — Relay Notifikasi

Menerima webhook dari Airbyte lalu menerjemahkannya menjadi pesan Telegram.
Airbyte tidak bisa memanggil Telegram Bot API secara langsung (bentuk payload
berbeda), jadi layanan kecil ini yang menjembatani.

Bersifat *best-effort* (lihat docs/adr/0001-notifikasi-telegram-best-effort.md):
selalu membalas 200 ke Airbyte seketika, lalu mengirim ke Telegram di thread
background dengan retry backoff. Kegagalan final hanya ditulis ke log —
pesannya hilang, Airbyte tidak pernah dibuat menganggap job bermasalah.

Satu webhook (satu Job) = satu pesan Telegram.

Sekaligus bot dua arah: loop long-polling getUpdates menerima perintah dari grup
TELEGRAM_CHAT_ID (/split, /dbt, /status, /logs, /help) lalu memicu job lewat
server kontrol HTTP internal di gisnet — bukan lewat Docker socket. Lihat
docs/adr/0002-trigger-job-via-telegram.md dan scripts/job_control.py.

Endpoint:
  POST <apa saja>   -- terima webhook Airbyte, balas 200 seketika
  GET  /            -- health check, balas 200 "ok"

Konfigurasi via environment (lihat .env.example):
  TELEGRAM_BOT_TOKEN            (wajib)
  TELEGRAM_CHAT_ID             (wajib) -- id grup/chat tujuan sekaligus satu-satunya
                                          chat yang perintahnya dilayani
  NOTIF_RELAY_PORT             (opsional, default 8000)
  TELEGRAM_MAX_RETRIES         (opsional, default 3)
  TELEGRAM_RETRY_BACKOFF_SECONDS (opsional, default 3)
  TELEGRAM_BOT_ENABLED         (opsional, default true) -- matikan loop perintah
  SPLIT_CONTROL_URL            (opsional, default http://split-excel:8080)
  DBT_CONTROL_URL              (opsional, default http://dbt-runner:8080)
  TELEGRAM_POLL_TIMEOUT        (opsional, default 50)
"""

import html
import json
import logging
import os
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import requests
from dotenv import load_dotenv

load_dotenv()

# ── Logging ────────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("notif_relay")

# ── Konfigurasi ─────────────────────────────────────────────────────────────

def _wajib(nama: str) -> str:
    """
    Ambil env var wajib. Kalau kosong: satu baris log yang jelas lalu keluar
    dengan kode 78 (EX_CONFIG) — bukan traceback KeyError. Compose memakai
    restart: on-failure:3 untuk service ini, jadi salah konfigurasi berhenti
    setelah beberapa percobaan alih-alih crash-loop tanpa henti.
    """
    nilai = os.getenv(nama, "").strip()
    if not nilai:
        log.error(
            "%s belum diisi. Set %s di .env (lihat .env.example), lalu: "
            "docker compose up -d notif-relay",
            nama, nama,
        )
        raise SystemExit(78)
    return nilai


TELEGRAM_BOT_TOKEN = _wajib("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID   = _wajib("TELEGRAM_CHAT_ID")

PORT            = int(os.getenv("NOTIF_RELAY_PORT", "8000"))
MAX_RETRIES     = int(os.getenv("TELEGRAM_MAX_RETRIES", "3"))
RETRY_BACKOFF   = float(os.getenv("TELEGRAM_RETRY_BACKOFF_SECONDS", "3"))
TELEGRAM_BASE   = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"
TELEGRAM_API    = f"{TELEGRAM_BASE}/sendMessage"
REQUEST_TIMEOUT = 15  # detik, per-attempt ke api.telegram.org

# ── Bot (perintah dari Telegram) ────────────────────────────────────────────
# Job yang bisa dipicu; masing-masing menjalankan server kontrol job_control di
# gisnet. Relay TIDAK menyentuh Docker socket — lihat docs/adr/0002.
JOBS = {
    "split": os.getenv("SPLIT_CONTROL_URL", "http://split-excel:8080").rstrip("/"),
    "dbt":   os.getenv("DBT_CONTROL_URL", "http://dbt-runner:8080").rstrip("/"),
}
POLL_TIMEOUT   = int(os.getenv("TELEGRAM_POLL_TIMEOUT", "50"))   # long-poll getUpdates
WATCH_INTERVAL = int(os.getenv("JOB_WATCH_INTERVAL_SECONDS", "10"))
_MATI = ("0", "false", "no", "off")
BOT_ENABLED = os.getenv("TELEGRAM_BOT_ENABLED", "true").strip().lower() not in _MATI
# Pemantau job: laporkan setiap run yang selesai ke grup, termasuk run terjadwal
# split-excel yang tidak dipicu dari Telegram.
JOB_WATCH_ENABLED = os.getenv("JOB_WATCH_ENABLED", "true").strip().lower() not in _MATI


# ── Format pesan ────────────────────────────────────────────────────────────

def _fmt_duration(seconds) -> str:
    """Ubah durasi (detik) menjadi string ringkas, mis. '1m 30s'."""
    try:
        seconds = int(seconds)
    except (TypeError, ValueError):
        return "-"
    if seconds < 60:
        return f"{seconds}s"
    menit, detik = divmod(seconds, 60)
    return f"{menit}m {detik}s"


def format_message(payload: dict) -> str:
    """
    Ubah payload webhook Airbyte menjadi pesan Telegram (parse_mode HTML).

    Defensif terhadap beberapa bentuk payload:
      - Custom webhook Airbyte terbaru: field terstruktur di bawah `data`.
      - Notifikasi gaya Slack/legacy: hanya berisi field `text`.
      - Bentuk lain: dump JSON mentah agar tidak ada event yang hilang diam-diam.
    """
    # Bentuk Slack/legacy: teruskan apa adanya.
    text = payload.get("text")
    if text and not payload.get("data"):
        return html.escape(str(text))

    data = payload.get("data") or payload

    def g(*keys, default="-"):
        for k in keys:
            v = data.get(k)
            if v not in (None, ""):
                return v
        return default

    def name_of(obj):
        if isinstance(obj, dict):
            return obj.get("name") or obj.get("id") or "-"
        return obj if obj not in (None, "") else "-"

    # Tentukan sukses/gagal. `success` bila ada; jika tidak, tebak dari errorMessage.
    success = data.get("success")
    if success is None:
        success = not (data.get("errorMessage") or data.get("errorType"))

    connection  = name_of(data.get("connection"))
    source      = name_of(data.get("source"))
    destination = name_of(data.get("destination"))
    job_id      = g("jobId", "job_id")
    records     = g("recordsCommitted", "recordsEmitted", "records_committed")
    duration    = _fmt_duration(data.get("durationInSeconds"))

    e = lambda v: html.escape(str(v))

    if success:
        lines = [
            "✅ <b>Airbyte sync berhasil</b>",
            f"Koneksi: <b>{e(connection)}</b>",
            f"{e(source)} → {e(destination)}",
            f"Job: <code>{e(job_id)}</code>",
            f"Records: {e(records)}",
            f"Durasi: {e(duration)}",
        ]
    else:
        error_msg = g("errorMessage", "errorType", default="(tidak ada detail)")
        lines = [
            "❌ <b>Airbyte sync GAGAL</b>",
            f"Koneksi: <b>{e(connection)}</b>",
            f"{e(source)} → {e(destination)}",
            f"Job: <code>{e(job_id)}</code>",
            f"Durasi: {e(duration)}",
            f"Error: {e(error_msg)}",
        ]
    return "\n".join(lines)


# ── Pengiriman ke Telegram (background, best-effort) ────────────────────────

def send_telegram(text: str, chat_id=None, reply_to=None) -> None:
    """
    Kirim satu pesan ke Telegram dengan retry linear backoff.
    Dipanggil dari thread background; kegagalan final hanya di-log.

    chat_id/reply_to opsional dipakai balasan perintah bot; default-nya tetap
    grup TELEGRAM_CHAT_ID sehingga jalur notifikasi Airbyte tidak berubah.
    """
    body = {
        "chat_id": chat_id or TELEGRAM_CHAT_ID,
        "text": text,
        "parse_mode": "HTML",
        "disable_web_page_preview": True,
    }
    if reply_to:
        body["reply_to_message_id"] = reply_to
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = requests.post(TELEGRAM_API, json=body, timeout=REQUEST_TIMEOUT)
            if resp.ok:
                log.info("Pesan Telegram terkirim (attempt %d/%d).", attempt, MAX_RETRIES)
                return
            log.warning(
                "Telegram membalas %s (attempt %d/%d): %s",
                resp.status_code, attempt, MAX_RETRIES, resp.text[:300],
            )
        except requests.RequestException as exc:
            log.warning(
                "Gagal menghubungi Telegram (attempt %d/%d): %s",
                attempt, MAX_RETRIES, exc,
            )
        if attempt < MAX_RETRIES:
            time.sleep(RETRY_BACKOFF * attempt)

    log.error("Pesan Telegram dijatuhkan setelah %d percobaan (best-effort).", MAX_RETRIES)


def dispatch(payload: dict) -> None:
    """Format lalu kirim di thread ini (sudah dipanggil dari thread background)."""
    try:
        text = format_message(payload)
    except Exception:  # noqa: BLE001 -- jangan pernah menjatuhkan thread relay
        log.exception("Gagal memformat payload; mengirim dump mentah.")
        text = html.escape(json.dumps(payload, ensure_ascii=False)[:3500])
    send_telegram(text)


# ── Bot: perintah dari grup Telegram ────────────────────────────────────────

BANTUAN = (
    "<b>Perintah yang tersedia</b>\n"
    "/split — jalankan split-excel untuk semua folder di NEXTCLOUD_SOURCE_PATHS\n"
    "/split <i>A1/Finance</i> — hanya folder tertentu (relatif ke NEXTCLOUD_SOURCE_HOME, "
    "boleh beberapa dipisah spasi)\n"
    "/dbt — jalankan <code>dbt run</code>\n"
    "/status — job sedang jalan atau tidak, plus hasil run terakhir\n"
    "/logs [split|dbt] — ekor log run terakhir\n"
    "/help — pesan ini"
)


def _fmt_waktu(ts) -> str:
    if not ts:
        return "-"
    return time.strftime("%d/%m %H:%M:%S", time.localtime(ts))


def _ringkas_status(nama: str, st: dict) -> str:
    if st.get("running"):
        return f"⏳ <b>{nama}</b>: berjalan ({_fmt_duration(st.get('duration_s'))})"
    if st.get("last_finished") is None:
        return f"💤 <b>{nama}</b>: belum pernah jalan sejak service start"
    tanda = "✅" if st.get("last_ok") else "❌"
    return (
        f"{tanda} <b>{nama}</b>: selesai {_fmt_waktu(st.get('last_finished'))} "
        f"({_fmt_duration(st.get('duration_s'))})"
    )


def _lapor_selesai(nama: str, st: dict) -> None:
    """Kirim satu pesan hasil run ke grup."""
    base = JOBS[nama]
    durasi = _fmt_duration(st.get("duration_s"))
    sumber = st.get("last_params", {}).get("sources")
    rincian = ""
    if sumber:
        rincian = "\n" + "\n".join(f"• {html.escape(str(s))}" for s in sumber)

    if st.get("last_ok"):
        send_telegram(f"✅ <b>{nama}</b> selesai ({durasi}).{rincian}")
        return

    ekor = ""
    try:
        teks = requests.get(f"{base}/logs", timeout=REQUEST_TIMEOUT).text
        ekor = "\n".join(teks.splitlines()[-15:])
    except Exception as exc:  # noqa: BLE001
        log.warning("Gagal ambil log %s: %s", nama, exc)
    pesan = f"❌ <b>{nama}</b> GAGAL ({durasi}).{rincian}"
    if ekor:
        pesan += f"\n<pre>{html.escape(ekor[:3000])}</pre>"
    send_telegram(pesan)


def watch_jobs() -> None:
    """
    Pantau semua job terus-menerus dan laporkan setiap run yang selesai ke grup.

    Satu pemantau untuk semua asal-usul run — dipicu dari Telegram, dari jadwal
    --watch split-excel, atau dari curl. Pendekatan poll dipilih supaya split-excel
    tidak perlu tahu apa pun soal Telegram (token tetap hanya di relay ini).

    `last_finished` dipakai sebagai penanda run: nilainya berubah tepat sekali per
    run selesai, jadi tidak ada pesan dobel. Nilai awal diambil saat start supaya
    run yang sudah lama selesai tidak diumumkan ulang setiap relay restart.
    """
    terakhir = {}
    for nama, base in JOBS.items():
        try:
            terakhir[nama] = requests.get(
                f"{base}/status", timeout=REQUEST_TIMEOUT
            ).json().get("last_finished")
        except Exception:  # noqa: BLE001 -- job belum siap saat relay start
            terakhir[nama] = None

    log.info("Pemantau job aktif (%s); hasil run dikirim ke grup.", ", ".join(JOBS))

    while True:
        time.sleep(WATCH_INTERVAL)
        for nama, base in JOBS.items():
            try:
                st = requests.get(f"{base}/status", timeout=REQUEST_TIMEOUT).json()
            except Exception as exc:  # noqa: BLE001
                log.debug("Gagal cek status %s: %s", nama, exc)
                continue

            selesai = st.get("last_finished")
            if selesai is None or selesai == terakhir.get(nama):
                continue

            terakhir[nama] = selesai
            try:
                _lapor_selesai(nama, st)
            except Exception:  # noqa: BLE001 -- satu laporan gagal != pemantau mati
                log.exception("Gagal melaporkan hasil %s.", nama)


def mulai_job(nama: str, args: list, chat_id, reply_to) -> None:
    """Panggil POST /run pada control server job, lalu balas ke Telegram."""
    base = JOBS[nama]
    body = {}
    if nama == "split" and args:
        # Diteruskan apa adanya — validasi path hanya hidup di resolve_source()
        # milik split-excel, supaya tidak ada dua aturan yang bisa berbeda.
        body["sources"] = args
    elif nama == "dbt" and args:
        body["select"] = " ".join(args)

    try:
        resp = requests.post(f"{base}/run", json=body, timeout=REQUEST_TIMEOUT)
    except requests.RequestException as exc:
        send_telegram(
            f"❌ Tidak bisa menghubungi <b>{nama}</b>: {html.escape(str(exc)[:300])}",
            chat_id, reply_to,
        )
        return

    if resp.status_code == 202:
        rincian = ""
        if body.get("sources"):
            rincian = "\n" + "\n".join(f"• {html.escape(s)}" for s in body["sources"])
        elif body.get("select"):
            rincian = f"\n<code>--select {html.escape(body['select'])}</code>"
        # Hasilnya dilaporkan oleh watch_jobs(), bukan di sini — supaya run
        # terjadwal dan run manual sama-sama dapat satu pesan, tanpa dobel.
        send_telegram(f"▶️ <b>{nama}</b> dimulai.{rincian}", chat_id, reply_to)
    elif resp.status_code == 409:
        send_telegram(f"⏳ <b>{nama}</b> masih berjalan; permintaan diabaikan.",
                      chat_id, reply_to)
    else:
        try:
            alasan = resp.json().get("error", resp.text)
        except ValueError:
            alasan = resp.text
        send_telegram(
            f"❌ <b>{nama}</b> ditolak ({resp.status_code}): "
            f"{html.escape(str(alasan)[:500])}",
            chat_id, reply_to,
        )


def kirim_status(chat_id, reply_to) -> None:
    baris = []
    for nama, base in JOBS.items():
        try:
            st = requests.get(f"{base}/status", timeout=REQUEST_TIMEOUT).json()
            baris.append(_ringkas_status(nama, st))

            # Config aktif ikut ditampilkan: kalau container masih memakai .env
            # atau image lama (mis. setelah `docker compose restart`), di sinilah
            # kelihatan — tanpa perlu akses SSH ke server.
            info = st.get("info") or {}
            if info.get("source_home") is not None:
                baris.append(f"   home: <code>{html.escape(str(info['source_home']))}</code>")
            elif "source_home" in info:
                baris.append("   home: <i>(kosong — NEXTCLOUD_SOURCE_HOME belum di-set)</i>")
            if info.get("sources"):
                baris.append("   sumber: " + ", ".join(
                    f"<code>{html.escape(str(s))}</code>" for s in info["sources"]
                ))
            if "fitur" not in info and nama == "split":
                baris.append("   ⚠️ <i>image lama: argumen path pada /split belum didukung</i>")
        except Exception as exc:  # noqa: BLE001
            baris.append(f"⚠️ <b>{nama}</b>: tidak bisa dihubungi ({html.escape(str(exc)[:120])})")
    send_telegram("\n".join(baris), chat_id, reply_to)


def kirim_logs(args: list, chat_id, reply_to) -> None:
    nama = (args[0] if args else "split").lower()
    if nama not in JOBS:
        send_telegram(f"Job tidak dikenal: {html.escape(nama)}. "
                      f"Pilihan: {', '.join(JOBS)}", chat_id, reply_to)
        return
    try:
        teks = requests.get(f"{JOBS[nama]}/logs", timeout=REQUEST_TIMEOUT).text
    except requests.RequestException as exc:
        send_telegram(f"❌ Gagal ambil log {nama}: {html.escape(str(exc)[:300])}",
                      chat_id, reply_to)
        return
    ekor = "\n".join(teks.splitlines()[-30:]) or "(belum ada log)"
    send_telegram(f"<b>Log {nama}</b>\n<pre>{html.escape(ekor[:3500])}</pre>",
                  chat_id, reply_to)


def handle_command(message: dict) -> None:
    chat = message.get("chat") or {}
    chat_id = chat.get("id")
    teks = (message.get("text") or "").strip()
    if not teks.startswith("/"):
        return

    # Otorisasi: bot bisa di-DM siapa saja yang tahu username-nya, jadi hanya
    # grup TELEGRAM_CHAT_ID yang dilayani. Chat lain diabaikan diam-diam.
    if str(chat_id) != str(TELEGRAM_CHAT_ID):
        log.warning("Perintah %r dari chat %s diabaikan (bukan TELEGRAM_CHAT_ID).",
                    teks.split()[0], chat_id)
        return

    bagian = teks.split()
    perintah = bagian[0].lstrip("/").split("@", 1)[0].lower()  # /split@NamaBot
    args = [a for a in bagian[1:] if a.strip(",")]
    args = [a.strip(",") for a in args]
    reply_to = message.get("message_id")

    if perintah in ("help", "start"):
        send_telegram(BANTUAN, chat_id, reply_to)
    elif perintah == "status":
        kirim_status(chat_id, reply_to)
    elif perintah == "logs":
        kirim_logs(args, chat_id, reply_to)
    elif perintah in JOBS:
        mulai_job(perintah, args, chat_id, reply_to)
    else:
        send_telegram(f"Perintah tidak dikenal: <code>/{html.escape(perintah)}</code>\n\n"
                      f"{BANTUAN}", chat_id, reply_to)


def poll_updates() -> None:
    """
    Loop long-polling getUpdates.

    Dipilih ketimbang webhook karena tidak butuh URL publik/HTTPS. Konsekuensinya:
    token ini tidak boleh punya webhook terpasang, dan hanya boleh ada satu proses
    yang polling per token (Telegram membalas 409 kalau ada dua).
    """
    offset = None
    log.info("Bot polling aktif (job: %s).", ", ".join(JOBS))
    while True:
        try:
            resp = requests.get(
                f"{TELEGRAM_BASE}/getUpdates",
                params={
                    "timeout": POLL_TIMEOUT,
                    "offset": offset,
                    "allowed_updates": json.dumps(["message"]),
                },
                timeout=POLL_TIMEOUT + 15,
            )
            if resp.status_code in (401, 404):
                # Token salah/dicabut: retry tidak akan pernah berhasil. Hentikan
                # loop perintah, tapi biarkan relay webhook Airbyte tetap jalan.
                log.error(
                    "getUpdates ditolak (%s): TELEGRAM_BOT_TOKEN tidak valid. "
                    "Bot perintah dimatikan; relay webhook tetap berjalan.",
                    resp.status_code,
                )
                return
            if resp.status_code == 409:
                # Ada webhook terpasang atau instance lain sedang polling token ini.
                log.error("getUpdates konflik (409): %s", resp.text[:300])
                time.sleep(RETRY_BACKOFF * 10)
                continue
            if not resp.ok:
                log.warning("getUpdates membalas %s: %s", resp.status_code, resp.text[:300])
                time.sleep(RETRY_BACKOFF)
                continue

            for update in resp.json().get("result", []):
                offset = update["update_id"] + 1
                message = update.get("message")
                if not message:
                    continue
                try:
                    handle_command(message)
                except Exception:  # noqa: BLE001 -- satu perintah gagal != bot mati
                    log.exception("Gagal memproses perintah.")
        except requests.RequestException as exc:
            log.warning("getUpdates gagal: %s", exc)
            time.sleep(RETRY_BACKOFF)
        except Exception:  # noqa: BLE001 -- loop bot tidak boleh menjatuhkan relay
            log.exception("Error tak terduga di loop bot.")
            time.sleep(RETRY_BACKOFF)


# ── HTTP server ─────────────────────────────────────────────────────────────

class RelayHandler(BaseHTTPRequestHandler):
    def _ok(self, body: bytes = b"ok"):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):  # noqa: N802 -- health check
        self._ok()

    def do_POST(self):  # noqa: N802
        length = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(length) if length else b""

        # Balas 200 SEKETIKA — Airbyte tidak boleh menunggu Telegram (ADR 0001).
        self._ok()

        try:
            payload = json.loads(raw.decode("utf-8")) if raw else {}
        except (json.JSONDecodeError, UnicodeDecodeError):
            log.warning("Payload webhook bukan JSON valid; diabaikan.")
            return

        if not isinstance(payload, dict):
            payload = {"text": str(payload)}

        # Kirim di background; handler-nya sudah selesai membalas Airbyte.
        threading.Thread(target=dispatch, args=(payload,), daemon=True).start()

    def log_message(self, fmt, *args):  # redam akses-log bawaan yang berisik
        log.debug("%s - %s", self.address_string(), fmt % args)


def main() -> None:
    if BOT_ENABLED:
        threading.Thread(target=poll_updates, daemon=True).start()
    else:
        log.info("Bot Telegram dimatikan (TELEGRAM_BOT_ENABLED=false).")

    if JOB_WATCH_ENABLED:
        threading.Thread(target=watch_jobs, daemon=True).start()
    else:
        log.info("Pemantau job dimatikan (JOB_WATCH_ENABLED=false).")

    server = ThreadingHTTPServer(("0.0.0.0", PORT), RelayHandler)
    log.info("Relay Notifikasi mendengarkan di 0.0.0.0:%d", PORT)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log.info("Dihentikan.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
