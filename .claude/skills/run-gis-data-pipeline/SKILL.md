---
name: run-gis-data-pipeline
description: Build, run, and drive gis-data-pipeline. Use when asked to start the stack, run dbt models, validate dbt SQL, test the pipeline, check Metabase, or interact with the running services.
---

A Docker Compose data warehouse stack: PostgreSQL/PostGIS, Metabase (web UI at :3000), dbt (SQL transforms), and OnlyOffice (:8080). Drive it via `.claude/skills/run-gis-data-pipeline/smoke.sh` — one command that handles service bring-up, health checks, dbt execution, and dbt model validation without a live DB.

All paths below are relative to the project root (`/home/eq/development/gis-data-pipeline/`).

## Prerequisites

Docker and Docker Compose must be installed for the full stack. For dbt-validate only (no Docker, no DB), install dbt via uv:

```bash
# Install uv (if not present)
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# Install dbt-core 1.11+ with postgres adapter — must use Python 3.12, not 3.14+
uv tool install dbt-core --with dbt-postgres --python 3.12
```

Verified: `dbt --version` → Core 1.11.11, postgres 1.10.0. **Python 3.14 is the system default but is incompatible with mashumaro (a dbt-core transitive dep) — always force `--python 3.12`.**

## Setup

dbt packages (dbt_utils) must be installed once in `dbt/`:

```bash
export PATH="$HOME/.local/bin:$PATH"
export DBT_POSTGRES_HOST=localhost DBT_POSTGRES_USER=admin DBT_POSTGRES_PW=password123 DBT_POSTGRES_DB=capil_db
cd dbt && dbt deps --profiles-dir .
```

The docker-compose.yml hardcodes credentials (`admin` / `password123`). No `.env` file is required.

## Run (agent path)

The smoke script handles everything. Run from any directory within the project:

```bash
.claude/skills/run-gis-data-pipeline/smoke.sh [command]
```

| command | what it does |
|---|---|
| `up` | `docker compose up -d postgres-db metabase`, polls until both are healthy |
| `down` | `docker compose down` |
| `status` | `docker compose ps` + Metabase health check |
| `dbt [args]` | `docker compose run --rm dbt dbt [args] --profiles-dir .` |
| `dbt-validate` | parse + list all models locally — **no Docker or live DB needed** |

### Validate dbt models without Docker

The most useful agent path for PR reviews — verifies SQL templates and macro expansion compile without errors:

```bash
.claude/skills/run-gis-data-pipeline/smoke.sh dbt-validate
```

Expected output: 15 models + 14 sources listed, "All models parsed OK".

### Start the full stack

```bash
.claude/skills/run-gis-data-pipeline/smoke.sh up
# → PostgreSQL ready
# → {"status":"ok"} (Metabase health response)
# → Metabase ready → http://localhost:3000
```

Metabase takes 1–3 minutes on first run (JVM startup). The script polls up to 3 minutes.

### Run dbt transforms

```bash
# Run all models
.claude/skills/run-gis-data-pipeline/smoke.sh dbt run

# Run a specific model
.claude/skills/run-gis-data-pipeline/smoke.sh dbt run --select stg_a1_capil

# Test connection
.claude/skills/run-gis-data-pipeline/smoke.sh dbt debug

# Install packages inside the container
.claude/skills/run-gis-data-pipeline/smoke.sh dbt deps
```

### Check Metabase

```bash
curl -s http://localhost:3000/api/health
# → {"status":"ok","components":{"db":{"status":"ok"},...}}
```

## Run (human path)

```bash
docker compose up -d          # starts postgres, metabase, onlyoffice
# → http://localhost:3000 (Metabase), http://localhost:8080 (OnlyOffice)
docker compose down           # stop, data preserved
docker compose down -v        # stop + delete volumes (data loss)
```

## Test

dbt model validation (no DB required):

```bash
.claude/skills/run-gis-data-pipeline/smoke.sh dbt-validate
# → "All models parsed OK"
```

Full dbt test (requires running stack):

```bash
.claude/skills/run-gis-data-pipeline/smoke.sh dbt test
```

---

## Gotchas

- **dbt runs in a Docker profile** — `docker compose up` without `--profile cli_only` does NOT start the dbt container; it only runs via `docker compose run --rm dbt`. The smoke.sh `dbt` command handles this correctly.

- **dbt DBT_POSTGRES_DB is `capil_db`, not `metabase_db`** — the dbt adapter connects to a separate database (`capil_db` in `profiles.yml`) while Metabase's own metadata lives in `metabase_db`. Both sit in the same `postgres-db` container.

- **dbt compile requires a live DB; dbt parse does not** — `dbt compile` actually queries pg_catalog to resolve column types for `dbt_utils.star()`. Use `dbt parse` + `dbt ls` for offline model validation.

- **Python 3.14 breaks dbt-core** — mashumaro (dbt-core dep) raises `UnserializableField` at import time on Python 3.14. Install with `--python 3.12` via uv. System python is 3.14.

- **Metabase first-run setup wizard** — on a fresh volume, Metabase shows a setup wizard. Connect using `postgres-db` (container hostname, not `localhost`) as the host.

- **onlyoffice JWT secret** — hardcoded in docker-compose.yml as `susSyf-dihdaq-7xudfa`. The env var is `JWT_SECRET`.

## Troubleshooting

- **`Env var required but not provided: 'DBT_POSTGRES_HOST'`**: env vars must be `export`-ed before running dbt, not passed inline with a single command. Use `export VAR=val && dbt ...` or put them all in `export` lines first.

- **`dbt found 1 package(s) specified in packages.yml, but only 0 package(s) installed`**: run `dbt deps --profiles-dir .` from `dbt/` first.

- **`connection to server at "localhost" (127.0.0.1), port 5432 failed: timeout expired`** during `dbt compile`: compile tries to connect to postgres. Use `dbt parse` instead for offline validation.

- **`No module named pip`** (system python3): pip is not available on this system. Use uv to install tools: `curl -LsSf https://astral.sh/uv/install.sh | sh`.
