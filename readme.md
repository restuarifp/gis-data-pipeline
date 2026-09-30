# Data Warehouse Stack — Docker Compose

A geospatial-based remote worker data warehouse stack using PostgreSQL/PostGIS, Metabase, DBT, and OnlyOffice.

---

## Services

| Service | Image | Port | Description |
|---|---|---|---|
| `postgres-db` | `postgis/postgis:latest` | `5432` | PostgreSQL + PostGIS database |
| `metabase` | `metabase/metabase:latest` | `3000` | Data visualization dashboard |
| `dbt` | Custom (Dockerfile.dbt) | — | Data transformation (CLI only) |
| `excel-loader` | Custom (Dockerfile.excel-loader) | — | Loads each office's `finance.xlsx` from Nextcloud straight into `raw_finance_*` |
| `onlyoffice-docs` | `onlyoffice/documentserver:9.3.1.1` | `8080` | Document server |

---

## Prerequisites

- Docker & Docker Compose installed
- `Dockerfile.dbt` present in the project root
- `./dbt/` folder with DBT project files (`dbt_project.yml`, `profiles.yml`, `models/`)

---

## Configuration

Copy and fill in credentials before starting:

```env
POSTGRES_USER=<user>
POSTGRES_PASSWORD=<password>
JWT_SECRET=<secret>
```

Credentials are referenced in `docker-compose.yml` directly. Do **not** commit real credentials to version control.

---

## Getting Started

### 1. Start all services

```bash
docker compose up -d
```

### 2. Access services

| Service | URL |
|---|---|
| Metabase | http://localhost:3000 |
| OnlyOffice | http://localhost:8080 |
| PostgreSQL | `localhost:5432` |

### 3. Metabase initial setup

On first run, go to http://localhost:3000 and complete the setup wizard.

Connect Metabase to PostgreSQL using these credentials:

```
Host:     postgres-db
Port:     5432
Database: metabase_db
User:     <user>
Password: <password>
```

> Use `postgres-db` (service name), **not** `localhost` — services communicate via the internal `gisnet` Docker network.

---

## DBT Usage

DBT runs as a CLI-only service (via `profiles: ["cli_only"]`).

### Run DBT commands

```bash
# Test connection
docker compose run --rm dbt dbt debug

# Run all models
docker compose run --rm dbt dbt run

# Run a specific model
docker compose run --rm dbt dbt run --select <model_name>

# Install packages (e.g. dbt_utils)
docker compose run --rm dbt dbt deps
```

### DBT project structure

```
dbt/
├── dbt_project.yml
├── profiles.yml
├── packages.yml          # optional
├── macros/
│   └── finance_helpers.sql      # source_relation_exists() + stg_finance_rekap()/stg_finance_rincian() SQL generators
└── models/
    ├── staging/
    │   ├── sources.yml
    │   ├── stg_<kantor_id>_capil.sql
    │   └── finance/
    │       ├── stg_<kantor_id>_finance_rekap.sql
    │       └── stg_<kantor_id>_finance_rincian.sql
    └── marts/
        ├── mart_capil.sql
        └── finance/
            ├── mart_finance_rekap.sql
            └── mart_finance_rincian.sql
```

### Adding a new branch office (kantor perwakilan) — capil

1. Create a new Airbyte connection → destination table `raw_<kantor_id>`
2. Add the table to `models/staging/sources.yml`
3. Create `models/staging/stg_<kantor_id>_capil.sql` (copy existing, update source and `kantor_id`)
4. Add `UNION ALL SELECT * FROM {{ ref('stg_<kantor_id>_capil') }}` to `models/marts/mart_capil.sql`
5. Run `dbt run`

### Adding a new branch office — finance

Finance raw tables (`raw_finance_rekap_<kantor_id>` / `raw_finance_rincian_<kantor_id>`) are written by `excel-loader` (created on an office's first load) and may not exist yet for offices that haven't been loaded. The staging models handle this gracefully via `source_relation_exists()` in `macros/finance_helpers.sql`: if the raw table is physically missing, the model falls back to an empty result set with the same columns/types instead of failing with "relation does not exist". This keeps `mart_finance_rekap`/`mart_finance_rincian` (a `UNION ALL` across every known office, same pattern as `mart_capil.sql`) always runnable, contributing 0 rows for offices without data yet.

To onboard a new office: add its `<Kantor>/Finance` folder to `NEXTCLOUD_SOURCE_PATHS` (no Airbyte connection needed), then:

1. Add `raw_finance_rekap_<kantor_id>` and `raw_finance_rincian_<kantor_id>` to `models/staging/sources.yml` under the `raw` source
2. Create `models/staging/finance/stg_<kantor_id>_finance_rekap.sql` containing just `{{ stg_finance_rekap('<kantor_id>') }}`
3. Create `models/staging/finance/stg_<kantor_id>_finance_rincian.sql` containing just `{{ stg_finance_rincian('<kantor_id>') }}`
4. Add both to the `UNION ALL` lists in `models/marts/finance/mart_finance_rekap.sql` and `mart_finance_rincian.sql`
5. Run `dbt run` — no need to wait for the first load; the model compiles either way

If a future office's Excel template has different finance columns, update the column lists in both branches of `stg_finance_rekap`/`stg_finance_rincian` in `macros/finance_helpers.sql` (the "exists" and "missing" branches must always match column-for-column, or the `UNION ALL` in the mart breaks).

---

## Excel Loader Service

The `excel-loader` service (`scripts/excel_loader.py`) fetches each office's `finance.xlsx` from Nextcloud via WebDAV and writes the `REKAP` and `RINCIAN` sheets straight into `raw_finance_rekap_<kantor_id>` / `raw_finance_rincian_<kantor_id>` — one transaction per office, one new pull (`_airbyte_generation_id = MAX + 1`) per load. It replaced the old `split-excel` → Airbyte path; see `docs/adr/0005-loader-excel-langsung-ke-postgres.md`. Capil still comes in through Airbyte.

- Header row 1, normalised like Airbyte did (`TUNAI IFQ` → `TUNAI_IFQ`). A missing column, text in a numeric cell, or a formula saved without its result rejects that office (the previous pull stays in effect) and names the cells.
- Unchanged content is skipped if that office already has a pull this month, so the hourly schedule does not duplicate data.
- **Cutover:** disable the Airbyte finance connections (do **not** reset/clear them — that empties the raw tables and their history).

### Configuration

Set the following in `.env` (loaded via `env_file` in `docker-compose.yml`):

```env
# Required
NEXTCLOUD_URL=<nextcloud base url>
NEXTCLOUD_USER=<user>
NEXTCLOUD_PASSWORD=<password>
NEXTCLOUD_SOURCE_PATHS=<comma or newline separated source folders, e.g. A1/Finance,A2/Finance>

# Optional
NEXTCLOUD_SOURCE_HOME=<parent folder the paths above are relative to>
SCHEDULE_INTERVAL_MINUTES=60        # polling interval in --watch mode
LOAD_DB_HOST/PORT/NAME/USER/PASSWORD/SCHEMA   # defaults match this compose stack
WEBDAV_MAX_RETRIES=5                # download retries on HTTP 423/5xx
WEBDAV_RETRY_BACKOFF_SECONDS=3      # linear backoff between retries
```

> **Important:** After changing `.env`, recreate the container — a plain `restart` does **not** reload environment variables:
>
> ```bash
> docker compose up -d --force-recreate excel-loader
> ```

### Run once (manual)

Runs a single pass and exits (exit code 1 if any office failed):

```bash
docker compose run --rm excel-loader python excel_loader.py            # all folders
docker compose run --rm excel-loader python excel_loader.py A1/Finance # one folder
```

### Run as a watcher (background service)

The container's default command is `python excel_loader.py --watch --serve`, which loads every `SCHEDULE_INTERVAL_MINUTES` and serves the control API used by the Telegram `/load` command:

```bash
docker compose up -d --build excel-loader
docker compose logs -f excel-loader
docker compose stop excel-loader
```

---

## Data Persistence

PostgreSQL data is persisted via a bind mount:

```yaml
volumes:
  - ./postgres-data:/var/lib/postgresql/data
```

> **Important:** The `/data` suffix is required. Without it, data is lost on container restart.

OnlyOffice data is persisted via named volumes (`oo_data`, `oo_log`).

---

## Networking

All services (except `onlyoffice-docs`) share the `gisnet` bridge network, enabling inter-container communication by service name.

```
postgres-db  ←→  metabase    (MB_DB_HOST=postgres-db)
postgres-db  ←→  dbt         (DBT_POSTGRES_HOST=postgres-db)
```

---

## Stopping & Restarting

```bash
# Stop all services (data is preserved)
docker compose down

# Stop and remove volumes (WARNING: data loss)
docker compose down -v
```
