# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A geospatial-based remote worker data warehouse stack for tracking civil registration (capil) and finance data across multiple branch offices (kantor perwakilan). Raw data flows from Nextcloud (via Excel) → Airbyte (capil) / `excel-loader` (finance) → PostgreSQL/PostGIS → dbt → Metabase.

## Stack

| Service | Image/Tech | Port |
|---|---|---|
| `postgres-db` | postgis/postgis:latest | 5432 |
| `metabase` | metabase/metabase:latest | 3000 |
| `dbt` | Custom Dockerfile.dbt (Python 3.9 + dbt-postgres) | CLI only |
| `excel-loader` | Custom Dockerfile.excel-loader (Python 3.12) | — |
| `notif-relay` | Custom Dockerfile.notif-relay (Python 3.12) | 8000 |
| `dbt-runner` | Custom Dockerfile.dbt (server kontrol job) | — |
| `onlyoffice-docs` | onlyoffice/documentserver:9.3.1.1 | 8080 |
| `grafana` | grafana/grafana:latest | 3030 |
| `prometheus` | prom/prometheus:latest | 9090 |
| `loki` | grafana/loki:latest | 3100 |
| `promtail` | grafana/promtail:latest | — |
| `node-exporter` / `cadvisor` / `postgres-exporter` | Prometheus exporters | — |

Services share a `gisnet` bridge network; inter-service references use Docker service names (e.g., `postgres-db`), not `localhost`.

**Roadmap:** `docs/plans/0001-ingest-and-input-quality.md` — data contracts + smart Excel template, replacing Airbyte with a direct Postgres loader, config-driven datasets for new divisions. Read it before touching ingestion. Done so far: finance moved off Airbyte to `excel-loader` (ADR 0005); capil still on Airbyte.

## Common Commands

```bash
# Start core services (postgres + metabase + onlyoffice)
docker compose up -d

# Run dbt (connects to capil_db, writes to analytics schema)
docker compose run --rm dbt dbt run
docker compose run --rm dbt dbt run --select <model_name>
docker compose run --rm dbt dbt debug          # test connection
docker compose run --rm dbt dbt deps           # install packages

# Load finance Excel into Postgres once (without --watch loop); optional folder args
docker compose run --rm excel-loader python excel_loader.py [A1/Finance ...]

# Start the notif-relay (Airbyte capil webhook → Telegram + bot perintah + Mini App); listens on :8000
docker compose up -d notif-relay

# Mini App page (needs MINI_APP_URL set; /api/* returns 401 without Telegram initData)
curl -s localhost:8000/app | head -5

# Rebuild the relay after changing report_summary.py or docs/template/summary.xlsx
docker compose build notif-relay && docker compose up -d notif-relay

# Trigger a job the way the Telegram bot does (control server, gisnet-internal)
docker run --rm --network gis-data-pipeline_gisnet curlimages/curl -s -X POST excel-loader:8080/run
docker run --rm --network gis-data-pipeline_gisnet curlimages/curl -s excel-loader:8080/status

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
    ├── excel_loader.py (scripts/, service excel-loader)       [finance]
    │       Reads <Kantor>/Finance/finance.xlsx, sheets REKAP + RINCIAN, and appends
    │       one pull to raw_finance_rekap_<kantor_id> / raw_finance_rincian_<kantor_id>
    └── Airbyte                                                  [capil]
            Syncs capil Excel into PostgreSQL as raw_<kantor_id> tables
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
- `models/history/hist_*.sql` — every pull (not just the latest), all offices, for the Rekap Bulanan month snapshot; see that section

### Key macro (`dbt/macros/finance_helpers.sql`)

`source_relation_exists(relation)` — checks `information_schema.tables` at compile time; returns `false` during `dbt parse`/`dbt ls` (no DB connection). Used in `stg_finance_rekap` and `stg_finance_rincian` to gracefully handle offices that haven't been loaded yet, returning an empty result set with matching columns instead of crashing.

**Critical invariant:** The "exists" and "missing" branches of both macros must have identical column names and types, or the `UNION ALL` in the mart breaks.

**Latest-pull filter:** Every staging model (capil + finance) filters to `_airbyte_generation_id = MAX(_airbyte_generation_id)` so only the most recent pull is shown — a month may contain several pulls, and a single extraction batch can produce differing `_airbyte_extracted_at` values across its rows, so the generation id (not extraction time) is the reliable batch key.

**`stg_finance_rincian` columns:** mirror the finance file exactly — `INSTANSI`, then `TUNAI_*` and `NOMINAL_*` for the 10 jenis (FI, ZF, AQQ, FDY, IFQ, LQT, SDQ, SNK, TDY, ZKT). There are **no** `WAJIB_*` columns in the file and no `JUMLAH_WARGA`; the only wajib column is the derived `wajib_ifq` below.

**Derived `wajib_ifq`:** In `stg_finance_rincian`, `wajib_ifq` is *not* read from the finance file — it is computed from the office's capil table (`raw_<kantor_id>`): `COUNT(*)` of latest-pull rows per instansi where `LMG = INSTANSI` and `Status_Tabungan = 'Paham'` (COALESCE to 0 when an instansi has no capil match). This makes `stg_finance_rincian` depend on **both** `raw_finance_rincian_<kantor_id>` **and** `raw_<kantor_id>`; the capil source must be declared in `sources.yml` for every office passed to the macro. If the capil table doesn't physically exist yet, `wajib_ifq` falls back to `NULL` (guarded by `source_relation_exists`).

### excel-loader service (`scripts/excel_loader.py`)

Replaced `split-excel` + the Airbyte finance connections (`docs/adr/0005-loader-excel-langsung-ke-postgres.md`). Configured via `.env` (required: `NEXTCLOUD_URL`, `NEXTCLOUD_USER`, `NEXTCLOUD_PASSWORD`, `NEXTCLOUD_SOURCE_PATHS`; optional: `NEXTCLOUD_SOURCE_HOME`, `SCHEDULE_INTERVAL_MINUTES` default 60, `LOAD_DB_*` defaults match compose, `LOAD_TIMEZONE`, `WEBDAV_MAX_RETRIES`, `WEBDAV_RETRY_BACKOFF_SECONDS`). `NEXTCLOUD_DEST_PATH` is ignored.

- **Writes the exact Airbyte table shape.** `_airbyte_raw_id/_extracted_at/_meta/_generation_id` are still written, each load is one pull with `generation_id = MAX + 1` (Append semantics), so staging's latest-pull filter, `hist_pulls`, and the Rekap Bulanan work unchanged. Loader rows carry `_airbyte_meta->>'loader' = 'excel-loader'`, plus `source_file` and `sha256`. Missing tables are created on first load (new office needs no Airbyte connection).
- **Contract in code (`DATASETS`)**: sheet `REKAP` → `raw_finance_rekap_<kantor>`, `RINCIAN` → `raw_finance_rincian_<kantor>`; header row 1 normalised like Airbyte (`TUNAI IFQ` → `TUNAI_IFQ`). kantor_id = folder above `Finance`, lowercased.
- **Every problem is collected, not just the first**: each office's result carries `masalah`, a list of structured items `{jenis, galat, sistem?, file, sheet, sel, kolom, nilai, detail}` (capped at `BATAS_MASALAH_PER_KANTOR`). Any `galat` item (missing column/sheet, text in a numeric cell, formula without cached result, unreadable file, …) rejects the office; `galat: false` items (unknown sheet, extra column) are notes. `sistem: true` marks Nextcloud/DB faults rather than filler mistakes. The loader never writes user-facing sentences — `scripts/rekap_masalah.py` does.
- **Atomic per office**: both tables in one transaction; any failure → nothing for that office changes, previous pull stays current.
- **Skip unchanged — within the month**: if the data hash equals the latest pull's and that pull is from the current month (`LOAD_TIMEZONE` → `REPORT_TIMEZONE` → Asia/Jakarta), no rows are written. Every month still gets its own pull for the Rekap Bulanan snapshot.
- **Airbyte still writing = warning**: non-loader rows newer than the last loader pull are flagged (`airbyte_aktif`) in the Telegram message. Airbyte's generation counter can be lower than the loader's, making its pulls invisible — disable (never reset/clear) the finance connections.
- The template formats rows down to 1,048,576; reading stops after `BATAS_BARIS_KOSONG` (1000) fully-empty rows.
- `NEXTCLOUD_SOURCE_HOME` / `resolve_source()` rules are unchanged from split-excel: idempotent join, security boundary for `/load <path>`, `..` always rejected, empty `SOURCE_HOME` = no boundary (warned at startup).
- **Control server (`--serve`)**: `job_control.serve()` exposes `POST /run` (202 / 409 busy / 400 rejected params), `GET /status`, `GET /logs` on `JOB_CONTROL_PORT` (8080) — **gisnet only, never published to the host**. `POST /run {"sources": [...]}` runs a subset. CMD is `--watch --serve`; the scheduled run goes through `JobRunner.run_now()` so it shares the single-flight lock and shows up in `/status` (`last_trigger: "jadwal"`). `run_once()` returns `{"ok", "kantor": [...]}`, exposed as `last_result`.
- Without `--watch`, runs once and exits (exit code 1 if any office failed).

### notif-relay service (`scripts/notif_relay.py`)

The **Relay Notifikasi** (see `CONTEXT.md`): a tiny stdlib-only HTTP server that receives Airbyte webhook notifications and forwards them to a Telegram group. Configured via `.env` (required: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`; optional: `NOTIF_RELAY_PORT` default 8000, `TELEGRAM_MAX_RETRIES` default 3, `TELEGRAM_RETRY_BACKOFF_SECONDS` default 3).

- **Best-effort by design** (`docs/adr/0001-notifikasi-telegram-best-effort.md`): every `POST` replies `200` *immediately*, then the Telegram send runs in a daemon thread with linear-backoff retry. Final failure is only logged — the message is dropped, and Airbyte is never made to think the Job failed. **No notification is not proof a sync didn't run; Airbyte UI is the source of truth.**
- **One Job = one message.** Airbyte fires one webhook per Job (not per Stream), so the relay emits one Telegram message per call.
- **Fails fast on missing config:** an empty/absent `TELEGRAM_BOT_TOKEN` or `TELEGRAM_CHAT_ID` logs one clear line and exits **78** (`EX_CONFIG`). The compose restart policy is `on-failure:3`, so a misconfigured relay stops after 3 attempts instead of crash-looping. Note an *empty* value in `.env` is still a set env var — hence the explicit emptiness check, not `os.environ[...]`.
- Accepts any POST path (health check on `GET /`). `format_message()` is defensive: it reads the structured `data` object of Airbyte's custom webhook, falls back to a Slack-style `{text}` field, and dumps raw JSON for unknown shapes. All interpolated values are HTML-escaped (`parse_mode=HTML`).
- Airbyte is **not** in this compose stack — point its webhook notification at `http://<host>:8000/` (the relay publishes host port 8000 on `gisnet`).
- **`/sync` triggers Airbyte** via its Public API (`AIRBYTE_URL`, `AIRBYTE_CLIENT_ID`, `AIRBYTE_CLIENT_SECRET`; optional `AIRBYTE_WORKSPACE_ID`). Connections are resolved by **name** from `GET /connections`, so no UUIDs in `.env`; an ambiguous name fails with the candidate list rather than guessing. Unlike load/dbt there is no control server and no single-flight lock — Airbyte owns its own job queue — and **completion is reported by Airbyte's existing webhook to this relay**, not by `watch_jobs()`.
- Airbyte's token endpoint takes `grant-type` (hyphen, not `grant_type`) and answers **401 — not 400** — when that field is wrong or missing, so a malformed body masquerades as bad credentials. Token is cached until ~30s before expiry and refreshed once on a 401.
- **Two-way bot** (`docs/adr/0002-trigger-job-via-telegram.md`): a `getUpdates` long-polling thread accepts `/load [path...]`, `/dbt [select]`, `/sync [connection]`, `/laporan`, `/keuangan`, `/status`, `/logs [load|dbt]`, `/app`, `/id`, `/help`. `/split` is a deprecated alias for `/load` (`ALIAS_JOB`, also honoured by the Mini App API). It triggers jobs by calling the control servers over `gisnet` (`LOAD_CONTROL_URL`, `DBT_CONTROL_URL`; a leftover `SPLIT_CONTROL_URL` is ignored with a warning because it points at the removed `split-excel` host) — **never via the Docker socket**, because the relay eats outside input.
- **Who may command the bot**: the group `TELEGRAM_CHAT_ID`, plus any user id listed in `TELEGRAM_DM_USER_IDS` (comma/space separated) talking to the bot in a DM. Everything else is ignored silently — the rejected user's id is logged, since that's the number to paste into the allowlist. `/id` replies with the sender's user and chat id so nobody needs a third-party bot to find it. A group member who is *not* on the DM allowlist can still DM `/start`, `/app`, `/help`, `/id` — enough to open the Mini App panel, nothing more.
- **DM-triggered runs report back to that DM.** `langgan_hasil()` records the private chat that triggered a job; `_lapor_selesai()` sends the finished-run message to the group *and* to that chat, then clears the list (one run = one report each). Group-triggered runs subscribe nobody, so the group never gets a duplicate.
- `/status` also prints the config the container is actually running with (`info` block from `/status`: `source_home`, resolved `sources`, `db`, interval). This is the remote-debugging path: `docker compose restart` re-reads neither `.env` nor a rebuilt image, so a stale container is otherwise invisible from Telegram. `fitur` other than `load-db` means the container isn't running the excel-loader image.
- **Every finished run is announced to the group**, not just Telegram-triggered ones. `watch_jobs()` polls each control server's `/status` every `JOB_WATCH_INTERVAL_SECONDS` and reports when `last_finished` changes — so the hourly `--watch` run reports too. For `load`, the message is **one plain-Bahasa recap for all offices** (`scripts/rekap_masalah.py`, copied into the relay image): which offices got new data, which were unchanged, which were rejected — and for each rejected office, the cells, what they contain, and how to fix them (similar cells grouped; renamed columns/sheets hinted). System faults go in a separate "untuk admin" section. Formatting rule: only things a reader would copy (cell addresses, the corrected value, exact sheet/column/file names) are `<code>` (tap-to-copy in Telegram); technical error text is an expandable `<blockquote>`, never `<code>`/`<pre>` — the same goes for the log tail in the generic job-failed message. Identical bad values in one sheet (e.g. `-` in 100 cells) collapse into one line. This replaces both the Airbyte finance webhooks and per-office failure messages. A **scheduled** run with no new data and the same problem fingerprint (`rekap_masalah.sidik`) as the last recap is not sent; unresolved problems are re-sent as a reminder after `REKAP_ULANG_JAM` (default 24). A state change (problems appear or are fixed) is always sent; manual runs always get a reply. The dedupe state is in memory, so a relay restart may repeat one recap. Completion is reported *only* there (the command handler just acks `▶️ dimulai`), which is what keeps manual runs from getting two messages. `last_finished` is seeded at relay startup so a restart doesn't re-announce an old run. Disable with `JOB_WATCH_ENABLED=false`.
- The bot does **not** validate `/load` paths; it forwards them and surfaces the control server's `400`. Path rules live only in `resolve_source()` — two copies of a rule drift, and the looser one becomes the hole.
- Long-polling means the token must have **no webhook** set and only **one** polling process may run per token (Telegram answers 409 otherwise). An invalid token (401/404) shuts the command loop down with one clear log line; the Airbyte webhook path keeps running.
- **Mini App** (`docs/adr/0003-mini-app-telegram.md`, page in `scripts/miniapp.html`): the relay also serves a Telegram Mini App at `GET /app` with a JSON API at `/api/*` (`state`, `logs`, `connections`, `run`, `sync`) — same capabilities as the text commands, plus source-folder chips, a dbt command picker, an Airbyte connection list, live status, and an auto-refreshing log tail. `/app` in Telegram replies with the button that opens it.
- **Mini App auth**: every `/api/*` call re-verifies the `initData` HMAC against the bot token (`hash` and `signature` excluded from the data-check string) *and* that the user is either listed in `TELEGRAM_DM_USER_IDS` (no round-trip needed — the id was written by hand in `.env`) or a member of `TELEGRAM_CHAT_ID` via `getChatMember` (cached 5 min, fail-closed). There is no session or cookie — `initData` is the credential, and `MINI_APP_AUTH_MAX_AGE` (default 24h) caps its life. The page never validates `sources`/`select` itself; it forwards them and shows the control server's 400 (same rule as the text bot).
- **Mini App needs a public HTTPS URL.** Telegram refuses `http://`, so `MINI_APP_URL` must point at a reverse proxy/tunnel that forwards to `/app`; empty = feature off. `web_app` buttons are private-chat-only, so in the group `/app` uses a direct link (`MINI_APP_DIRECT_LINK`, from BotFather `/newapp`). That's also why `/start`, `/app`, `/help` are answered in DMs — for group members only, and only to open the panel.
- Actions taken from the panel are announced to the group ("dimulai oleh @siapa lewat Mini App"); completion is still reported only by `watch_jobs()`.
- **Laporan Rekap Bulanan** (`docs/adr/0004-laporan-rekap-bulanan.md`, builder in `scripts/report_summary.py`): `/laporan [MM-YYYY]` and the Mini App's *laporan* tab query the warehouse directly, fill `docs/template/summary.xlsx`, and push the result to Telegram with `sendDocument`. The only text sent
alongside it is one line naming who asked; everything else goes to the log. See
the section below.

### Laporan Rekap Bulanan (`scripts/report_summary.py`)

Turns the Metabase rekap query into the printable Excel that used to be filled
in by hand. Triggered by `/laporan [MM-YYYY]` in Telegram or the *laporan* tab in
the Mini App (`POST /api/report`), both of which hand off to a background thread
and reply immediately; the finished `.xlsx` arrives as a Telegram document.

- **Delivery is `sendDocument`, never an HTTP download.** The Mini App runs in
  Telegram's webview, which blocks page-initiated downloads — a download button
  would appear to work and produce nothing. The file lands in the group chat, so
  past months stay searchable.
- **The template is filled, not redrawn.** `openpyxl` opens
  `docs/template/summary.xlsx` and writes into existing cells, so merges,
  borders, and number formats survive. Column → query-field mapping lives in
  `KOLOM`; `D` (BARIS) counts distinct `LMG LIKE 'KPJ%'`, `T` (P+A) is derived, and
  `S` (NT) is deliberately left alone because the query has no equivalent.
- **The report for month X is a snapshot as of the end of month X.** It does
  *not* read staging (latest pull only). It reads `hist_capil`,
  `hist_finance_rekap`, `hist_finance_rincian` (`dbt/models/history/`, macro
  `hist_pulls` in `macros/history_helpers.sql`), which keep every pull
  with `tarikan_id` (= generation id) and `ditarik_pada` (MIN extracted_at per
  generation, epoch rows dropped). Per office and per source the query takes
  the latest pull before the 1st of the next month in `REPORT_TIMEZONE`
  (default Asia/Jakarta). This only works because every pull is appended —
  capil via Airbyte **Full refresh | Append** (switch one to Overwrite and its
  history is gone), finance via `excel-loader`, which always appends.
  DAKWAH HASIL is additionally filtered on `Bln_Integrasi`/`Th_Integrasi`.
  Offices falling back to an older pull, or with no finance pull yet, are
  noted in the relay log. History views discover offices from `sources.yml`,
  so a new office needs no new history model; `hist_finance_rincian` has no
  `wajib_ifq` on purpose.
- **Every finished report archives its own snapshot** to `REPORT_HISTORY_DIR`
  (`./report-history`, bind-mounted at `/data/laporan`) as
  `<year>-<month>.json`, and the next month's report reads the previous month's
  archive to fill `JUMLAH BULAN LALU`, with `SELISIH` computed from the two.
  The raw tables hold past pulls only while capil's Airbyte connections stay
  on Append (and nobody resets a connection), and the archive is the only record of what was actually *reported*,
  so **back that folder up**. A month with no archive behind it
  gets zeros, noted in the relay log. Rerunning a month overwrites its archive,
  which is what you want after a late sync or load.
- **Archive keys are semantic names** (`NAMA_KOLOM`), not column letters, so
  inserting a column in the template does not silently reroute old archives
  into the wrong cells.
- **Summary rows are found by their column-A labels** (`JUMLAH BULAN INI`,
  `JUMLAH BULAN LALU`, `SELISIH`), not by fixed row numbers; data rows run from
  row 5 up to the `JUMLAH BULAN INI` row. Adding offices to the template needs
  no code change — just a new row with its code in column C. Offices present in
  the warehouse but absent from the template are named in the relay log.
- **Summary rows are written as numbers, replacing the template's
  `=SUM(...)`/`=X19-X20`** — Telegram's file preview does not recalculate
  formulas and would show the stale cached result. Cells the template leaves
  empty stay empty, so a short row keeps its shape.
- **`REPORT_XLSX_PASSWORD`** sets an open-password on the sent `.xlsx`
  (`msoffcrypto-tool`, ECMA-376 Agile encryption — openpyxl can't do this);
  empty = no password. If it is set but the library is missing, the report is
  **disabled** rather than sent unprotected. Encrypted files get no Telegram
  preview. The JSON archive in `REPORT_HISTORY_DIR` is not encrypted.
- Config is `REPORT_DB_*`, `REPORT_SCHEMA`, `REPORT_VIEW_HIST_*`,
  `REPORT_TIMEZONE`, `REPORT_TEMPLATE`, `REPORT_HISTORY_DIR`, `REPORT_XLSX_PASSWORD`; the defaults match
  this compose stack. The old `REPORT_VIEW_*` (pointing at `stg_all_*`) are
  ignored — renamed on purpose so a stale `.env` can't feed staging views in. `psycopg2` and
  `openpyxl` are imported defensively, so an image built before this feature
  keeps running with the report disabled and says so instead of crashing.

### Laporan Keuangan (`scripts/report_finance.py`)

`/keuangan [MM-YYYY]` and the *Laporan keuangan* button in the Mini App's laporan tab
(`POST /api/report {"jenis": "keuangan"}`) fill `docs/template/monthly-finance-report.xlsx`
and send it with `sendDocument`. Delivery, password, locking and the one-line caption are
shared with the Rekap Bulanan (`LAPORAN` in `notif_relay.py` maps `jenis` → builder module;
a builder needs `laporan_aktif()` and `bangun_laporan(bulan, tahun)`).

- Same snapshot rule and `hist_*` views as the Rekap Bulanan. One query returns
  per-(month, office) rows from the first finance pull up to the report month; the top
  table is the report month per office, the bottom table is all-office totals per month
  of that year (later months stay empty).
- Columns: NASABAH TUNAI = `SUM(TUNAI_IFQ)` from rincian; NASABAH AKTIF 1/2/3 = capil rows per K; WAJIB/POKOK/SUKARELA = rekap `NOMINAL IFQ/ZKT/SDQ`
  `total_100_persen`; TOTAL SETOR = `SUM(disetor)` over all rekap rows except `TOTAL`;
  CAD = rekap `CAD` (trimmed — the file has `'CAD '`) `disetor`; JUMLAH PETUGAS = capil
  pengurus (LMG not PRA/PJ%/KPJ%).
- **AKUMULASI CAD** is recomputed from the warehouse, not archived: running sum of CAD over
  months whose finance pull is *from that month*. An office reusing an older pull shows
  that pull's CAD BULAN INI but does not add it again. Accuracy depends on finance raw
  tables never being reset.
- **Columns are found by their row-4 header text** (`HEADER` in `report_finance.py`), and
  rows by column-A labels (office codes, `TOTAL`, `BULAN`, month names), so columns can be
  moved and offices added without code changes. A missing header, or a merged header
  whose width doesn't match its field list (NASABAH AKTIF = 3), fails the report with an
  error naming it. Totals are written as numbers.
- **Charts are generated in code, never stored in the template** — openpyxl drops existing
  charts when it loads a workbook. They go on the report sheet itself, below the monthly
  table (two rows under its `TOTAL`), cell-anchored (`TwoCellAnchor`) to the table's width
  via `TINGKAT`. The header row is found by `NAMA KOPERASI` in column A, so nothing depends
  on fixed row numbers. One y-axis per chart: the nasabah tunai + wajib/pokok/sukarela
  chart is an **index** (first month with data = 100), its values written to hidden
  columns right of the monthly table (`visible_cells_only = False`). Prints A4 portrait,
  one page wide, charts on a new page after the table; the print area is set explicitly
  because the default stops at the last filled cell and clips the bottom charts.

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

0. Add the office's `<Kantor>/Finance` folder to `NEXTCLOUD_SOURCE_PATHS` and recreate `excel-loader` — no Airbyte connection; the loader creates both raw tables on first load
1. Add `raw_finance_rekap_<kantor_id>` and `raw_finance_rincian_<kantor_id>` to `sources.yml`
2. Create `models/staging/finance/stg_<kantor_id>_finance_rekap.sql` → `{{ stg_finance_rekap('<kantor_id>') }}`
3. Create `models/staging/finance/stg_<kantor_id>_finance_rincian.sql` → `{{ stg_finance_rincian('<kantor_id>') }}`
4. Add both `ref()` calls to their respective marts
5. `docker compose run --rm dbt dbt run` — safe to run before the first load

If the finance columns change, update `DATASETS` in `scripts/excel_loader.py` **and both** branches (exists + missing) of `stg_finance_rekap` / `stg_finance_rincian` in `macros/finance_helpers.sql`, plus `hist_finance_*`.

## Data Persistence Notes

- PostgreSQL: bind-mounted at `./postgres-data:/var/lib/postgresql/data` (the `/data` suffix is required)
- Metabase app data: bind-mounted at `./metabase-data:/metabase-data`
- OnlyOffice: named volumes (`oo_data`, `oo_log`, `oo_cache`, `oo_db`)
- `postgres-data/` is not accessible to non-root users — don't try to read it directly
