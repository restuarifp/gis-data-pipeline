#!/usr/bin/env bash
# Drive the gis-data-pipeline stack. Run from project root or any subdirectory.
# Usage: smoke.sh [up|down|status|dbt [args...]|dbt-validate]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

case "${1:-up}" in
  up)
    echo "Starting postgres and metabase..."
    docker compose up -d postgres-db metabase

    echo "Waiting for postgres..."
    for i in {1..30}; do
      docker compose exec -T postgres-db pg_isready -U admin -d metabase_db > /dev/null 2>&1 && break
      sleep 2
    done
    echo "PostgreSQL ready"

    echo "Waiting for Metabase (up to 3 min on first run)..."
    for i in {1..60}; do
      curl -sf http://localhost:3000/api/health > /dev/null 2>&1 && break
      sleep 3
    done
    curl -s http://localhost:3000/api/health
    echo ""
    echo "Metabase ready → http://localhost:3000"
    ;;

  down)
    docker compose down
    ;;

  status)
    docker compose ps
    echo ""
    curl -sf http://localhost:3000/api/health 2>/dev/null && echo "Metabase: UP" || echo "Metabase: down"
    ;;

  dbt)
    shift
    docker compose run --rm dbt dbt "${@:-run}" --profiles-dir .
    ;;

  dbt-validate)
    # Validates models locally — no live database or Docker required.
    # Requires: uv tool install dbt-core --with dbt-postgres --python 3.12
    export PATH="$HOME/.local/bin:$PATH"
    export DBT_POSTGRES_HOST=localhost
    export DBT_POSTGRES_USER=admin
    export DBT_POSTGRES_PW=password123
    export DBT_POSTGRES_DB=capil_db

    echo "Installing dbt packages (if needed)..."
    (cd dbt && dbt deps --profiles-dir .)

    echo "Parsing all models..."
    (cd dbt && dbt parse --profiles-dir .)

    echo "Listing models..."
    (cd dbt && dbt ls --profiles-dir .)
    echo "All models parsed OK"
    ;;

  *)
    echo "Usage: smoke.sh [up|down|status|dbt [dbt-args]|dbt-validate]"
    exit 1
    ;;
esac
