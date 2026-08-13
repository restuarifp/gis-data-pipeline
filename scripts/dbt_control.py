#!/usr/bin/env python3
"""
dbt_control.py — server kontrol untuk `dbt run`

Dijalankan service `dbt-runner` supaya bot Telegram bisa memicu `dbt run` lewat
HTTP internal di gisnet (lihat job_control.py dan
docs/adr/0002-trigger-job-via-telegram.md).

Service `dbt` yang lama sengaja dibiarkan apa adanya (profile cli_only) supaya
alur `docker compose run --rm dbt dbt run` di CLAUDE.md tetap berlaku.

Konfigurasi via environment:
  DBT_PROJECT_DIR  (opsional, default /usr/app/dbt)
  DBT_TARGET       (opsional, mis. 'prod')
  JOB_CONTROL_PORT (opsional, default 8080)
"""

from __future__ import annotations  # image ini masih Python 3.9

import logging
import os
import subprocess
import sys

import job_control

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    stream=sys.stdout,
)
log = logging.getLogger("dbt_control")

PROJECT_DIR = os.getenv("DBT_PROJECT_DIR", "/usr/app/dbt")
TARGET = os.getenv("DBT_TARGET", "").strip()

# Subperintah yang boleh dipicu dari luar. Daftar putih, bukan string bebas —
# perintahnya berasal dari pesan Telegram, jadi tidak boleh bisa dirakit sendiri.
PERINTAH_DIIZINKAN = {"run", "test", "build", "deps", "debug"}


def validate_params(params: dict) -> dict:
    perintah = str(params.get("command") or "run").strip().lower()
    if perintah not in PERINTAH_DIIZINKAN:
        raise ValueError(
            f"perintah dbt {perintah!r} tidak diizinkan "
            f"(pilihan: {', '.join(sorted(PERINTAH_DIIZINKAN))})"
        )

    hasil = {"command": perintah}

    select = params.get("select")
    if select:
        select = str(select).strip()
        # --select diteruskan sebagai satu argumen ke argv (tanpa shell), tapi
        # tetap dibatasi ke karakter selector dbt supaya tidak jadi jalan masuk
        # flag lain seperti '--profiles-dir'.
        if not all(c.isalnum() or c in "_-+@.*: " for c in select):
            raise ValueError(f"selector {select!r} mengandung karakter tidak wajar")
        hasil["select"] = select

    return hasil


def jalankan(params: dict) -> bool:
    argv = ["dbt", params.get("command", "run"), "--profiles-dir", "."]
    if TARGET:
        argv += ["--target", TARGET]
    if params.get("select"):
        argv += ["--select", params["select"]]

    log.info("Menjalankan: %s (cwd=%s)", " ".join(argv), PROJECT_DIR)
    proses = subprocess.Popen(
        argv,
        cwd=PROJECT_DIR,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    # Diteruskan baris per baris ke logging supaya ikut tertangkap ring buffer
    # job_control dan bisa dibaca lewat GET /logs (dan perintah /logs di Telegram).
    for baris in proses.stdout:
        log.info("%s", baris.rstrip())
    kode = proses.wait()

    if kode == 0:
        log.info("dbt selesai dengan sukses.")
        return True
    log.error("dbt keluar dengan kode %d.", kode)
    return False


if __name__ == "__main__":
    job_control.serve("dbt", jalankan, validate=validate_params)
