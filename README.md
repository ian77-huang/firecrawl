# Firecrawl Self-Hosted (Local)

這個資料夾是用 Docker Compose 在本機啟動 Firecrawl 的 self-hosted 環境，包含：

- `api`: Firecrawl API
- `playwright-service`: 瀏覽器抓取服務
- `redis`: 快取與 rate limit
- `rabbitmq`: 佇列
- `nuq-postgres`: 內部任務/資料庫

## 目錄結構

- `docker-compose.yml`: 服務定義
- `.env`: 環境變數設定
- `scripts/init.sh`: 檢查 Docker、初始化 `.env`、驗證 compose
- `scripts/start.sh`: 拉最新 image 並背景啟動
- `scripts/stop.sh`: 關閉並移除 compose containers/network

## 快速開始

1. 初始化（首次或要重新檢查設定時）

```bash
./scripts/init.sh
```

2. 啟動服務

```bash
./scripts/start.sh
```

3. 驗證服務是否可用

```bash
curl -f http://localhost:3002/
```

4. 測試 crawl

```bash
curl -X POST http://localhost:3002/v1/crawl \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://docs.firecrawl.dev"}'
```

5. 停止服務

```bash
./scripts/stop.sh
```

## 常用指令

查看 logs：

```bash
docker compose logs -f
```

只看 API logs：

```bash
docker compose logs -f api
```

看服務狀態：

```bash
docker compose ps
```

## `.env` 重要設定

- `PORT`: 本機對外 API port（預設 `3002`）
- `CRAWL_CONCURRENT_REQUESTS`: 單工作流程抓取併發
- `MAX_CONCURRENT_JOBS`: 同時處理工作的上限
- `NUM_WORKERS_PER_QUEUE`: worker 數量
- `BROWSER_POOL_SIZE`: 瀏覽器池大小
- `BULL_AUTH_KEY`: 內部佇列授權 key，請改掉預設值 `CHANGEME`
- `PROXY_*`: 如果目標網站需要代理時設定
- `OPENAI_*` / `OLLAMA_BASE_URL`: 需要擴充模型能力時設定

## MCP 設定（讓 AI 連到本機 Firecrawl）

先確認本機 API 可用：

```bash
curl -f http://localhost:3002/
```

### 方式 A：`command` 型 MCP（常見）

在你的 AI 工具 MCP 設定檔加入：

```json
{
  "mcpServers": {
    "firecrawl": {
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_URL": "http://localhost:3002"
      }
    }
  }
}
```

如果你的 self-hosted 有啟用驗證，再加上：

```json
{
  "FIRECRAWL_API_KEY": "YOUR_API_KEY"
}
```

### 方式 B：HTTP 型 MCP（支援 HTTP MCP 的客戶端）

先在本機啟動 MCP server：

```bash
HTTP_STREAMABLE_SERVER=true FIRECRAWL_API_URL=http://localhost:3002 npx -y firecrawl-mcp
```

然後在 AI 工具填入 MCP URL：

```text
http://localhost:3000/v2/mcp
```

### 小提醒

- 你是 Docker 自架在本機時，`FIRECRAWL_API_URL` 通常用 `http://localhost:3002`。
- 若 AI 客戶端不在同一台機器，請改成可連到該主機的 IP 或網域，並確認防火牆/NAT/安全群組已放行對應 port。

### Antigravity 設定範例

如果你用的是 Antigravity，一樣是在它的 MCP 設定（`mcp.json` / Raw Config）加入 `firecrawl`：

```json
{
  "mcpServers": {
    "firecrawl": {
      "command": "npx",
      "args": ["-y", "firecrawl-mcp"],
      "env": {
        "FIRECRAWL_API_URL": "http://localhost:3002"
      }
    }
  }
}
```

若有啟用驗證，補上：

```json
{
  "FIRECRAWL_API_KEY": "YOUR_API_KEY"
}
```

設定後，重開 Antigravity 或在 MCP 管理頁重新載入，確認 `firecrawl` server 已啟用。

## 要注意的事

- `scripts/start.sh` 會先執行 `docker compose pull`，每次啟動可能更新到最新 image。
- `scripts/stop.sh` 內容是 `docker compose down`：
  - 會移除 containers 與 network。
  - 不會刪掉 named volume。
- 這份 compose 有定義 Postgres volume：`nuq_postgres_data`，因此 Postgres 內資料通常可保留。
- `redis`、`rabbitmq` 沒有額外掛持久化 volume，重啟或 down/up 後，暫存/佇列資料可能重置。
- 自架後不受 Firecrawl 雲端帳號配額限制，但仍受你機器資源、網路與目標站點 rate limit 影響。

## 故障排查

1. Port 衝突：
   - 改 `.env` 的 `PORT`，再重啟 `./scripts/start.sh`。
2. 服務起不來：
   - `docker compose ps`
   - `docker compose logs -f api`
   - `docker compose logs -f playwright-service`
3. 清空所有資料（包含 Postgres volume）：
   - `docker compose down -v`
   - 注意：這會刪除 `nuq_postgres_data`，屬於不可逆操作。
