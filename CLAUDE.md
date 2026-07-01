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
| `onlyoffice-docs` | onlyoffice/documentserver:9.3.1.1 | 8080 |

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
            (capil) and raw_<kantor_id>_finance_rekap / _rincian tables (finance)
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
- `models/staging/stg_<kantor_id>_capil.sql` — one per office; filters to latest Airbyte generation (`_airbyte_generation_id`), strips internal Airbyte columns, normalizes text fields to lowercase, adds `kantor_id` column
- `models/staging/finance/stg_<kantor_id>_finance_rekap.sql` / `_rincian.sql` — one-liner: `{{ stg_finance_rekap('<kantor_id>') }}` delegating to the macro
- `models/marts/mart_capil.sql` — `UNION ALL` across every staging capil model
- `models/marts/finance/mart_finance_rekap.sql` / `mart_finance_rincian.sql` — `UNION ALL` across every staging finance model

### Key macro (`dbt/macros/finance_helpers.sql`)

`source_relation_exists(relation)` — checks `information_schema.tables` at compile time; returns `false` during `dbt parse`/`dbt ls` (no DB connection). Used in `stg_finance_rekap` and `stg_finance_rincian` to gracefully handle offices whose Airbyte sync hasn't landed yet, returning an empty result set with matching columns instead of crashing.

**Critical invariant:** The "exists" and "missing" branches of both macros must have identical column names and types, or the `UNION ALL` in the mart breaks.

### split-excel service (`scripts/split_excel.py`)

Configured via `.env` (required: `NEXTCLOUD_URL`, `NEXTCLOUD_USER`, `NEXTCLOUD_PASSWORD`, `NEXTCLOUD_SOURCE_PATHS`, `NEXTCLOUD_DEST_PATH`; optional: `SCHEDULE_INTERVAL_MINUTES`, default 60).

- Accepts multiple source paths via `NEXTCLOUD_SOURCE_PATHS` (comma or newline separated)
- Output naming: `{kantor_name}__{file_stem}__{safe_sheet_name}.xlsx`
- Atomic per-office: if any sheet fails to process, the whole office is skipped and old files are not deleted
- `--watch` flag enables polling loop; without it, runs once and exits

## Adding a New Branch Office

### Capil

1. Create Airbyte connection → destination table `raw_<kantor_id>` in `capil_db`
2. Add `- name: raw_<kantor_id>` to `models/staging/sources.yml`
3. Create `models/staging/stg_<kantor_id>_capil.sql` (copy an existing one, update source name and `kantor_id` literal)
4. Add `UNION ALL SELECT * FROM {{ ref('stg_<kantor_id>_capil') }}` to `models/marts/mart_capil.sql`
5. `docker compose run --rm dbt dbt run`

### Finance

1. Add `raw_<kantor_id>_finance_rekap` and `raw_<kantor_id>_finance_rincian` to `sources.yml`
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
