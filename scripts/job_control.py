#!/usr/bin/env python3
"""
job_control.py — server kontrol job mungil (stdlib saja)

Dipakai bersama oleh split-excel dan dbt-runner supaya sebuah job bisa dipicu
dari service lain di jaringan `gisnet` — konkretnya oleh bot Telegram di
notif-relay (lihat docs/adr/0002-trigger-job-via-telegram.md).

Sengaja TIDAK memakai Docker socket: notif-relay menerima input dari luar, dan
container semacam itu tidak boleh punya akses setara root ke host. Yang ada di
sini hanyalah "jalankan fungsi Python yang memang milik service ini".

Endpoint (hanya di dalam gisnet, tidak dipublish ke host):
  POST /run     -- mulai job. Body JSON opsional diteruskan ke runner.
                   202 dimulai | 409 masih jalan | 400 parameter ditolak
  GET  /status  -- JSON: running, last_started, last_finished, last_ok, duration_s
  GET  /logs    -- ekor log run terakhir (teks biasa)
  GET  /        -- health check

Konfigurasi via environment:
  JOB_CONTROL_PORT   (opsional, default 8080)
  JOB_LOG_LINES      (opsional, default 200)
"""

from __future__ import annotations  # image dbt masih Python 3.9 — 'X | None' harus lazy

import json
import logging
import os
import threading
import time
from collections import deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

log = logging.getLogger("job_control")

PORT      = int(os.getenv("JOB_CONTROL_PORT", "8080"))
LOG_LINES = int(os.getenv("JOB_LOG_LINES", "200"))


class _RingHandler(logging.Handler):
    """Tampung log run terakhir di memori supaya bisa dibaca lewat GET /logs."""

    def __init__(self, buf: deque):
        super().__init__()
        self.buf = buf

    def emit(self, record):
        try:
            self.buf.append(self.format(record))
        except Exception:  # noqa: BLE001 -- logging tidak boleh menjatuhkan job
            pass


class JobRunner:
    """
    Pembungkus single-flight untuk satu job.

    Lock-nya bukan sekadar rapi-rapi: dua run split-excel yang tumpang tindih
    akan menulis file yang sama di folder tujuan Nextcloud, jadi permintaan
    kedua ditolak (409), bukan diantrikan.
    """

    def __init__(self, nama: str, fn):
        self.nama = nama
        self.fn = fn
        self._lock = threading.Lock()
        self._running = False
        self._logs: deque = deque(maxlen=LOG_LINES)
        self.last_started: float | None = None
        self.last_finished: float | None = None
        self.last_ok: bool | None = None
        self.last_params: dict = {}

    # ── status ──────────────────────────────────────────────────────────────

    def status(self) -> dict:
        if self._running and self.last_started:
            durasi = time.time() - self.last_started
        elif self.last_started and self.last_finished:
            durasi = self.last_finished - self.last_started
        else:
            durasi = None
        return {
            "job": self.nama,
            "running": self._running,
            "last_started": self.last_started,
            "last_finished": self.last_finished,
            "last_ok": self.last_ok,
            "last_params": self.last_params,
            "duration_s": round(durasi, 1) if durasi is not None else None,
        }

    def logs(self) -> str:
        return "\n".join(self._logs)

    # ── eksekusi ────────────────────────────────────────────────────────────

    def start(self, params: dict) -> bool:
        """True kalau job dimulai, False kalau masih ada run yang jalan."""
        if not self._lock.acquire(blocking=False):
            return False
        self._running = True
        self.last_started = time.time()
        self.last_finished = None
        self.last_ok = None
        self.last_params = params
        self._logs.clear()
        threading.Thread(target=self._run, args=(params,), daemon=True).start()
        return True

    def _run(self, params: dict) -> None:
        root = logging.getLogger()
        handler = _RingHandler(self._logs)
        handler.setFormatter(
            logging.Formatter("%(asctime)s %(levelname)s %(message)s", "%H:%M:%S")
        )
        root.addHandler(handler)
        try:
            ok = bool(self.fn(params))
        except Exception:  # noqa: BLE001 -- kegagalan job != matinya server kontrol
            log.exception("Job %s gagal dengan exception.", self.nama)
            ok = False
        finally:
            root.removeHandler(handler)
            self.last_ok = ok
            self.last_finished = time.time()
            self._running = False
            self._lock.release()


def make_handler(runner: JobRunner, validate=None):
    """
    Bangun request handler untuk satu JobRunner.

    `validate(params) -> params` boleh melempar ValueError untuk menolak
    parameter; pesannya dikirim balik apa adanya sebagai 400 supaya operator
    di Telegram melihat alasan yang jelas (mis. path di luar SOURCE_HOME).
    """

    class Handler(BaseHTTPRequestHandler):
        def _reply(self, code: int, body: str, ctype="text/plain; charset=utf-8"):
            raw = body.encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def _json(self, code: int, obj: dict):
            self._reply(code, json.dumps(obj), "application/json; charset=utf-8")

        def do_GET(self):  # noqa: N802
            path = self.path.split("?", 1)[0].rstrip("/") or "/"
            if path == "/status":
                self._json(200, runner.status())
            elif path == "/logs":
                self._reply(200, runner.logs() or "(belum ada log)")
            else:
                self._reply(200, "ok")

        def do_POST(self):  # noqa: N802
            path = self.path.split("?", 1)[0].rstrip("/") or "/"
            if path != "/run":
                self._json(404, {"error": f"endpoint tidak dikenal: {path}"})
                return

            length = int(self.headers.get("Content-Length") or 0)
            raw = self.rfile.read(length) if length else b""
            try:
                params = json.loads(raw.decode("utf-8")) if raw.strip() else {}
            except (json.JSONDecodeError, UnicodeDecodeError) as exc:
                self._json(400, {"error": f"body bukan JSON valid: {exc}"})
                return
            if not isinstance(params, dict):
                self._json(400, {"error": "body harus berupa object JSON"})
                return

            if validate is not None:
                try:
                    params = validate(params)
                except ValueError as exc:
                    self._json(400, {"error": str(exc)})
                    return

            if not runner.start(params):
                self._json(409, {"error": f"job {runner.nama} masih berjalan",
                                 **runner.status()})
                return

            log.info("Job %s dimulai lewat /run (params: %s).", runner.nama, params)
            self._json(202, {"started": True, **runner.status()})

        def log_message(self, fmt, *args):  # redam akses-log bawaan
            log.debug("%s - %s", self.address_string(), fmt % args)

    return Handler


def serve(nama: str, fn, validate=None, background: bool = False) -> JobRunner:
    """
    Nyalakan server kontrol untuk job `nama`.

    background=True menjalankannya di thread daemon (dipakai split-excel yang
    thread utamanya sudah dipegang loop --watch).
    """
    runner = JobRunner(nama, fn)
    server = ThreadingHTTPServer(("0.0.0.0", PORT), make_handler(runner, validate))
    log.info("Server kontrol job '%s' mendengarkan di 0.0.0.0:%d", nama, PORT)

    if background:
        threading.Thread(target=server.serve_forever, daemon=True).start()
    else:
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            log.info("Dihentikan.")
        finally:
            server.server_close()
    return runner
