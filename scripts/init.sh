#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] docker is not installed."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "[ERROR] docker compose plugin is not available."
  exit 1
fi

if [ ! -f .env ]; then
  cat > .env <<'ENV'
PORT=3002
INTERNAL_PORT=3002
HOST=0.0.0.0
USE_DB_AUTHENTICATION=false
REDIS_URL=redis://redis:6379
REDIS_RATE_LIMIT_URL=redis://redis:6379
PLAYWRIGHT_MICROSERVICE_URL=http://playwright-service:3000/scrape
NUQ_DATABASE_URL=postgres://postgres:postgres@nuq-postgres:5432/postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
POSTGRES_HOST=nuq-postgres
POSTGRES_PORT=5432
BULL_AUTH_KEY=CHANGEME
LOGGING_LEVEL=INFO
ENV
  echo "[OK] .env created."
else
  echo "[SKIP] .env already exists."
fi

docker compose config >/dev/null
echo "[OK] docker-compose.yml is valid."
echo "Run ./scripts/start.sh to start Firecrawl."
