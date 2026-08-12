# Observability stack

Grafana + Prometheus + Loki, bolted onto the existing `gisnet` compose stack.
Everything lives under the `observability` compose profile, so plain
`docker compose up -d` still starts only the core services.

```bash
# start
docker compose --profile observability up -d

# stop just the observability services (core stack keeps running)
docker compose --profile observability stop prometheus grafana loki promtail node-exporter cadvisor postgres-exporter
```

| Service | Role | Host port |
|---|---|---|
| `grafana` | UI + dashboards | 3030 (`GRAFANA_PORT`) |
| `prometheus` | metrics store, 30d retention | 9090 |
| `loki` | log store, 30d retention | 3100 |
| `promtail` | ships Docker container logs → Loki | — |
| `node-exporter` | host CPU/mem/disk | — |
| `cadvisor` | per-container CPU/mem/net | — |
| `postgres-exporter` | PostgreSQL + pipeline metrics | — |

Login: `GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD` from `.env` (default `admin`/`admin`).
Grafana is on **3030**, not 3001 — 3000 is Metabase and 3001 was already taken on this host.

## What's provisioned

Datasources (`grafana/provisioning/datasources/datasources.yml`) — all created on boot,
no clicking required:

- **Prometheus** (default)
- **Loki**
- **capil_db** — the warehouse itself, so a dashboard can chart `analytics.*`
  (rows per kantor, finance rekap) next to infra metrics. Credentials come from
  the `DBT_POSTGRES_*` env vars already in `.env`.

Dashboard: **GIS Data Pipeline — Stack Overview** (`grafana/dashboards/stack-overview.json`).
Files in that folder are auto-loaded every 30s; drop more JSON in to add dashboards.
Edits made in the UI are allowed but are **not** written back to the file — export
and commit the JSON if you want them to survive.

## Pipeline metrics

`prometheus/postgres-queries.yml` adds warehouse-level metrics on top of the
exporter's defaults:

| Metric | Meaning |
|---|---|
| `pipeline_raw_freshness_live_rows{datname,table_name}` | estimated rows in each `raw_*` landing table |
| `pipeline_raw_freshness_last_maintenance_epoch` | last (auto)vacuum/analyze — proxy for "when did this table last get written" |
| `pipeline_raw_writes_inserts{datname,table_name}` | cumulative inserts; steps up when an Airbyte sync lands |
| `pipeline_dbt_models_{analytics_relations,staging_models,mart_models}{datname}` | how many objects dbt has built in `analytics` |

Two constraints on anything added to that file:

1. **Never name a warehouse table directly.** Auto-discovery runs every query
   against every database, so `analytics.mart_capil` fails on `metabase_db` and a
   single unresolved relation 500s the *whole* `/metrics` endpoint. A `WHERE
   to_regclass(...) IS NOT NULL` guard does not help — the planner resolves the
   name before the filter runs. Read catalog/stat views instead.
2. **Every query must carry a `datname` label** (`current_database() AS datname`).
   Without it the same query run against three databases emits duplicate
   metric+label pairs, which is also a hard 500.

After editing: `docker compose --profile observability restart postgres-exporter`,
then check `docker logs postgres_exporter` and that the target is green at
<http://localhost:9090/targets>.

## Logs

Promtail discovers containers via the Docker socket, so it picks up **every**
container on the host, not just this project's. Labels available in Loki:
`container`, `compose_service`, `compose_project`, `stream`. The dashboard's log
panel filters to this stack's services; to scope a query to the project use
`{compose_project="gis-data-pipeline"}`.

This is the practical answer to the notif-relay's best-effort design
(`docs/adr/0001-notifikasi-telegram-best-effort.md`): a dropped Telegram message
is only logged, and now that log is searchable in Grafana instead of living in
`docker logs` until the container restarts.

## Notes / gotchas

- `node-exporter` mounts `/` as plain `:ro`, not `:ro,rslave` — WSL2 mounts `/`
  as a private mount and rejects `rslave` at container start.
- `cadvisor` runs privileged; that's what it needs to read cgroups.
- Prometheus data, Grafana data and Loki chunks are in named volumes
  (`prom_data`, `grafana_data`, `loki_data`), so `docker compose down -v` wipes
  the history along with everything else.
