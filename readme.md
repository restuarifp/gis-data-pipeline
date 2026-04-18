# Data Warehouse Stack — Docker Compose

A geospatial-based remote worker data warehouse stack using PostgreSQL/PostGIS, Metabase, DBT, and OnlyOffice.

---

## Services

| Service | Image | Port | Description |
|---|---|---|---|
| `postgres-db` | `postgis/postgis:latest` | `5432` | PostgreSQL + PostGIS database |
| `metabase` | `metabase/metabase:latest` | `3000` | Data visualization dashboard |
| `dbt` | Custom (Dockerfile.dbt) | — | Data transformation (CLI only) |
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
└── models/
    ├── staging/
    │   ├── sources.yml
    │   └── stg_<kantor_id>_capil.sql
    └── marts/
        └── mart_capil.sql
```

### Adding a new branch office (kantor perwakilan)

1. Create a new Airbyte connection → destination table `raw_<kantor_id>`
2. Add the table to `models/staging/sources.yml`
3. Create `models/staging/stg_<kantor_id>_capil.sql` (copy existing, update source and `kantor_id`)
4. Add `UNION ALL SELECT * FROM {{ ref('stg_<kantor_id>_capil') }}` to `models/marts/mart_capil.sql`
5. Run `dbt run`

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
