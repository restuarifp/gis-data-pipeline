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

Endpoint:
  POST <apa saja>   -- terima webhook Airbyte, balas 200 seketika
  GET  /            -- health check, balas 200 "ok"

Konfigurasi via environment (lihat .env.example):
  TELEGRAM_BOT_TOKEN            (wajib)
  TELEGRAM_CHAT_ID             (wajib) -- id grup/chat tujuan
  NOTIF_RELAY_PORT             (opsional, default 8000)
  TELEGRAM_MAX_RETRIES         (opsional, default 3)
  TELEGRAM_RETRY_BACKOFF_SECONDS (opsional, default 3)
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
TELEGRAM_API    = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
REQUEST_TIMEOUT = 15  # detik, per-attempt ke api.telegram.org


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

def send_telegram(text: str) -> None:
    """
    Kirim satu pesan ke Telegram dengan retry linear backoff.
    Dipanggil dari thread background; kegagalan final hanya di-log.
    """
    body = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": text,
        "parse_mode": "HTML",
        "disable_web_page_preview": True,
    }
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
