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

Selain grup, operator yang id-nya terdaftar di TELEGRAM_DM_USER_IDS boleh memakai
perintah yang sama lewat chat privat; hasil run yang dipicu dari sana ikut dikirim
balik ke chat privat itu, bukan hanya ke grup.

Sekaligus melayani Mini App Telegram: halaman web kecil di GET /app dengan API
JSON di /api/* yang diautentikasi lewat initData (HMAC bot token) — perintah yang
sama dengan bot teks, tapi bisa diklik. Lihat docs/adr/0003-mini-app-telegram.md.

Endpoint:
  GET  /app         -- halaman Mini App (HTML)
  GET  /api/state   -- status semua job + config aktif (butuh initData)
  GET  /api/logs    -- ekor log satu job (butuh initData)
  GET  /api/connections -- daftar koneksi Airbyte (butuh initData)
  POST /api/run     -- picu split/dbt (butuh initData)
  POST /api/sync    -- picu sync Airbyte (butuh initData)
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
  MINI_APP_URL                 (opsional) -- URL HTTPS publik ke /app; kosong = Mini App mati
  MINI_APP_DIRECT_LINK         (opsional) -- https://t.me/<bot>/<app>, dipakai di grup
  MINI_APP_AUTH_MAX_AGE        (opsional, default 86400) -- umur maksimum initData (detik)
  TELEGRAM_DM_USER_IDS         (opsional) -- id user yang boleh memakai bot lewat DM
"""

import hashlib
import hmac
import html
import json
import logging
import os
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

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
# Airbyte (perintah /sync). Airbyte tidak ada di compose stack ini, jadi URL-nya
# harus yang terjangkau DARI DALAM container relay — bukan localhost.
AIRBYTE_URL           = os.getenv("AIRBYTE_URL", "").strip().rstrip("/")
AIRBYTE_CLIENT_ID     = os.getenv("AIRBYTE_CLIENT_ID", "").strip()
AIRBYTE_CLIENT_SECRET = os.getenv("AIRBYTE_CLIENT_SECRET", "").strip()
AIRBYTE_WORKSPACE_ID  = os.getenv("AIRBYTE_WORKSPACE_ID", "").strip()

POLL_TIMEOUT   = int(os.getenv("TELEGRAM_POLL_TIMEOUT", "50"))   # long-poll getUpdates
WATCH_INTERVAL = int(os.getenv("JOB_WATCH_INTERVAL_SECONDS", "10"))
_MATI = ("0", "false", "no", "off")
BOT_ENABLED = os.getenv("TELEGRAM_BOT_ENABLED", "true").strip().lower() not in _MATI
# Pemantau job: laporkan setiap run yang selesai ke grup, termasuk run terjadwal
# split-excel yang tidak dipicu dari Telegram.
JOB_WATCH_ENABLED = os.getenv("JOB_WATCH_ENABLED", "true").strip().lower() not in _MATI

# Mini App. Telegram hanya mau membuka URL HTTPS publik, sementara relay ini
# mendengarkan HTTP di jaringan internal — jadi MINI_APP_URL harus menunjuk ke
# reverse proxy/tunnel yang meneruskan ke /app di sini. Kosong = fitur mati:
# tanpa URL, tombolnya tidak akan pernah bisa dibuka.
MINI_APP_URL         = os.getenv("MINI_APP_URL", "").strip().rstrip("/")
# Tombol web_app hanya boleh muncul di chat privat. Di grup, satu-satunya cara
# membuka Mini App adalah direct link t.me/<bot>/<shortname> (dibuat lewat
# BotFather /newapp) yang dipasang sebagai tombol URL biasa.
MINI_APP_DIRECT_LINK = os.getenv("MINI_APP_DIRECT_LINK", "").strip()
MINI_APP_MAX_AGE     = int(os.getenv("MINI_APP_AUTH_MAX_AGE", "86400"))
MINI_APP_FILE        = Path(os.getenv("MINI_APP_FILE", Path(__file__).with_name("miniapp.html")))


def _daftar_id(nama: str) -> set:
    """
    Baca daftar id numerik dari env (dipisah koma/spasi).

    Entri yang bukan angka dibuang dengan peringatan, bukan didiamkan: salah
    ketik satu id di sini artinya seseorang mengira dirinya berwenang padahal
    perintahnya akan diabaikan tanpa jejak.
    """
    hasil = set()
    for potong in os.getenv(nama, "").replace(",", " ").split():
        if potong.lstrip("-").isdigit():
            hasil.add(potong)
        else:
            log.warning("%s: %r bukan id Telegram yang valid, dilewati.", nama, potong)
    return hasil


# Operator yang boleh memakai bot lewat chat privat. Grup TELEGRAM_CHAT_ID tetap
# jalur utama (dan tetap satu-satunya penerima notifikasi Airbyte); daftar ini
# hanya menambah pintu DM untuk orang yang id-nya memang ditulis operator di .env.
DM_USER_IDS = _daftar_id("TELEGRAM_DM_USER_IDS")


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

def send_telegram(text: str, chat_id=None, reply_to=None, reply_markup=None) -> None:
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
    if reply_markup:
        body["reply_markup"] = reply_markup
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


# ── Airbyte Public API ──────────────────────────────────────────────────────

_token_lock = threading.Lock()
_token = {"nilai": None, "kedaluwarsa": 0.0}


class AirbyteError(Exception):
    """Kegagalan yang layak ditampilkan apa adanya ke operator di Telegram."""


def airbyte_aktif() -> bool:
    return bool(AIRBYTE_URL and AIRBYTE_CLIENT_ID and AIRBYTE_CLIENT_SECRET)


def _ambil_token(paksa: bool = False) -> str:
    """
    Access token Public API, di-cache sampai mendekati kedaluwarsa.

    Catatan bentuk body: field-nya `grant-type` (tanda hubung), bukan `grant_type`
    seperti konvensi OAuth. Salah tanda hubung dibalas 401 — bukan 400 — jadi
    gejalanya menyamar sebagai kredensial salah.
    """
    with _token_lock:
        if not paksa and _token["nilai"] and time.time() < _token["kedaluwarsa"]:
            return _token["nilai"]

        try:
            resp = requests.post(
                f"{AIRBYTE_URL}/api/public/v1/applications/token",
                json={
                    "client_id": AIRBYTE_CLIENT_ID,
                    "client_secret": AIRBYTE_CLIENT_SECRET,
                    "grant-type": "client_credentials",
                },
                timeout=REQUEST_TIMEOUT,
            )
        except requests.RequestException as exc:
            raise AirbyteError(f"tidak bisa menghubungi Airbyte: {exc}") from exc

        if not resp.ok:
            raise AirbyteError(
                f"gagal ambil token ({resp.status_code}): {resp.text[:200]}"
            )

        data = resp.json()
        nilai = data.get("access_token")
        if not nilai:
            raise AirbyteError(f"respons token tanpa access_token: {str(data)[:200]}")

        umur = float(data.get("expires_in") or 180)
        _token["nilai"] = nilai
        _token["kedaluwarsa"] = time.time() + max(umur - 30, 30)  # sisakan margin
        return nilai


def _api(metode: str, path: str, **kwargs):
    """Panggil Public API; sekali retry dengan token baru kalau kena 401."""
    for percobaan in (1, 2):
        token = _ambil_token(paksa=(percobaan == 2))
        try:
            resp = requests.request(
                metode,
                f"{AIRBYTE_URL}/api/public/v1{path}",
                headers={"Authorization": f"Bearer {token}"},
                timeout=REQUEST_TIMEOUT,
                **kwargs,
            )
        except requests.RequestException as exc:
            raise AirbyteError(f"tidak bisa menghubungi Airbyte: {exc}") from exc

        if resp.status_code == 401 and percobaan == 1:
            continue  # token kedaluwarsa lebih cepat dari perkiraan
        if not resp.ok:
            raise AirbyteError(f"{metode} {path} → {resp.status_code}: {resp.text[:300]}")
        return resp.json() if resp.content else {}

    raise AirbyteError("token ditolak dua kali berturut-turut")


def daftar_koneksi() -> list:
    """
    Semua koneksi, diurutkan alfabetis menurut nama.

    Airbyte mengembalikannya dalam urutan yang tidak dijamin dan bisa berubah
    antar panggilan; diurutkan di sini supaya setiap pemakainya — daftar di
    Mini App, daftar /sync, maupun daftar kandidat saat nama ambigu — menampilkan
    urutan yang sama dan stabil.
    """
    params = {"limit": 100}
    if AIRBYTE_WORKSPACE_ID:
        params["workspaceIds"] = AIRBYTE_WORKSPACE_ID
    koneksi = _api("GET", "/connections", params=params).get("data", [])
    return sorted(koneksi, key=lambda k: (k.get("name") or "").lower())


def cari_koneksi(nama: str) -> dict:
    """
    Cocokkan nama koneksi yang diketik operator. Persis dulu, baru sebagian.

    Kalau ambigu, lebih baik gagal dan menampilkan kandidat daripada menebak —
    memicu sync koneksi yang salah berarti menulis data ke tabel kantor lain.
    """
    koneksi = daftar_koneksi()
    kunci = nama.strip().lower()

    persis = [k for k in koneksi if (k.get("name") or "").lower() == kunci]
    if len(persis) == 1:
        return persis[0]

    sebagian = [k for k in koneksi if kunci in (k.get("name") or "").lower()]
    if len(sebagian) == 1:
        return sebagian[0]
    if not sebagian:
        raise AirbyteError(
            f"koneksi {nama!r} tidak ditemukan. Ketik /sync tanpa argumen "
            f"untuk melihat daftarnya."
        )
    nama_kandidat = ", ".join(k.get("name", "?") for k in sebagian[:10])
    raise AirbyteError(f"nama {nama!r} cocok ke beberapa koneksi: {nama_kandidat}")


def mulai_sync(args: list, chat_id, reply_to) -> None:
    if not airbyte_aktif():
        send_telegram(
            "⚠️ Airbyte belum dikonfigurasi. Set <code>AIRBYTE_URL</code>, "
            "<code>AIRBYTE_CLIENT_ID</code>, dan <code>AIRBYTE_CLIENT_SECRET</code> "
            "di .env lalu <code>docker compose up -d notif-relay</code>.",
            chat_id, reply_to,
        )
        return

    try:
        if not args:
            koneksi = daftar_koneksi()
            if not koneksi:
                send_telegram("Tidak ada koneksi di Airbyte.", chat_id, reply_to)
                return
            baris = "\n".join(
                f"• <code>{html.escape(k.get('name', '?'))}</code>"
                f"{'' if k.get('status') == 'active' else ' <i>(' + html.escape(str(k.get('status'))) + ')</i>'}"
                for k in koneksi
            )
            send_telegram(
                f"<b>Koneksi Airbyte</b>\n{baris}\n\nPakai: <code>/sync nama-koneksi</code>",
                chat_id, reply_to,
            )
            return

        target = cari_koneksi(" ".join(args))
        hasil = _api("POST", "/jobs", json={
            "connectionId": target["connectionId"],
            "jobType": "sync",
        })
    except AirbyteError as exc:
        send_telegram(f"❌ Airbyte: {html.escape(str(exc))}", chat_id, reply_to)
        return

    # Laporan selesai datang lewat webhook Airbyte ke relay ini — jalur yang sudah
    # berjalan sejak awal. Tidak ada pemantau tambahan di sini.
    send_telegram(
        f"▶️ Sync <b>{html.escape(target.get('name', '?'))}</b> dimulai "
        f"(job {hasil.get('jobId', '?')}).\n"
        f"<i>Hasilnya menyusul lewat notifikasi Airbyte.</i>",
        chat_id, reply_to,
    )


# ── Mini App: otentikasi initData ───────────────────────────────────────────

class WebAppError(Exception):
    """Permintaan Mini App yang ditolak; pesannya boleh tampil ke pengguna."""

    def __init__(self, pesan: str, kode: int = 401):
        super().__init__(pesan)
        self.kode = kode


def mini_app_aktif() -> bool:
    return bool(MINI_APP_URL) and MINI_APP_FILE.is_file()


def verifikasi_init_data(raw: str) -> dict:
    """
    Verifikasi `Telegram.WebApp.initData` sesuai spesifikasi Bot API.

    Ini satu-satunya hal yang memisahkan panel ini dari siapa pun yang menebak
    URL-nya, jadi tidak ada jalan pintas: hash dihitung ulang dengan HMAC
    bertingkat (kunci = HMAC("WebAppData", token)) dan dibandingkan constant-time.
    Yang dikeluarkan dari data_check_string hanya `hash`. `signature` (tanda tangan
    Ed25519 Bot API 8.0+ untuk validasi pihak ketiga) **ikut dihitung** — mengeluarkannya
    membuat semua klien baru ditolak "initData tidak sah" sementara klien lama yang
    belum mengirim field itu tetap lolos, gejala yang menyesatkan.
    """
    if not raw:
        raise WebAppError("initData kosong — buka panel ini dari Telegram.")

    data = dict(urllib.parse.parse_qsl(raw, keep_blank_values=True))
    diberikan = data.pop("hash", "")
    if not diberikan:
        raise WebAppError("initData tanpa hash.")

    check = "\n".join(f"{k}={data[k]}" for k in sorted(data))
    rahasia = hmac.new(b"WebAppData", TELEGRAM_BOT_TOKEN.encode(), hashlib.sha256).digest()
    dihitung = hmac.new(rahasia, check.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(dihitung, diberikan):
        raise WebAppError("initData tidak sah.")

    # Umur dibatasi supaya initData yang bocor (mis. dari log proxy) tidak jadi
    # kunci permanen. Tanpa ini, hash-nya berlaku selamanya.
    try:
        umur = time.time() - float(data.get("auth_date") or 0)
    except ValueError:
        raise WebAppError("auth_date tidak valid.") from None
    if umur > MINI_APP_MAX_AGE:
        raise WebAppError("Sesi kedaluwarsa. Tutup panel lalu buka lagi.")

    try:
        user = json.loads(data.get("user") or "{}")
    except json.JSONDecodeError:
        user = {}
    if not user.get("id"):
        raise WebAppError("initData tanpa data pengguna.")
    return user


_anggota_lock  = threading.Lock()
_anggota_cache: dict = {}   # user_id -> (boleh, kedaluwarsa)
_ANGGOTA_TTL_OK    = 300    # detik
_ANGGOTA_TTL_TOLAK = 30     # gagal/ditolak di-cache singkat saja


def anggota_grup(user_id) -> bool:
    """
    True kalau user_id anggota TELEGRAM_CHAT_ID.

    Otorisasi bot teks adalah "chat-nya harus grup itu"; padanan untuk Mini App
    adalah "penggunanya harus anggota grup itu" — link panel bisa diteruskan
    keluar grup, chat tidak. Jawaban Telegram di-cache sebentar supaya tiap
    polling status tidak jadi satu getChatMember.
    """
    if str(user_id) == str(TELEGRAM_CHAT_ID):   # target notifikasi = chat privat
        return True

    sekarang = time.time()
    with _anggota_lock:
        cache = _anggota_cache.get(user_id)
        if cache and cache[1] > sekarang:
            return cache[0]

    boleh = False
    try:
        resp = requests.get(
            f"{TELEGRAM_BASE}/getChatMember",
            params={"chat_id": TELEGRAM_CHAT_ID, "user_id": user_id},
            timeout=REQUEST_TIMEOUT,
        )
        if resp.ok:
            status = ((resp.json().get("result") or {}).get("status") or "").lower()
            boleh = status in ("creator", "administrator", "member", "restricted")
        else:
            log.warning("getChatMember %s membalas %s: %s",
                        user_id, resp.status_code, resp.text[:200])
    except requests.RequestException as exc:
        # Fail closed: kalau keanggotaan tidak bisa dipastikan, tolak.
        log.warning("getChatMember %s gagal: %s", user_id, exc)

    with _anggota_lock:
        _anggota_cache[user_id] = (boleh, sekarang + (_ANGGOTA_TTL_OK if boleh else _ANGGOTA_TTL_TOLAK))
    return boleh


def otorisasi_webapp(init_data: str) -> dict:
    user = verifikasi_init_data(init_data)
    # Operator DM yang terdaftar tidak perlu diverifikasi ke Telegram: id-nya
    # sudah ditulis tangan di .env, sumber kebenaran yang lebih kuat daripada
    # keanggotaan grup — dan panel tetap bisa dipakai kalau bot belum di grup.
    if str(user["id"]) in DM_USER_IDS:
        return user
    if not anggota_grup(user["id"]):
        raise WebAppError("Anda bukan anggota grup operator pipeline ini.", 403)
    return user


def sebut(user: dict) -> str:
    """Nama pengguna untuk pesan audit ke grup."""
    if user.get("username"):
        return "@" + str(user["username"])
    nama = " ".join(filter(None, [user.get("first_name"), user.get("last_name")]))
    return nama or f"id {user.get('id')}"


def tombol_mini_app(chat_id) -> dict:
    """
    reply_markup untuk membuka Mini App, atau {} kalau tidak memungkinkan.

    Tombol `web_app` hanya sah di chat privat; di grup Telegram menolaknya, jadi
    di sana dipakai direct link (t.me/<bot>/<shortname>) sebagai tombol URL biasa.
    """
    if not mini_app_aktif():
        return {}
    privat = str(chat_id) != str(TELEGRAM_CHAT_ID) or not str(TELEGRAM_CHAT_ID).startswith("-")
    if privat:
        tombol = {"text": "🎛 Buka Panel", "web_app": {"url": f"{MINI_APP_URL}/app"}}
    elif MINI_APP_DIRECT_LINK:
        tombol = {"text": "🎛 Buka Panel", "url": MINI_APP_DIRECT_LINK}
    else:
        return {}
    return {"inline_keyboard": [[tombol]]}


def pasang_menu_button() -> None:
    """
    Pasang tombol menu (pojok kiri kolom ketik) di chat privat pengguna.

    setChatMenuButton tanpa chat_id mengubah default untuk semua chat privat —
    itu yang diinginkan: panel hanya bisa dibuka anggota grup, dan orang lain
    tetap ditolak oleh otorisasi_webapp() saat halaman memanggil API.
    """
    if not mini_app_aktif():
        return
    try:
        resp = requests.post(
            f"{TELEGRAM_BASE}/setChatMenuButton",
            json={"menu_button": {"type": "web_app", "text": "Panel",
                                  "web_app": {"url": f"{MINI_APP_URL}/app"}}},
            timeout=REQUEST_TIMEOUT,
        )
        if resp.ok:
            log.info("Mini App aktif: %s/app", MINI_APP_URL)
        else:
            log.warning("setChatMenuButton gagal (%s): %s", resp.status_code, resp.text[:200])
    except requests.RequestException as exc:
        log.warning("setChatMenuButton gagal: %s", exc)


# ── Mini App: API JSON ──────────────────────────────────────────────────────

def status_semua_job() -> dict:
    hasil = {}
    for nama, base in JOBS.items():
        try:
            hasil[nama] = requests.get(f"{base}/status", timeout=REQUEST_TIMEOUT).json()
        except Exception as exc:  # noqa: BLE001 -- satu job mati != panel mati
            hasil[nama] = {"job": nama, "error": f"tidak bisa dihubungi: {str(exc)[:120]}"}
    return hasil


def api_state(user: dict) -> dict:
    return {
        "jobs": status_semua_job(),
        "airbyte": {"enabled": airbyte_aktif()},
        "user": {k: user.get(k) for k in ("id", "username", "first_name")},
    }


def api_logs(nama: str) -> dict:
    if nama not in JOBS:
        raise WebAppError(f"job tidak dikenal: {nama}", 400)
    try:
        teks = requests.get(f"{JOBS[nama]}/logs", timeout=REQUEST_TIMEOUT).text
    except requests.RequestException as exc:
        raise WebAppError(f"gagal ambil log: {str(exc)[:200]}", 502) from exc
    return {"job": nama, "text": "\n".join(teks.splitlines()[-200:])}


def api_run(body: dict, user: dict) -> dict:
    """
    Picu job dari Mini App. Parameter diteruskan apa adanya ke control server —
    yang memvalidasi tetap hanya validate_params() milik service itu (ADR 0002).
    """
    nama = str(body.get("job") or "").lower()
    if nama not in JOBS:
        raise WebAppError(f"job tidak dikenal: {nama}", 400)

    params = {}
    if nama == "split":
        sumber = body.get("sources") or []
        if not isinstance(sumber, list):
            raise WebAppError("sources harus berupa list", 400)
        if sumber:
            params["sources"] = [str(x) for x in sumber]
    elif nama == "dbt":
        if body.get("command"):
            params["command"] = str(body["command"])
        if body.get("select"):
            params["select"] = str(body["select"])

    kode, data = picu_job(nama, params)
    if kode == 202:
        # Panel yang dibuka operator DM: laporan hasil ikut masuk ke DM-nya.
        if str(user.get("id")) in DM_USER_IDS:
            langgan_hasil(nama, user["id"])
        # Diumumkan ke grup: aksi lewat panel tidak meninggalkan jejak pesan
        # seperti perintah teks, dan run yang muncul entah dari mana bikin
        # operator lain menebak-nebak.
        rincian = _rincian_params(params)
        threading.Thread(
            target=send_telegram,
            args=(f"▶️ <b>{nama}</b> dimulai oleh {html.escape(sebut(user))} "
                  f"lewat Mini App.{rincian}",),
            daemon=True,
        ).start()
        return {"ok": True, "message": f"{nama} dimulai. Hasilnya dilaporkan ke grup."}
    if kode == 409:
        raise WebAppError(f"{nama} masih berjalan.", 409)
    raise WebAppError(str((data or {}).get("error") or f"ditolak ({kode})")[:300], 400)


def api_connections() -> dict:
    if not airbyte_aktif():
        raise WebAppError("Airbyte belum dikonfigurasi.", 400)
    try:
        koneksi = daftar_koneksi()
    except AirbyteError as exc:
        raise WebAppError(str(exc)[:300], 502) from exc
    return {"connections": [
        {"connectionId": k.get("connectionId"), "name": k.get("name"), "status": k.get("status")}
        for k in koneksi
    ]}


def api_sync(body: dict, user: dict) -> dict:
    if not airbyte_aktif():
        raise WebAppError("Airbyte belum dikonfigurasi.", 400)
    connection_id = str(body.get("connection_id") or "").strip()
    nama = str(body.get("name") or "").strip()
    try:
        if not connection_id:
            if not nama:
                raise WebAppError("connection_id atau name wajib diisi.", 400)
            target = cari_koneksi(nama)
            connection_id, nama = target["connectionId"], target.get("name", nama)
        hasil = _api("POST", "/jobs", json={"connectionId": connection_id, "jobType": "sync"})
    except AirbyteError as exc:
        raise WebAppError(str(exc)[:300], 502) from exc

    label = nama or connection_id
    threading.Thread(
        target=send_telegram,
        args=(f"▶️ Sync <b>{html.escape(label)}</b> dimulai oleh "
              f"{html.escape(sebut(user))} lewat Mini App (job {hasil.get('jobId', '?')}).",),
        daemon=True,
    ).start()
    return {"ok": True, "message": f"Sync {label} dimulai (job {hasil.get('jobId', '?')})."}


# ── Bot: perintah dari grup Telegram ────────────────────────────────────────

BANTUAN = (
    "<b>Perintah yang tersedia</b>\n"
    "/split — jalankan split-excel untuk semua folder di NEXTCLOUD_SOURCE_PATHS\n"
    "/split <i>A1/Finance</i> — hanya folder tertentu (relatif ke NEXTCLOUD_SOURCE_HOME, "
    "boleh beberapa dipisah spasi)\n"
    "/dbt — jalankan <code>dbt run</code>\n"
    "/sync — daftar koneksi Airbyte\n"
    "/sync <i>nama-koneksi</i> — picu sync koneksi itu\n"
    "/status — job sedang jalan atau tidak, plus hasil run terakhir\n"
    "/logs [split|dbt] — ekor log run terakhir\n"
    "/app — buka Panel Pipeline (Mini App): status, tombol jalankan, log\n"
    "/id — tampilkan user id Anda (untuk didaftarkan ke TELEGRAM_DM_USER_IDS)\n"
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


_pelanggan_lock = threading.Lock()
_pelanggan: dict = {}     # nama job -> set chat privat yang menunggu hasilnya


def langgan_hasil(nama: str, chat_id) -> None:
    """
    Catat chat privat yang memicu job supaya ikut menerima laporan selesainya.

    Tanpa ini, operator yang bekerja lewat DM harus menengok ke grup untuk tahu
    hasil perintahnya sendiri. Grup tetap dapat laporan seperti biasa — pelaporan
    tetap satu tempat (watch_jobs), yang bertambah hanya daftar penerimanya.
    """
    if chat_id is None or str(chat_id) == str(TELEGRAM_CHAT_ID):
        return
    with _pelanggan_lock:
        _pelanggan.setdefault(nama, set()).add(chat_id)


def _ambil_pelanggan(nama: str) -> set:
    """Ambil sekaligus kosongkan daftar penunggu; satu run = satu laporan."""
    with _pelanggan_lock:
        return _pelanggan.pop(nama, set())


def _lapor_selesai(nama: str, st: dict) -> None:
    """Kirim satu pesan hasil run ke grup (dan ke chat privat yang memicunya)."""
    base = JOBS[nama]
    durasi = _fmt_duration(st.get("duration_s"))
    sumber = st.get("last_params", {}).get("sources")
    rincian = ""
    if sumber:
        rincian = "\n" + "\n".join(f"• {html.escape(str(s))}" for s in sumber)

    if st.get("last_ok"):
        pesan = f"✅ <b>{nama}</b> selesai ({durasi}).{rincian}"
    else:
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
    for chat_id in _ambil_pelanggan(nama):
        send_telegram(pesan, chat_id)


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


def _rincian_params(params: dict) -> str:
    """Baris tambahan untuk pesan Telegram: folder atau selector yang dipakai."""
    if params.get("sources"):
        return "\n" + "\n".join(f"• {html.escape(str(s))}" for s in params["sources"])
    potongan = []
    if params.get("command") and params["command"] != "run":
        potongan.append(str(params["command"]))
    if params.get("select"):
        potongan.append(f"--select {params['select']}")
    return f"\n<code>{html.escape(' '.join(potongan))}</code>" if potongan else ""


def picu_job(nama: str, params: dict):
    """
    POST /run ke control server job. Balikkan (status_code, body_json_atau_None).

    Dipakai bersama oleh bot teks dan Mini App supaya keduanya menempuh jalur
    yang persis sama — termasuk 409 single-flight dan 400 dari validate_params().
    """
    resp = requests.post(f"{JOBS[nama]}/run", json=params, timeout=REQUEST_TIMEOUT)
    try:
        data = resp.json()
    except ValueError:
        data = {"error": resp.text[:500]}
    return resp.status_code, data


def mulai_job(nama: str, args: list, chat_id, reply_to) -> None:
    """Panggil POST /run pada control server job, lalu balas ke Telegram."""
    body = {}
    if nama == "split" and args:
        # Diteruskan apa adanya — validasi path hanya hidup di resolve_source()
        # milik split-excel, supaya tidak ada dua aturan yang bisa berbeda.
        body["sources"] = args
    elif nama == "dbt" and args:
        body["select"] = " ".join(args)

    try:
        kode, data = picu_job(nama, body)
    except requests.RequestException as exc:
        send_telegram(
            f"❌ Tidak bisa menghubungi <b>{nama}</b>: {html.escape(str(exc)[:300])}",
            chat_id, reply_to,
        )
        return

    if kode == 202:
        # Hasilnya dilaporkan oleh watch_jobs(), bukan di sini — supaya run
        # terjadwal dan run manual sama-sama dapat satu pesan, tanpa dobel.
        langgan_hasil(nama, chat_id)
        send_telegram(f"▶️ <b>{nama}</b> dimulai.{_rincian_params(body)}", chat_id, reply_to)
    elif kode == 409:
        send_telegram(f"⏳ <b>{nama}</b> masih berjalan; permintaan diabaikan.",
                      chat_id, reply_to)
    else:
        send_telegram(
            f"❌ <b>{nama}</b> ditolak ({kode}): "
            f"{html.escape(str((data or {}).get('error', ''))[:500])}",
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


def kirim_panel(chat_id, reply_to) -> None:
    """Balas dengan tombol pembuka Mini App, atau jelaskan kenapa belum bisa."""
    if not mini_app_aktif():
        send_telegram(
            "⚠️ Mini App belum aktif. Set <code>MINI_APP_URL</code> (URL HTTPS publik "
            "yang meneruskan ke <code>/app</code> di relay ini) lalu "
            "<code>docker compose up -d notif-relay</code>.",
            chat_id, reply_to,
        )
        return

    markup = tombol_mini_app(chat_id)
    if not markup:
        # Tombol web_app dilarang di grup dan direct link belum diisi.
        send_telegram(
            "🎛 Panel hanya bisa dibuka dari chat privat dengan bot ini "
            "(kirim <code>/app</code> di japri), atau lewat direct link — buat "
            "dengan BotFather <code>/newapp</code> lalu isi "
            "<code>MINI_APP_DIRECT_LINK</code> di .env.",
            chat_id, reply_to,
        )
        return

    send_telegram(
        "🎛 <b>Panel Pipeline</b>\nStatus job, tombol jalankan, dan log — "
        "tanpa mengetik perintah.",
        chat_id, reply_to, markup,
    )


def kirim_id(message: dict, chat_id, reply_to) -> None:
    """
    Balas dengan id pengirim dan id chat.

    Ada supaya mengisi TELEGRAM_DM_USER_IDS tidak perlu bot pihak ketiga: minta
    calon operator mengetik /id di grup, salin angkanya ke .env.
    """
    dari = (message.get("from") or {}).get("id")
    send_telegram(
        f"🪪 User id Anda: <code>{html.escape(str(dari))}</code>\n"
        f"Chat id di sini: <code>{html.escape(str(chat_id))}</code>\n\n"
        f"<i>Tambahkan user id itu ke <code>TELEGRAM_DM_USER_IDS</code> di .env "
        f"agar bisa memakai bot lewat chat privat.</i>",
        chat_id, reply_to,
    )


def handle_command(message: dict) -> None:
    chat = message.get("chat") or {}
    chat_id = chat.get("id")
    teks = (message.get("text") or "").strip()
    if not teks.startswith("/"):
        return

    bagian = teks.split()
    perintah = bagian[0].lstrip("/").split("@", 1)[0].lower()  # /split@NamaBot
    args = [a for a in bagian[1:] if a.strip(",")]
    args = [a.strip(",") for a in args]
    reply_to = message.get("message_id")

    pemakai = (message.get("from") or {}).get("id")
    privat = chat.get("type") == "private"

    # Otorisasi: bot bisa di-DM siapa saja yang tahu username-nya. Yang dilayani
    # penuh hanya grup TELEGRAM_CHAT_ID dan user yang id-nya terdaftar di
    # TELEGRAM_DM_USER_IDS. Di luar itu, chat privat milik anggota grup masih
    # boleh meminta tombol Mini App — tombol web_app memang tidak sah di grup —
    # dan setiap aksi di dalam panel tetap diverifikasi ulang oleh otorisasi_webapp().
    if str(chat_id) != str(TELEGRAM_CHAT_ID) and not (privat and str(pemakai) in DM_USER_IDS):
        if (privat and perintah in ("start", "app", "help", "id")
                and pemakai and anggota_grup(pemakai)):
            if perintah == "id":
                kirim_id(message, chat_id, reply_to)
            else:
                kirim_panel(chat_id, reply_to)
            return
        # id penggunanya ikut di-log: itu yang perlu disalin operator ke
        # TELEGRAM_DM_USER_IDS kalau memang orang ini yang berhak.
        log.warning("Perintah %r dari chat %s (user %s) diabaikan — tambahkan id itu "
                    "ke TELEGRAM_DM_USER_IDS bila ini operator.",
                    bagian[0], chat_id, pemakai)
        return

    if perintah == "id":
        kirim_id(message, chat_id, reply_to)
    elif perintah == "app":
        kirim_panel(chat_id, reply_to)
    elif perintah in ("help", "start"):
        send_telegram(BANTUAN, chat_id, reply_to, tombol_mini_app(chat_id) or None)
    elif perintah == "status":
        kirim_status(chat_id, reply_to)
    elif perintah == "logs":
        kirim_logs(args, chat_id, reply_to)
    elif perintah == "sync":
        mulai_sync(args, chat_id, reply_to)
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
    def _kirim(self, code: int, body: bytes, ctype: str):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _ok(self, body: bytes = b"ok"):
        self._kirim(200, body, "text/plain; charset=utf-8")

    def _json(self, code: int, obj: dict):
        self._kirim(code, json.dumps(obj).encode("utf-8"),
                    "application/json; charset=utf-8")

    # ── Mini App ────────────────────────────────────────────────────────────

    def _halaman_mini_app(self):
        """
        Layani halaman panel. Dibaca dari disk tiap permintaan (file kecil, dan
        rebuild image tidak perlu untuk mengubah tampilan saat bind-mount dipakai).
        """
        if not MINI_APP_URL:
            self._kirim(404, b"Mini App tidak aktif (MINI_APP_URL kosong).",
                        "text/plain; charset=utf-8")
            return
        try:
            isi = MINI_APP_FILE.read_bytes()
        except OSError as exc:
            log.error("Gagal membaca %s: %s", MINI_APP_FILE, exc)
            self._kirim(500, b"halaman Mini App tidak ditemukan",
                        "text/plain; charset=utf-8")
            return
        self._kirim(200, isi, "text/html; charset=utf-8")

    def _api_mini_app(self, path: str, query: dict, body: dict):
        """
        Jalur API panel. Setiap permintaan diverifikasi ulang dari nol —
        tidak ada sesi, tidak ada cookie: initData-lah kredensialnya.
        """
        try:
            user = otorisasi_webapp(self.headers.get("X-Telegram-Init-Data", ""))
            if path == "/api/state":
                return 200, api_state(user)
            if path == "/api/logs":
                return 200, api_logs((query.get("job") or ["split"])[0])
            if path == "/api/connections":
                return 200, api_connections()
            if path == "/api/run":
                return 200, api_run(body, user)
            if path == "/api/sync":
                return 200, api_sync(body, user)
            return 404, {"error": f"endpoint tidak dikenal: {path}"}
        except WebAppError as exc:
            if exc.kode in (401, 403):
                log.warning("Permintaan Mini App ditolak (%s): %s", exc.kode, exc)
            return exc.kode, {"error": str(exc)}
        except requests.RequestException as exc:
            return 502, {"error": f"service tidak bisa dihubungi: {str(exc)[:200]}"}
        except Exception:  # noqa: BLE001 -- satu permintaan gagal != relay mati
            log.exception("Error tak terduga di API Mini App (%s).", path)
            return 500, {"error": "kesalahan internal; cek log notif-relay"}

    # ── HTTP ────────────────────────────────────────────────────────────────

    def _pisah(self):
        potong = urllib.parse.urlsplit(self.path)
        path = potong.path.rstrip("/") or "/"
        return path, urllib.parse.parse_qs(potong.query)

    def do_GET(self):  # noqa: N802 -- health check + Mini App
        path, query = self._pisah()
        if path == "/app":
            self._halaman_mini_app()
        elif path.startswith("/api/"):
            self._json(*self._api_mini_app(path, query, {}))
        else:
            self._ok()

    def do_POST(self):  # noqa: N802
        path, query = self._pisah()
        length = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(length) if length else b""

        # Jalur Mini App dicek lebih dulu: sisa path apa pun tetap milik webhook
        # Airbyte (URL-nya diisi operator dan tidak selalu "/").
        if path.startswith("/api/"):
            try:
                body = json.loads(raw.decode("utf-8")) if raw.strip() else {}
            except (json.JSONDecodeError, UnicodeDecodeError):
                self._json(400, {"error": "body bukan JSON valid"})
                return
            if not isinstance(body, dict):
                self._json(400, {"error": "body harus berupa object JSON"})
                return
            self._json(*self._api_mini_app(path, query, body))
            return

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
        if DM_USER_IDS:
            log.info("Perintah lewat DM diizinkan untuk user: %s", ", ".join(sorted(DM_USER_IDS)))
        else:
            log.info("TELEGRAM_DM_USER_IDS kosong: perintah hanya dilayani di grup "
                     "(ketik /id di grup untuk melihat user id).")
        threading.Thread(target=poll_updates, daemon=True).start()
    else:
        log.info("Bot Telegram dimatikan (TELEGRAM_BOT_ENABLED=false).")

    if mini_app_aktif():
        threading.Thread(target=pasang_menu_button, daemon=True).start()
    elif MINI_APP_URL:
        log.warning("MINI_APP_URL di-set tapi %s tidak ada — Mini App dimatikan.",
                    MINI_APP_FILE)
    else:
        log.info("Mini App dimatikan (MINI_APP_URL kosong).")

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
