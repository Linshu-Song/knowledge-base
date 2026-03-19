# 第二部分：基礎架構設定

## 語言選擇

- [English](02-infrastructure-setup.md) - 英文
- [简体中文](02-infrastructure-setup.zh-CN.md) - 簡體中文
- **繁體中文** (當前) - 本文檔

## 目錄

1. [Docker Compose 架構](#1-docker-compose-架構)
2. [基礎架構服務](#2-基礎架構服務)
3. [開發環境覆蓋](#3-開發環境覆蓋)
4. [環境變數策略](#4-環境變數策略)
5. [服務網絡](#5-服務網絡)
6. [多階段 Dockerfile 模式](#6-多階段-dockerfile-模式)

---

## 1. Docker Compose 架構

使用**分層 Compose 文件**方法：基礎文件定義基礎架構，覆蓋文件添加特定環境的配置。

### 文件層級結構

```
infra/ (or platform-dev/)
├── compose.yaml              # 基礎：基礎架構服務（始終首先加載）
├── compose.dev.yaml          # 開發覆蓋：綁定掛載、調試端口、熱重載
├── compose.staging.yaml      # 預備環境覆蓋：生產目標、預備環境配置
├── compose.prod.yaml         # 生產環境覆蓋：不可變映像、資源限制
└── env/
    ├── compose.dev.env       # Compose 插值變數（開發環境）
    ├── compose.staging.env   # Compose 插值變數（預備環境）
    ├── compose.prod.env      # Compose 插值變數（生產環境）
    ├── shared.base.env       # 跨服務運行時變數（所有環境）
    ├── shared.dev.env        # 跨服務運行時變數（開發環境覆蓋）
    ├── shared.prod.env       # 跨服務運行時變數（生產環境值）
    ├── service-a.dev.env     # 服務特定變數（開發環境）
    └── service-a.prod.env    # 服務特定變數（生產環境）
```

### 加載順序

```bash
# 後面的文件會覆蓋前面的文件
docker compose \
  --env-file ./env/compose.dev.env \
  -f compose.yaml \
  -f compose.dev.yaml \
  --profile dev \
  up -d
```

---

## 2. 基礎架構服務

基礎 Compose 文件定義所有服務依賴的共享基礎架構。具體的技術選擇（Postgres 與 MySQL、RabbitMQ 與 Kafka 等）取決於你的需求——模式是相同的。

### `compose.yaml`（基礎編排）

```yaml
services:
  database:
    image: postgres:16-alpine           # 或 mysql, mongodb 等
    environment:
      POSTGRES_USER: devuser
      POSTGRES_PASSWORD: devpass
      POSTGRES_DB: platform_db
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U devuser -d platform_db"]
      interval: 5s
      timeout: 3s
      retries: 10

  message-queue:
    image: rabbitmq:3-management-alpine  # 或 kafka, nats 等
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    ports:
      - "5672:5672"
      - "15672:15672"                    # 管理界面
    volumes:
      - mq_data:/var/lib/rabbitmq
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 5s
      timeout: 3s
      retries: 10

  cache:
    image: redis:7-alpine                # 或 memcached, valkey 等
    ports:
      - "6379:6379"
    volumes:
      - cache_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 10

  object-storage:
    image: minio/minio:latest            # 或 localstack 等
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - "9000:9000"
      - "9001:9001"                      # 控制台
    command: server /data --console-address ":9001"
    volumes:
      - storage_data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 5s
      timeout: 3s
      retries: 10

networks:
  default:
    driver: bridge

volumes:
  db_data:
  mq_data:
  cache_data:
  storage_data:
```

### 關鍵設計決策

- **所有基礎架構都配置健康檢查**：服務應該使用 `depends_on` 配合 `condition: service_healthy`，以避免啟動競態條件
- **命名卷**：數據在容器重啟後持久保存
- **預設網絡**：所有服務可以通過名稱互相訪問（Docker DNS）
- **Alpine 基礎映像**：佔用空間更小，拉取速度更快

---

## 3. 開發環境覆蓋

開發覆蓋文件添加綁定掛載、調試端口和應用程式服務。

### `compose.dev.yaml`

```yaml
services:
  # 你的應用程式服務
  api:
    build:
      context: ../api-gateway             # Monorepo：使用根目錄作為上下文
      dockerfile: Dockerfile
      target: dev                         # 多階段：使用開發目標
    command: npm run dev                   # 或你技術棧的等效命令
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: development
      DEBUG: "app:*"
    volumes:
      - ../api-gateway:/workspace/api-gateway
      - /workspace/api-gateway/node_modules   # 匿名卷：保護不被主機覆蓋
    depends_on:
      database:
        condition: service_healthy
      message-queue:
        condition: service_healthy
      cache:
        condition: service_healthy
    env_file:
      - ./env/shared.base.env
      - ./env/shared.dev.env
      - ./env/service-a.dev.env
    user: vscode
    profiles:
      - dev

  frontend:
    build:
      context: ../web-app
      dockerfile: Dockerfile
      target: dev
    command: npm start
    ports:
      - "3001:3000"
    environment:
      API_URL: http://localhost:3000
    volumes:
      - ../web-app:/workspace/web-app
      - /workspace/web-app/node_modules
    env_file:
      - ./env/shared.base.env
      - ./env/shared.dev.env
      - ./env/frontend.dev.env
    user: vscode
    profiles:
      - dev

  # 可選的開發工具
  adminer:
    image: adminer:latest
    ports:
      - "8080:8080"
    depends_on:
      - database
    profiles:
      - dev-optional

  mailhog:
    image: mailhog/mailhog:latest
    ports:
      - "1025:1025"
      - "8025:8025"
    profiles:
      - dev-optional
```

### Monorepo 與 Polyrepo：構建上下文的差異

```
# Monorepo：構建上下文是儲存庫根目錄
build:
  context: ..                            # Monorepo 根目錄
  dockerfile: apps/api-gateway/Dockerfile

# Polyrepo：構建上下文是服務目錄
build:
  context: ../api-gateway                # 服務儲存庫根目錄
  dockerfile: Dockerfile
```

---

## 4. 環境變數策略

使用**分層覆蓋**模式：基礎配置 → 特定環境 → 密鑰。

### 環境變數的兩個層級

| 層級 | 用途 | 來源 | 示例 |
|------|------|------|------|
| **Compose 插值** | 控制要拉取的映像、項目名稱 | `--env-file` 標誌 | `GATEWAY_IMAGE_TAG`, `COMPOSE_PROJECT_NAME` |
| **容器運行時** | 應用程式啟動時讀取的變數 | 服務配置中的 `env_file` | `DATABASE_URL`, `JWT_SECRET` |

### 文件內容

#### Compose 插值 (`compose.dev.env`)

```bash
# 控制 docker compose 行為，應用程式不會讀取
APP_ENV=development
COMPOSE_PROJECT_NAME=platform-dev
```

#### 共享運行時變數 (`shared.base.env`)

```bash
# 跨服務約定：服務發現、隊列名稱等
# 僅包含非敏感值 —— 提交到版本控制

DATABASE_HOST=database
DATABASE_PORT=5432
DATABASE_NAME=platform_db
MESSAGE_QUEUE_HOST=message-queue
MESSAGE_QUEUE_PORT=5672
CACHE_HOST=cache
CACHE_PORT=6379

# 內部服務 URL（通過 Docker DNS 解析）
API_URL=http://api:3000
WORKER_QUEUE_NAME=task_queue
EVENT_TOPIC=platform_events
```

#### 開發環境覆蓋 (`shared.dev.env`)

```bash
# 開發環境特定的覆蓋
LOG_LEVEL=debug
ENABLE_PROFILING=true
CACHE_TTL=60
```

#### 服務特定變數 (`service-a.dev.env`)

```bash
# 特定於某個服務的變數
PORT=3000
DATABASE_URL=postgres://devuser:devpass@database:5432/platform_db
MESSAGE_QUEUE_URL=amqp://guest:guest@message-queue:5672
CACHE_URL=redis://cache:6379/0
JWT_SECRET=dev-secret-change-in-prod
SESSION_TIMEOUT=86400
```

### 密鑰：永遠不要放入版本控制

```bash
# 生產環境密鑰來自外部密鑰管理器
# (Vault, AWS Secrets Manager, Azure Key Vault 等)
# 在部署時注入，不存儲在 .env 文件中

# .env 文件僅包含非敏感的、已提交的值
# 密鑰值使用佔位符名稱，例如：
JWT_SECRET=<loaded-from-vault>
DATABASE_PASSWORD=<loaded-from-vault>
```

---

## 5. 服務網絡

### Docker Compose 內部

同一個 Compose 項目中的所有服務共享一個網絡，可以通過服務名稱互相訪問：

```
# 從 api 容器：
http://database:5432           # 資料庫
http://message-queue:5672      # 消息隊列
http://cache:6379              # 緩存
http://frontend:3000           # 另一個服務

# 從主機（通過端口映射）：
http://localhost:3000          # API
http://localhost:5432          # 資料庫
http://localhost:15672         # 隊列管理界面
```

### 跨服務調用（示例）

```javascript
// Node.js：使用服務名稱（Docker DNS 解析）
const response = await fetch('http://ai-service:8001/api/infer', {
  method: 'POST',
  body: JSON.stringify({ input: '...' })
});
```

```python
# Python：相同的模式
import requests
response = requests.post('http://api:3000/api/data', json={'key': 'value'})
```

```go
// Go：相同的模式
resp, err := http.Post("http://api:3000/api/data", "application/json", body)
```

---

## 6. 多階段 Dockerfile 模式

每個服務都應該使用多階段構建，並設置 `dev` 和 `prod` 目標。

### 通用模式

```dockerfile
# 階段 1：base —— 系統依賴、通用設置
FROM <base-image> AS base
WORKDIR /app
RUN <install-system-dependencies>

# 階段 2：dev —— 包含調試工具、開發依賴、熱重載
FROM base AS dev
RUN <install-dev-tools>
COPY package*.json ./               # 或 requirements.txt, go.mod 等
RUN <install-all-dependencies>
COPY . .
USER vscode
CMD ["<hot-reload-command>"]

# 階段 3：prod —— 最小運行時，無調試工具
FROM base AS prod
COPY package*.json ./
RUN <install-production-dependencies-only>
COPY . .
RUN <build-step-if-needed>
RUN <cleanup-build-artifacts>
EXPOSE <port>
USER nobody
CMD ["<production-entrypoint>"]
```

### Node.js 示例

```dockerfile
FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache python3 make g++ git

FROM base AS dev
RUN npm install -g nodemon
COPY package*.json ./
RUN npm ci --include=dev
COPY . .
USER vscode
CMD ["nodemon", "--exec", "node", "--inspect=0.0.0.0:9229", "dist/index.js"]

FROM base AS prod
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
RUN npm run build
RUN rm -rf src/ tests/ *.config.js
EXPOSE 3000
USER nobody
CMD ["node", "dist/index.js"]
```

### Python 示例

```dockerfile
FROM python:3.11-slim AS base
WORKDIR /app
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

FROM base AS dev
COPY requirements.txt requirements-dev.txt* ./
RUN pip install -r requirements.txt
RUN if [ -f requirements-dev.txt ]; then pip install -r requirements-dev.txt; fi
COPY . .
USER vscode
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001", "--reload"]

FROM base AS prod
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN python -m py_compile app/
USER nobody
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
```

### 為什麼要使用多階段構建？

| 方面 | 開發目標 | 生產目標 |
|------|----------|----------|
| 調試工具 | 包含（nodemon、調試器等） | 不包含 |
| 開發依賴 | 已安裝 | 不安裝 |
| 源代碼 | 保留（用於熱重載） | 構建後移除 |
| 用戶 | `vscode`（非 root，UID 映射） | `nobody`（最小權限） |
| 映像大小 | 較大（開發環境可接受） | 最小化 |
| 攻擊面 | 較大 | 最小化 |

---

*上一篇：[第一部分：架構概述](01-architecture-overview.zh-HK.md)*
*下一篇：[第三部分：開發環境](03-development-environment.zh-HK.md) — Dev Containers、Git/SSH 設定及日常工作流程。*
