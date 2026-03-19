# 第五部分：操作與故障排除

## 語言選擇

- [English](05-operations-troubleshooting.md) - 英文
- [简体中文](05-operations-troubleshooting.zh-CN.md) - 簡體中文
- **繁體中文** (當前) - 本文檔

## 目錄

1. [健康檢查](#1-健康檢查)
2. [日誌記錄](#2-日誌記錄)
3. [指標與追蹤](#3-指標與追蹤)
4. [回滾程序](#4-回滾程序)
5. [故障排除：Docker Compose](#5-故障排除-docker-compose)
6. [故障排除：開發容器](#6-故障排除-開發容器)
7. [故障排除：檔案權限](#7-故障排除-檔案權限)
8. [故障排除：網絡](#8-故障排除-網絡)
9. [生產環境清單](#9-生產環境清單)

---

## 1. 健康檢查

每個服務都必須公開健康端點。

### 應用程式健康端點

```typescript
// Example: Node.js / Express
import { Router } from 'express';

const router = Router();

// Liveness: is the process running?
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.APP_ENV,
  });
});

// Readiness: can the service handle requests?
router.get('/health/ready', async (req, res) => {
  try {
    await database.query('SELECT 1');
    await cache.ping();
    res.json({ ready: true });
  } catch (error) {
    res.status(503).json({ ready: false, error: error.message });
  }
});
```

### Compose 健康檢查

```yaml
services:
  api:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 30s     # 啟動寬限期
```

### 檢查健康狀態

```bash
# 從主機
curl -s http://localhost:3000/health | jq .

# 從另一個容器
docker compose exec frontend curl -s http://api:3000/health

# Compose 狀態
docker compose ps
```

---

## 2. 日誌記錄

### 日誌驅動程式配置

```yaml
# compose.prod.yaml
services:
  api:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"        # 10MB 時輪換
        max-file: "3"          # 保留 3 個輪換檔案
        labels: "service=api,environment=prod"
```

### 檢視日誌

```bash
# 追蹤所有日誌
docker compose logs -f

# 追蹤特定服務
docker compose logs -f api

# 最近 100 行
docker compose logs --tail=100 worker

# 搜尋錯誤
docker compose logs | grep -i error

# 自指定時間以來
docker compose logs --since "2026-03-19T10:00:00" api
```

### 應用程式層級日誌記錄

在生產環境中使用結構化日誌（JSON）以便輕鬆解析：

```javascript
// Example: structured logger
logger.info({
  event: 'request_completed',
  method: 'GET',
  path: '/api/users',
  statusCode: 200,
  duration_ms: 45,
  requestId: 'abc-123'
});
```

---

## 3. 指標與追蹤

### Prometheus 指標（範例）

```typescript
import prom from 'prom-client';

const httpDuration = new prom.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
});

const databaseQueryDuration = new prom.Histogram({
  name: 'database_query_duration_seconds',
  help: 'Duration of database queries',
  labelNames: ['query_type'],
});

const activeConnections = new prom.Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
});
```

### 分散式追蹤（使用 OpenTelemetry 的範例）

```typescript
import { trace } from '@opentelemetry/api';

const tracer = trace.getTracer('app-tracer');

async function handleRequest(req) {
  const span = tracer.startSpan('handle_request');
  try {
    // ... business logic
    span.setAttribute('http.method', req.method);
    span.setAttribute('http.route', req.path);
  } finally {
    span.end();
  }
}
```

---

## 4. 回滾程序

### 立即服務回滾

如果生產環境部署出現問題，快速恢復到之前的映像：

```bash
#!/bin/bash
set -euo pipefail

PREVIOUS_TAG="prod-xyz9876"     # 從部署日誌取得

echo "正在回滾到 $PREVIOUS_TAG"

docker pull registry.company.com/api:${PREVIOUS_TAG}

docker compose \
  --env-file ./env/compose.prod.env \
  -f compose.yaml \
  -f compose.prod.yaml \
  up -d --force-recreate api

# 驗證
sleep 10
curl -s https://api.company.com/health

echo "回滾完成"
```

### 資料庫回滾

```bash
# 如果遷移破壞了什麼：

# 1. 從遷移前備份還原
./scripts/restore-db.sh ./backups/db_prod_20260318_100000.sql.gz

# 2. 使用之前的程式碼版本重新啟動服務
docker compose restart api
```

### 定時復原

```bash
# 找到事件前最近的一個備份
BACKUP_FILE=$(find ./backups -name "db_prod_*.sql.gz" | sort -r | head -1)
./scripts/restore-db.sh "$BACKUP_FILE"
```

---

## 5. 故障排除：Docker Compose

### 「連接埠已被佔用」

**原因**：另一個行程正在使用該連接埠。

```bash
# 找出佔用連接埠的程式
lsof -i :3000          # macOS/Linux
netstat -ano | findstr :3000   # Windows

# 停止容器
docker compose down

# 或終止特定容器
docker kill $(docker ps -q --filter "publish=3000")

# 重新啟動
docker compose up -d
```

### 「服務無法連接到資料庫」

**原因**：資料庫尚未就緒，或不在同一網絡。

```bash
# 檢查資料庫狀態
docker compose ps database

# 檢查健康狀態
docker compose exec database pg_isready -U devuser -d platform_db

# 檢查日誌
docker compose logs database

# 如果不健康則重新啟動
docker compose restart database
```

### 「無法解析主機」

**原因**：容器內 DNS 解析失敗。

```bash
# 快速修復：重新啟動
docker compose restart

# 持久修復：在 compose.yaml 新增 DNS
# services:
#   api:
#     dns: [8.8.8.8, 1.1.1.1]

docker compose up -d --force-recreate api
```

---

## 6. 故障排除：開發容器

### 開發容器啟動時間過長

**原因**：首次 Docker 映像構建（下載基礎映像、安裝依賴項）、Docker Desktop 緩慢，或網絡緩慢。

**修復**：

```bash
# 在開啟前預先構建映像
cd platform-dev
docker compose build gateway

# 或使用預先構建的映像，而非從 Dockerfile 構建
# 在 devcontainer.json 中，使用 "image" 而非 "dockerComposeFile"：
{
  "image": "node:20-alpine",
  "postCreateCommand": "npm install"
}
# 這以自訂性換取啟動速度
```

### 「無法啟動開發容器」

**原因**：Compose 語法錯誤、缺少服務或資源限制。

```bash
# 驗證 Compose 檔案
docker compose \
  --env-file ./env/compose.dev.env \
  -f compose.yaml \
  -f compose.dev.yaml \
  config > /tmp/merged.yaml

# 檢視合併後的配置
cat /tmp/merged.yaml

# 檢查 Docker Desktop 資源
# 至少分配：4 個 CPU、6GB RAM、20GB 磁碟

# 檢查日誌
docker compose logs api

# 重新構建容器
docker compose build --no-cache api
docker compose up -d api
```

### 「VS Code 無法連接到容器」

**原因**：容器崩潰或擴展問題。

```bash
# 檢查容器是否正在運行
docker compose ps api

# 如果已退出，查看原因
docker compose logs api

# 重新啟動
docker compose restart api

# 在 VS Code 中：命令面板 → 「開發容器：重新在容器中開啟」

# 如果仍然失敗，重新構建
docker compose build --no-cache api
docker compose up -d api
```

### SSH Agent 未轉送到容器內

**原因**：SSH socket 未掛載到容器中。

**修復**：在 `devcontainer.json` 中新增：

```json
{
  "mounts": [
    "source=${localEnv:SSH_AUTH_SOCK},target=/run/host-services/ssh-auth.sock,readonly"
  ]
}
```

並在 compose.yaml 服務中新增：

```yaml
services:
  gateway:
    environment:
      SSH_AUTH_SOCK: /run/host-services/ssh-auth.sock
```

### macOS 上綁定掛載效能緩慢

**原因**：macOS Docker Desktop 使用虛擬化層，檔案同步速度緩慢。

**修復**（按優先順序）：

1. **為 node_modules 使用命名卷：**
```yaml
services:
  gateway:
    volumes:
      - ../api-gateway:/workspace/api-gateway
      - node_modules:/workspace/api-gateway/node_modules  # 獨立卷，速度更快
volumes:
  node_modules:
```

2. **啟用 VirtioFS**（macOS 上更快的檔案同步）：
   - Docker Desktop → 設定 → 資源 → 勾選「使用 VirtioFS」
   - 需要 Docker Desktop 4.22+

3. **接受緩慢** — 典型情況下慢 30-40%，對大多數工作流程而言並非致命。

### 多個開發容器衝突同一服務

**問題**：兩個 VS Code 視窗競爭同一個 gateway 服務。

**修復**：為不同服務使用獨立的 VS Code 視窗。如果需要在同一服務上開啟兩個視窗，請使用不同的 Docker Compose profile 或分開的 compose 檔案。

### .env 變更後環境變數未重新載入

**原因**：Docker Compose 在啟動時解釋 `env_file`；變更後需要完整重啟。

**修復**：

```bash
# 停止並移除容器（強制重新構建環境）
docker compose down gateway
docker compose up -d gateway

# 然後在 VS Code 中重新連接
```

---

## 7. 故障排除：檔案權限

### 掛載卷上出現「權限被拒」

**原因**：容器用戶無法寫入主機目錄。

```bash
# 在主機上：修正權限
chmod -R a+rw ~/workspace/api-gateway

# 或確保這些設定：
# devcontainer.json: "updateRemoteUserUID": true
# compose.yaml: user: vscode

# 重新啟動
docker compose down api && docker compose up -d api
```

### 「node_modules 無法從主機訪問」

**這是預期且有意的。** 匿名卷可防止效能問題：

```yaml
volumes:
  - ../api-gateway:/workspace/api-gateway
  - /workspace/api-gateway/node_modules    # 匿名卷（不在主機上）
```

要重新安裝依賴項：

```bash
docker compose exec api npm ci
```

---

## 8. 故障排除：網絡

### 「服務之間無法連接」

```bash
# 驗證兩個服務都在運行
docker compose ps api ai-service

# 測試連接
docker compose exec api ping ai-service

# 驗證在同一網絡
docker network inspect <project>_default | grep -A 10 Containers
```

### 「無法從容器連接到資料庫」

```bash
# 檢查資料庫正在運行
docker compose ps database

# 檢查日誌
docker compose logs database | tail -20

# 嘗試直接連接
docker compose exec api psql -h database -U devuser -d platform_db -c "SELECT 1"

# 如果連接被拒絕，等待（資料庫可能仍在啟動）
sleep 10
docker compose exec api psql -h database -U devuser -d platform_db -c "SELECT 1"
```

---

## 9. 生產環境清單

### 基礎架構

- [ ] 資料庫有自動化備份（最少每小時一次）
- [ ] 所有服務都配置了健康檢查
- [ ] 資源限制設定適當
- [ ] 負載均衡器 / 入口配置了 SSL
- [ ] DNS 指向正確的端點

### 密鑰

- [ ] 所有敏感值在密鑰管理器中（不在 .env 檔案中）
- [ ] 資料庫密碼在 90 天內輪換
- [ ] API 密鑰有短期有效期，盡可能配置自動輪換
- [ ] TLS 憑證有效且配置了自動續期

### 監控與警報

- [ ] 應用程式指標導出（Prometheus 格式或等效格式）
- [ ] 日誌集中且可搜尋
- [ ] 配置了警報：高 CPU、高記憶體、健康檢查失敗、錯誤率飆升
- [ ] 已建立值班輪值

### 測試

- [ ] 已使用負載測試驗證預備環境部署
- [ ] 已手動測試回滾程序
- [ ] 已測試資料庫備份/還原
- [ ] 所有服務通過冒煙測試

### 文件

- [ ] 部署操作手冊已編寫並測試
- [ ] 事件應對程序已記錄
- [ ] 架構圖保持最新
- [ ] 團隊知道部署腳本的位置

---

*上一部分：[第四部分：生產環境部署](04-production-deployment.zh-HK.md)*

---

## 摘要

| 部分 | 主題 | 關鍵要點 |
|------|-------|-------------|
| [第一部分](01-architecture-overview.zh-HK.md) | 架構概覽 | 根據團隊規模和發布節奏選擇單一儲存庫與多儲存庫 |
| [第二部分](02-infrastructure-setup.zh-HK.md) | 基礎架構設定 | 分層 Compose 檔案 + 多階段 Dockerfile |
| [第三部分](03-development-environment.zh-HK.md) | 開發環境 | 開發容器 + SSH Agent 轉送 |
| [第四部分](04-production-deployment.zh-HK.md) | 生產環境部署 | 預備環境優先晉升、密鑰管理器、路徑過濾 CI/CD |
| [第五部分](05-operations-troubleshooting.zh-HK.md) | 操作與故障排除 | 健康檢查、回滾程序、常見修復 |
