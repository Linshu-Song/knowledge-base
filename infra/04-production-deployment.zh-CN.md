# 第四部分：生产部署

## 语言选择

- [English](04-production-deployment.md) - 英文
- **简体中文** (当前) - 本文档
- [繁體中文](04-production-deployment.zh-HK.md) - 繁体中文

## 目录

1. [环境层级](#1-环境层级)
2. [镜像构建与标记](#2-镜像构建与标记)
3. [密钥管理](#3-密钥管理)
4. [数据库迁移](#4-数据库迁移)
5. [数据库备份与恢复](#5-数据库备份与恢复)
6. [预发布部署](#6-预发布部署)
7. [生产部署](#7-生产部署)
8. [CI/CD 集成](#8-cicd-集成)

---

## 1. 环境层级

| 层级 | 用途 | 构建目标 | 配置来源 | 规模 |
|------|------|----------|----------|------|
| **开发** | 本地开发，热重载 | `dev` | `.dev.env` 文件 | 1–3 个开发者 |
| **预发布** | 生产前验证 | `prod` | `.staging.env` 文件 | 与生产一致 |
| **生产** | 面向客户 | `prod` | `.prod.env` + 密钥管理器 | 扩展、分布式 |

### 核心原则

1. **单一 Dockerfile，多个目标**：一个文件包含 `dev` 和 `prod` 目标
2. **环境一致性**：相同的基础镜像、相同的 schema — 仅配置不同
3. **不可变镜像**：构建后的镜像永不修改；配置来自环境变量
4. **渐进发布**：先部署预发布 → 验证 → 将相同镜像提升到生产
5. **零信任密钥**：敏感数据永远不在版本控制中

---

## 2. 镜像构建与标记

### 确定性标签

使用 Git SHA 实现可复现的构建：

```bash
GIT_SHA=$(git rev-parse --short HEAD)

# 开发
BUILD_TAG="dev-${GIT_SHA}"

# 预发布
BUILD_TAG="staging-${GIT_SHA}"

# 生产
BUILD_TAG="prod-${GIT_SHA}"
```

### 构建命令

```bash
# 构建单个服务
docker buildx build \
  --file ../api-gateway/Dockerfile \
  --target prod \
  --tag registry.company.com/api:sha-a1b2c3d \
  ../api-gateway

# 推送到注册中心
docker push registry.company.com/api:sha-a1b2c3d
```

### 使用 docker buildx bake 批量构建

#### `docker/bake.hcl`

```hcl
variable "DOCKER_REGISTRY" {
  default = "registry.company.com"
}

variable "BUILD_TAG" {
  default = "dev"
}

group "default" {
  targets = ["api", "frontend", "worker", "ai-service"]
}

target "api" {
  dockerfile = "Dockerfile"
  context    = "../api-gateway"
  platforms  = ["linux/amd64"]
  tags = [
    "${DOCKER_REGISTRY}/api:${BUILD_TAG}",
    "${DOCKER_REGISTRY}/api:latest"
  ]
  cache-from = ["type=registry,ref=${DOCKER_REGISTRY}/api:buildcache"]
  cache-to   = ["type=registry,ref=${DOCKER_REGISTRY}/api:buildcache,mode=max"]
}

target "frontend" {
  dockerfile = "Dockerfile"
  context    = "../web-app"
  platforms  = ["linux/amd64"]
  tags = [
    "${DOCKER_REGISTRY}/frontend:${BUILD_TAG}",
    "${DOCKER_REGISTRY}/frontend:latest"
  ]
}

target "worker" {
  dockerfile = "Dockerfile"
  context    = "../order-worker"
  platforms  = ["linux/amd64"]
  tags = [
    "${DOCKER_REGISTRY}/worker:${BUILD_TAG}",
    "${DOCKER_REGISTRY}/worker:latest"
  ]
}
```

#### 构建脚本

```bash
#!/bin/bash
# scripts/build-images.sh
set -euo pipefail

GIT_SHA=$(git rev-parse --short HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "$GIT_BRANCH" == "main" ]; then
  BUILD_TAG="prod-${GIT_SHA}"
elif [ "$GIT_BRANCH" == "staging" ]; then
  BUILD_TAG="staging-${GIT_SHA}"
else
  BUILD_TAG="feature-${GIT_BRANCH}-${GIT_SHA}"
fi

echo "构建镜像：tag=$BUILD_TAG"

docker buildx bake \
  --file docker/bake.hcl \
  --set "BUILD_TAG=$BUILD_TAG" \
  --load

echo "镜像已构建：$BUILD_TAG"
```

---

## 3. 密钥管理

### 原则

**永远不要在 .env 文件或版本控制中存储生产密钥。**

```
开发环境：    密钥在 .env 文件中（仅限本地开发）
预发布环境：  密钥来自密钥管理器或 CI/CD 变量
生产环境：    密钥来自密钥管理器（Vault、AWS SM、Azure KV 等）
```

### 密钥类型

| 类型 | 示例 | 存储方式 |
|------|------|----------|
| 数据库凭证 | `DB_PASSWORD`、`DATABASE_URL` | 密钥管理器 |
| API 密钥 | `JWT_SECRET`、第三方密钥 | 密钥管理器 |
| 证书 | TLS 证书、客户端证书 | 密钥管理器 / K8s Secrets |

### Vault 集成模式

```bash
#!/bin/bash
# scripts/load-secrets.sh
set -euo pipefail

ENVIRONMENT=${1:-staging}

# 认证到 Vault
if [ -z "${VAULT_TOKEN:-}" ]; then
  VAULT_TOKEN=$(cat ~/.vault-token)
fi

# 获取密钥到环境变量
vault kv get -format=json secret/data/${ENVIRONMENT}/platform \
  | jq -r '.data.data | to_entries | .[] | "\(.key)=\(.value)"' \
  > /tmp/secrets.${ENVIRONMENT}.env

# 导入到环境
set -a
source /tmp/secrets.${ENVIRONMENT}.env
set +a

echo "已加载 $ENVIRONMENT 的密钥"
```

### Docker Swarm Secrets

```bash
echo "your-jwt-secret" | docker secret create jwt_secret -
echo "db-password" | docker secret create db_password -
```

```yaml
# compose.prod.yaml
services:
  api:
    secrets:
      - jwt_secret
      - db_password
    environment:
      JWT_SECRET_FILE: /run/secrets/jwt_secret

secrets:
  jwt_secret:
    external: true
  db_password:
    external: true
```

### Kubernetes Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: platform-secrets
  namespace: production
type: Opaque
stringData:
  JWT_SECRET: "your-jwt-secret"
  DATABASE_PASSWORD: "db-password"
```

### 密钥轮换（零停机）

```bash
# 1. 在 Vault 中创建新密钥
vault kv put secret/staging/platform JWT_SECRET_NEW="new-value"

# 2. 更新应用以同时接受新旧密钥
# 3. 部署更新后的应用
# 4. 废弃旧密钥
vault kv delete secret/staging/platform/JWT_SECRET
# 5. 简化应用，仅使用新密钥
```

---

## 4. 数据库迁移

将迁移与部署分离。在启动更新后的服务**之前**运行迁移。

### Compose 中的迁移服务

```yaml
# compose.prod.yaml
services:
  db-migrate:
    image: registry.company.com/api:sha-a1b2c3d
    entrypoint: ["npm", "run", "db:migrate"]   # 或等效命令
    depends_on:
      database:
        condition: service_healthy
    env_file:
      - ./env/shared.prod.env
      - ./env/api.prod.env
    environment:
      DATABASE_MAX_CONNECTIONS: 1               # 不允许并行迁移
    profiles:
      - migrate

  api:
    image: registry.company.com/api:sha-a1b2c3d
    depends_on:
      db-migrate:
        condition: service_completed_successfully
    # ... 其余配置
```

### 部署流程

```bash
# 步骤 1：运行迁移
docker compose \
  --env-file ./env/compose.prod.env \
  -f compose.yaml \
  -f compose.prod.yaml \
  --profile migrate \
  run db-migrate

# 步骤 2：如果迁移成功，部署服务
docker compose \
  --env-file ./env/compose.prod.env \
  -f compose.yaml \
  -f compose.prod.yaml \
  up -d api worker frontend
```

---

## 5. 数据库备份与恢复

### 备份脚本

```bash
#!/bin/bash
# scripts/backup-db.sh
set -euo pipefail

ENVIRONMENT=${1:-staging}
BACKUP_DIR=./backups
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/db_${ENVIRONMENT}_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "备份 $ENVIRONMENT 数据库..."

docker compose exec database pg_dump \
  -U devuser \
  platform_db \
  | gzip > "$BACKUP_FILE"

echo "备份已保存：$BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
```

### 恢复脚本

```bash
#!/bin/bash
# scripts/restore-db.sh
set -euo pipefail

BACKUP_FILE=${1:?用法: restore-db.sh <备份文件>}

if [ ! -f "$BACKUP_FILE" ]; then
  echo "错误：文件不存在：$BACKUP_FILE"
  exit 1
fi

echo "警告：这将从备份恢复。输入 'yes' 继续："
read -r CONFIRM
if [ "$CONFIRM" != "yes" ]; then exit 1; fi

echo "正在从 $BACKUP_FILE 恢复..."

docker compose exec -T database psql -U devuser -d postgres \
  -c "DROP DATABASE IF EXISTS platform_db;"

docker compose exec -T database psql -U devuser -d postgres \
  -c "CREATE DATABASE platform_db;"

gunzip -c "$BACKUP_FILE" | \
  docker compose exec -T database psql -U devuser platform_db

echo "数据库已恢复"
```

---

## 6. 预发布部署

预发布环境镜像生产环境，用于在生产推送前进行验证。

```bash
#!/bin/bash
# scripts/deploy-staging.sh
set -euo pipefail

GIT_SHA=$(git rev-parse --short HEAD)
BUILD_TAG="staging-${GIT_SHA}"

echo "====== 预发布部署 ======"
echo "Git SHA: $GIT_SHA"

# 1. 构建镜像
docker buildx build \
  --file ../api-gateway/Dockerfile \
  --target prod \
  --tag registry.company.com/api:${BUILD_TAG} \
  ../api-gateway

# 2. 推送到注册中心
docker push registry.company.com/api:${BUILD_TAG}

# 3. 运行迁移
docker compose \
  --env-file ./env/compose.staging.env \
  -f compose.yaml \
  -f compose.staging.yaml \
  --profile migrate \
  run db-migrate

# 4. 部署服务
docker compose \
  --env-file ./env/compose.staging.env \
  -f compose.yaml \
  -f compose.staging.yaml \
  up -d api worker frontend

# 5. 记录部署
echo "已部署：$BUILD_TAG at $(date -u +'%Y-%m-%d %H:%M:%S UTC')"

echo "验证地址：https://api-staging.company.com"
```

---

## 7. 生产部署

将预发布环境中**验证过的相同镜像**提升到生产环境。

```bash
#!/bin/bash
# scripts/promote-to-prod.sh
set -euo pipefail

STAGING_TAG=${1:?用法: promote-to-prod.sh <预发布构建标签>}
PROD_TAG=$(echo "$STAGING_TAG" | sed 's/^staging-/prod-/')

echo "====== 生产提升 ======"
echo "从：$STAGING_TAG → 到：$PROD_TAG"

# 1. 验证预发布健康状态
STATUS=$(curl -s https://api-staging.company.com/health || echo "FAILED")
if [ "$STATUS" != "OK" ]; then
  echo "预发布健康检查失败。中止。"
  exit 1
fi

# 2. 重新标记镜像
docker pull registry.company.com/api:${STAGING_TAG}
docker tag registry.company.com/api:${STAGING_TAG} registry.company.com/api:${PROD_TAG}
docker push registry.company.com/api:${PROD_TAG}

# 3. 运行迁移
docker compose \
  --env-file ./env/compose.prod.env \
  -f compose.yaml \
  -f compose.prod.yaml \
  --profile migrate \
  run db-migrate

# 4. 部署
docker compose \
  --env-file ./env/compose.prod.env \
  -f compose.yaml \
  -f compose.prod.yaml \
  up -d api worker frontend

echo "生产部署完成"
echo "验证地址：https://api.company.com"
```

---

## 8. CI/CD 集成

### GitHub Actions（Monorepo 配合路径过滤）

```yaml
name: 部署 API Gateway

on:
  push:
    branches: [main]
    paths:
      - 'apps/api-gateway/**'
      - 'libs/shared-types/**'     # 共享依赖变更触发重建

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: 设置 Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: 登录注册中心
        uses: docker/login-action@v2
        with:
          registry: registry.company.com
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_PASSWORD }}

      - name: 构建并推送
        uses: docker/build-push-action@v4
        with:
          context: .
          file: apps/api-gateway/Dockerfile
          target: prod
          push: true
          tags: |
            registry.company.com/api:sha-${{ github.sha }}
            registry.company.com/api:main-latest
          cache-from: type=registry,ref=registry.company.com/api:buildcache
          cache-to: type=registry,ref=registry.company.com/api:buildcache,mode=max

      - name: 部署到生产（手动）
        if: github.ref == 'refs/heads/main'
        environment: production
        run: |
          ./infra/scripts/promote-to-prod.sh sha-${{ github.sha }}
```

### GitHub Actions（Polyrepo）

```yaml
name: 部署流水线

on:
  push:
    branches: [staging, main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: 构建并推送
        uses: docker/build-push-action@v4
        with:
          context: .
          file: ./Dockerfile
          target: prod
          push: true
          tags: |
            registry.company.com/api:sha-${{ github.sha }}

      - name: 部署到预发布
        if: github.ref == 'refs/heads/staging'
        run: ./scripts/deploy-staging.sh

      - name: 部署到生产
        if: github.ref == 'refs/heads/main'
        environment: production
        run: ./scripts/promote-to-prod.sh sha-${{ github.sha }}
```

### GitLab CI

```yaml
stages:
  - build
  - test
  - deploy-staging
  - deploy-prod

build-images:
  stage: build
  image: docker:latest
  services: [docker:dind]
  script:
    - docker buildx build --target prod --tag $REGISTRY/api:sha-$CI_COMMIT_SHORT_SHA .
    - docker push $REGISTRY/api:sha-$CI_COMMIT_SHORT_SHA
  only: [staging, main]

deploy-staging:
  stage: deploy-staging
  script: ./scripts/deploy-staging.sh
  environment:
    name: staging
    url: https://api-staging.company.com
  only: [staging]

deploy-prod:
  stage: deploy-prod
  script: ./scripts/promote-to-prod.sh sha-$CI_COMMIT_SHORT_SHA
  environment:
    name: production
    url: https://api.company.com
  when: manual
  only: [main]
```

---

*上一篇：[第三部分：开发环境](03-development-environment.zh-CN.md)*
*下一篇：[第五部分：运维与故障排查](05-operations-troubleshooting.zh-CN.md) — 监控、回滚和常见问题。*
