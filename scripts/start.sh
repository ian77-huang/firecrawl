#!/usr/bin/env bash
set -euo pipefail

docker compose pull
docker compose up -d

echo "Firecrawl API is starting at: http://localhost:${PORT:-3002}"
echo "Health check: curl http://localhost:${PORT:-3002}/health"
echo "Crawl test:    curl -X POST http://localhost:${PORT:-3002}/v1/crawl -H 'Content-Type: application/json' -d '{\"url\":\"https://docs.firecrawl.dev\"}'"
