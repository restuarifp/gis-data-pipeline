# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A geospatial-based remote worker data warehouse stack for tracking civil registration (capil) and finance data across multiple branch offices (kantor perwakilan). Raw data flows from Nextcloud (via Excel) → Airbyte → PostgreSQL/PostGIS → dbt → Metabase.

## Stack

| Service | Image/Tech | Port |
|---|---|---|
| `postgres-db` | postgis/postgis:latest | 5432 |
| `metabase` | metabase/metabase:latest | 3000 |
| `dbt` | Custom Dockerfile.dbt (Python 3.9 + dbt-postgres) | CLI only |
| `split-excel` | Custom Dockerfile.split-excel (Python 3.12) | — |
| `notif-relay` | Custom Dockerfile.notif-relay (Python 3.12) | 8000 |
| `dbt-runner` | Custom Dockerfile.dbt (server kontrol job) | — |
| `onlyoffice-docs` | onlyoffice/documentserver:9.3.1.1 | 8080 |
| `grafana` | grafana/grafana:latest | 3030 |
| `prometheus` | prom/prometheus:latest | 9090 |
| `loki` | grafana/loki:latest | 3100 |
| `promtail` | grafana/promtail:latest | — |
| `node-exporter` / `cadvisor` / `postgres-exporter` | Prometheus exporters | — |

Services share a `gisnet` bridge network; inter-service references use Docker service names (e.g., `postgres-db`), not `localhost`.

## Common Commands

```bash
# Start core services (postgres + metabase + onlyoffice)
docker compose up -d

# Run dbt (connects to capil_db, writes to analytics schema)
docker compose run --rm dbt dbt run
docker compose run --rm dbt dbt run --select <model_name>
docker compose run --rm dbt dbt debug          # test connection
docker compose run --rm dbt dbt deps           # install packages

# Run split-excel once (without --watch loop)
docker compose run --rm split-excel python split_excel.py

# Start the notif-relay (Airbyte webhook → Telegram + bot perintah); listens on :8000
docker compose up -d notif-relay

# Trigger a job the way the Telegram bot does (control server, gisnet-internal)
docker run --rm --network gis-data-pipeline_gisnet curlimages/curl -s -X POST split-excel:8080/run
docker run --rm --network gis-data-pipeline_gisnet curlimages/curl -s split-excel:8080/status

# Start the observability stack (Grafana on :3030, admin/admin by default)
docker compose --profile observability up -d

# Stop services (data preserved)
docker compose down

# Stop and wipe volumes (data loss)
docker compose down -v
```

## Architecture

### Data flow

```
Nextcloud (WebDAV)
    └── split_excel.py (scripts/)
            Fetches .xlsx from source folders, splits each sheet into a
            separate file, uploads to destination folder
    └── Airbyte
            Syncs per-sheet .xlsx files into PostgreSQL as raw_<kantor_id> tables
            (capil) and raw_finance_rekap_<kantor_id> / raw_finance_rincian_<kantor_id> tables (finance)
    └── dbt (dbt/)
            staging/ views → mart/ views in the analytics schema
    └── Metabase (port 3000)
            Dashboards querying analytics schema
```

### dbt project (`dbt/`)

- **Profile**: `dbt_profile`, target `prod`, writes to schema `analytics` in `capil_db`
- **Materialization**: all models are `view`
- **Package**: `dbt-labs/dbt_utils` (provides `dbt_utils.star()`)

**Model layers:**

- `models/staging/sources.yml` — declares all `raw.*` source tables in `capil_db.public`
- `models/staging/stg_<kantor_id>_capil.sql` — one per office; filters to the latest data pull (`_airbyte_generation_id = MAX(_airbyte_generation_id)`), strips internal Airbyte columns, normalizes text fields to lowercase, adds `kantor_id` column
- `models/staging/finance/stg_<kantor_id>_finance_rekap.sql` / `_rincian.sql` — one-liner: `{{ stg_finance_rekap('<kantor_id>') }}` delegating to the macro
- `models/marts/mart_capil.sql` — `UNION ALL` across every staging capil model
- `models/marts/finance/mart_finance_rekap.sql` / `mart_finance_rincian.sql` — `UNION ALL` across every staging finance model

### Key macro (`dbt/macros/finance_helpers.sql`)

`source_relation_exists(relation)` — checks `information_schema.tables` at compile time; returns `false` during `dbt parse`/`dbt ls` (no DB connection). Used in `stg_finance_rekap` and `stg_finance_rincian` to gracefully handle offices whose Airbyte sync hasn't landed yet, returning an empty result set with matching columns instead of crashing.

**Critical invariant:** The "exists" and "missing" branches of both macros must have identical column names and types, or the `UNION ALL` in the mart breaks.

**Latest-pull filter:** Every staging model (capil + finance) filters to `_airbyte_generation_id = MAX(_airbyte_generation_id)` so only the most recent pull is shown — a month may contain several pulls, and a single extraction batch can produce differing `_airbyte_extracted_at` values across its rows, so the generation id (not extraction time) is the reliable batch key.

**`stg_finance_rincian` columns:** mirror the finance file exactly — `INSTANSI`, then `TUNAI_*` and `NOMINAL_*` for the 10 jenis (FI, ZF, AQQ, FDY, IFQ, LQT, SDQ, SNK, TDY, ZKT). There are **no** `WAJIB_*` columns in the file and no `JUMLAH_WARGA`; the only wajib column is the derived `wajib_ifq` below.

**Derived `wajib_ifq`:** In `stg_finance_rincian`, `wajib_ifq` is *not* read from the finance file — it is computed from the office's capil table (`raw_<kantor_id>`): `COUNT(*)` of latest-pull rows per instansi where `LMG = INSTANSI` and `Status_Tabungan = 'Paham'` (COALESCE to 0 when an instansi has no capil match). This makes `stg_finance_rincian` depend on **both** `raw_finance_rincian_<kantor_id>` **and** `raw_<kantor_id>`; the capil source must be declared in `sources.yml` for every office passed to the macro. If the capil table doesn't physically exist yet, `wajib_ifq` falls back to `NULL` (guarded by `source_relation_exists`).

### split-excel service (`scripts/split_excel.py`)

Configured via `.env` (required: `NEXTCLOUD_URL`, `NEXTCLOUD_USER`, `NEXTCLOUD_PASSWORD`, `NEXTCLOUD_SOURCE_PATHS`, `NEXTCLOUD_DEST_PATH`; optional: `SCHEDULE_INTERVAL_MINUTES` default 60, `WEBDAV_MAX_RETRIES` default 5, `WEBDAV_RETRY_BACKOFF_SECONDS` default 3).

- Accepts multiple source paths via `NEXTCLOUD_SOURCE_PATHS` (comma or newline separated)
- **`NEXTCLOUD_SOURCE_HOME`** — optional parent folder; entries in `NEXTCLOUD_SOURCE_PATHS` are written relative to it (`A1/Finance`). `resolve_source()` joins them **idempotently**, so entries that already spell out the full path still work and an unset `SOURCE_HOME` reproduces the old behaviour exactly. It is also the security boundary for the `/split <path>` Telegram argument: anything containing `..` or resolving outside `SOURCE_HOME` is rejected. **An empty `SOURCE_HOME` means no folder boundary at all** (only `..` is still blocked) — the service logs a warning at startup when that's the case.
- **Control server (`--serve`)**: `job_control.serve()` exposes `POST /run` (202 / 409 busy / 400 rejected params), `GET /status`, `GET /logs` on `JOB_CONTROL_PORT` (8080) — **gisnet only, never published to the host**. `POST /run {"sources": [...]}` runs a subset. The container CMD is `--watch --serve`, so the schedule and the on-demand path coexist.
- Output naming: `{kantor_name}__{file_stem}__{safe_sheet_name}.xlsx`
- Atomic per-office: if any sheet fails to process, the whole office is skipped and old files are not deleted
- `--watch` flag enables polling loop; without it, runs once and exits (exit code 1 if any upload failed)
- `split_workbook()` reads with `data_only=True` and copies only resolved values (never formula strings) into the split output; if a cell has no cached value (formula saved without a stored result), its coordinates are logged as a warning instead of leaking `=...` text downstream.
- **Upload-first, then prune:** each office's sheets are uploaded via PUT (overwrite) *before* anything is deleted, so a lock failure can't leave the destination half-empty. Only stale files (prefix matches but no longer produced) are deleted afterward. If any upload still fails after retries, old files are kept and `process_source` returns failure.
- **423 Locked retry:** WebDAV `PUT`/`DELETE` retry on HTTP 423 (`_request_with_retry`, linear backoff, `WEBDAV_MAX_RETRIES` × `WEBDAV_RETRY_BACKOFF_SECONDS`). Destination files get locked when OnlyOffice/another client holds them open; keep the OnlyOffice-watched folder separate from `NEXTCLOUD_DEST_PATH` to avoid this.

### notif-relay service (`scripts/notif_relay.py`)

The **Relay Notifikasi** (see `CONTEXT.md`): a tiny stdlib-only HTTP server that receives Airbyte webhook notifications and forwards them to a Telegram group. Configured via `.env` (required: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`; optional: `NOTIF_RELAY_PORT` default 8000, `TELEGRAM_MAX_RETRIES` default 3, `TELEGRAM_RETRY_BACKOFF_SECONDS` default 3).

- **Best-effort by design** (`docs/adr/0001-notifikasi-telegram-best-effort.md`): every `POST` replies `200` *immediately*, then the Telegram send runs in a daemon thread with linear-backoff retry. Final failure is only logged — the message is dropped, and Airbyte is never made to think the Job failed. **No notification is not proof a sync didn't run; Airbyte UI is the source of truth.**
- **One Job = one message.** Airbyte fires one webhook per Job (not per Stream), so the relay emits one Telegram message per call.
- **Fails fast on missing config:** an empty/absent `TELEGRAM_BOT_TOKEN` or `TELEGRAM_CHAT_ID` logs one clear line and exits **78** (`EX_CONFIG`). The compose restart policy is `on-failure:3`, so a misconfigured relay stops after 3 attempts instead of crash-looping. Note an *empty* value in `.env` is still a set env var — hence the explicit emptiness check, not `os.environ[...]`.
- Accepts any POST path (health check on `GET /`). `format_message()` is defensive: it reads the structured `data` object of Airbyte's custom webhook, falls back to a Slack-style `{text}` field, and dumps raw JSON for unknown shapes. All interpolated values are HTML-escaped (`parse_mode=HTML`).
- Airbyte is **not** in this compose stack — point its webhook notification at `http://<host>:8000/` (the relay publishes host port 8000 on `gisnet`).
- **Two-way bot** (`docs/adr/0002-trigger-job-via-telegram.md`): a `getUpdates` long-polling thread accepts `/split [path...]`, `/dbt [select]`, `/status`, `/logs [split|dbt]`, `/help`. It triggers jobs by calling the control servers over `gisnet` (`SPLIT_CONTROL_URL`, `DBT_CONTROL_URL`) — **never via the Docker socket**, because the relay eats outside input. Commands from any chat other than `TELEGRAM_CHAT_ID` are ignored silently.
- The bot does **not** validate `/split` paths; it forwards them and surfaces the control server's `400`. Path rules live only in `resolve_source()` — two copies of a rule drift, and the looser one becomes the hole.
- Long-polling means the token must have **no webhook** set and only **one** polling process may run per token (Telegram answers 409 otherwise). An invalid token (401/404) shuts the command loop down with one clear log line; the Airbyte webhook path keeps running.

### Observability (`observability/`)

Grafana + Prometheus + Loki behind the `observability` compose profile, so the
default `docker compose up -d` is unaffected. See `observability/README.md` for
the full picture. Two rules matter when touching
`observability/prometheus/postgres-queries.yml`: queries must never reference a
warehouse table by name (they run against every auto-discovered database, and one
unresolved relation 500s the entire `/metrics` endpoint — a `to_regclass` guard
does *not* help), and every query must emit a `datname` label or duplicate
metric/label pairs 500 it just the same. Grafana datasources and dashboards are
file-provisioned; UI edits are not written back to the repo.

## Adding a New Branch Office

### Capil

1. Create Airbyte connection → destination table `raw_<kantor_id>` in `capil_db`
2. Add `- name: raw_<kantor_id>` to `models/staging/sources.yml`
3. Create `models/staging/stg_<kantor_id>_capil.sql` (copy an existing one, update source name and `kantor_id` literal)
4. Add `UNION ALL SELECT * FROM {{ ref('stg_<kantor_id>_capil') }}` to `models/marts/mart_capil.sql`
5. `docker compose run --rm dbt dbt run`

### Finance

1. Add `raw_finance_rekap_<kantor_id>` and `raw_finance_rincian_<kantor_id>` to `sources.yml`
2. Create `models/staging/finance/stg_<kantor_id>_finance_rekap.sql` → `{{ stg_finance_rekap('<kantor_id>') }}`
3. Create `models/staging/finance/stg_<kantor_id>_finance_rincian.sql` → `{{ stg_finance_rincian('<kantor_id>') }}`
4. Add both `ref()` calls to their respective marts
5. `docker compose run --rm dbt dbt run` — safe to run before the Airbyte sync lands

If a new office uses different finance columns, update **both** branches (exists + missing) of `stg_finance_rekap` / `stg_finance_rincian` in `macros/finance_helpers.sql` to keep columns in sync.

## Data Persistence Notes

- PostgreSQL: bind-mounted at `./postgres-data:/var/lib/postgresql/data` (the `/data` suffix is required)
- Metabase app data: bind-mounted at `./metabase-data:/metabase-data`
- OnlyOffice: named volumes (`oo_data`, `oo_log`, `oo_cache`, `oo_db`)
- `postgres-data/` is not accessible to non-root users — don't try to read it directly
