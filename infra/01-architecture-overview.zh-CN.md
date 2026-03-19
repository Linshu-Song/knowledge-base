# 第一部分：存储库架构概述

## 语言选择

- [English](01-architecture-overview.md) - 英文
- **简体中文** (当前) - 本文档
- [繁體中文](01-architecture-overview.zh-HK.md) - 繁体中文

## Table of Contents

1. [单体存储库 vs 多存储库](#1-单体存储库-vs-多存储库)
2. [单体存储库：核心概念](#2-单体存储库核心概念)
3. [多存储库：核心概念](#3-多存储库核心概念)
4. [两种模式中的共享库](#4-两种模式中的共享库)
5. [目录结构示例](#5-目录结构示例)
6. [决策指南](#6-决策指南)

---

## 1. 单体存储库 vs 多存储库

多服务平台存在两种主要的存储库策略。没有哪种是绝对优越的；正确的选择取决于团队规模、发布节奏和组织架构。

### 功能逐项对比

| 维度 | 单体存储库 | 多存储库 |
|-----------|----------|----------|
| **代码共享** | 优秀。应用间原生导入。共享库可被前端和 API 直接使用。 | 复杂。需要发布到私有仓库或使用 Git 子模块。 |
| **原子性变更** | 是的。单个 PR 可以同时修改 API 契约、后端实现和前端消费者。 | 不是。需要跨多个仓库创建多个 PR 并仔细协调。 |
| **新成员入职** | 简单。`git clone` 一次。所有代码、基础设施和文档立即可用。 | 中等。需要克隆平台仓库加上多个服务仓库。 |
| **CI/CD 复杂度** | 高。流水线必须使用路径过滤或 Nx/Turborepo 等工具。 | 低。标准流水线——如果某个仓库被推送，就构建和部署该仓库。 |
| **Git Clone 大小** | 较大。包含所有服务的完整历史记录。 | 较小。开发者只拉取他们工作的部分。 |
| **语言混合** | 中等。混合生态系统（如不同的依赖管理器）需要规范管理。 | 简单。每个仓库完全专注于自己的语言生态系统。 |
| **访问控制** | 全有或全无。通常每个人都对整个代码库有读取权限。 | 精细化。易于限制对特定服务的访问。 |

### 单体存储库

所有服务、应用程序和共享库都位于**一个 Git 存储库**中。

**优势：**
- 跨服务原子性变更（一次提交同时涉及 API 和前端）
- 通过本地引用共享代码——无需发布到包仓库
- 统一的 CI/CD 流水线，支持基于路径的过滤
- 单一克隆，统一的分支策略
- 当共享接口变更时，IDE 和编译器会立即在所有消费者中暴露错误

**权衡：**
- 存储库会随着时间增长而变得庞大
- CI 必须使用路径过滤以避免重建所有内容
- 随着复杂度增长需要工具支持（如 Nx、Turborepo、Bazel）
- 如果团队规模大，所有权边界会变得模糊

### 多存储库

每个服务都有自己**独立的 Git 存储库**。一个中心的"平台"存储库管理共享的基础设施（Compose 文件、Dev Container、环境配置）。

**优势：**
- 每个服务独立的 CI/CD、版本控制和发布节奏
- 清晰的团队所有权边界
- 更小、更专注的存储库
- 无需单体存储库工具的开销
- 天然边界强制执行——开发者不会意外耦合服务

**权衡：**
- 跨服务变更需要协调多个 PR
- 共享代码必须发布到仓库（npm、PyPI 等）或进行 vendoring
- 新成员入职需要克隆多个仓库
- 保持基础设施配置同步需要手动操作（通过中心平台仓库可以缓解）

---

### 深度解析：单体存储库的优势

#### "共享契约"模式

在多服务平台中，后端 API、前端和后台工作进程通常共享**数据传输对象（DTO）**、验证模式和事件负载。

**在多存储库中**，向消息负载添加新字段：
1. 更新 shared-contracts 仓库 → 发布新版本
2. 更新 API 网关仓库 → 安装新版本 → 部署
3. 更新工作进程仓库 → 安装新版本 → 部署

**在单体存储库中**：
1. 在**同一分支**中更新共享契约文件、更新网关和工作进程
2. 运行测试。合并一个 PR。两个服务一起部署。

#### 重构信心

当你在单体存储库中更改核心工具或 API 接口时，你的 IDE 和编译器会立即在**每个**使用它的应用程序中暴露错误。在多存储库中，你可能要等到下游仓库的 CI 运行后数小时或数天才能发现这个破坏性变更。

---

### 深度解析：多存储库的优势

#### 边界强制执行

多存储库天然防止"意大利面条式代码"。在单体存储库中，开发者可能直接将一个服务的数据库模型导入到另一个服务中。多存储库使这成为不可能，迫使开发者通过实际的网络边界（API、消息队列等）进行通信。

#### 构建隔离

如果一个团队维护着使用完全不同工具链的计算密集型构建，他们无需浏览不相关的配置。他们的 CI/CD 流水线保持专注和独立。

---

## 2. 单体存储库：核心概念

### 工作空间

大多数语言生态系统都支持工作空间链接：

```
# Node.js (npm/yarn/pnpm)
"workspaces": ["apps/*", "libs/*"]

# Python (poetry/uv)
# Use path dependencies in pyproject.toml

# Go
# Use Go modules with replace directives
```

### 基于路径的 CI/CD

仅重建和重新部署受变更影响的服务：

```yaml
# Example: trigger deploy only when specific paths change
on:
  push:
    paths:
      - 'apps/api-gateway/**'
      - 'libs/shared-types/**'   # Shared dependency changes trigger rebuild
```

### 构建工具

随着单体存储库的增长，支持依赖感知的构建工具变得必不可少：

- **Turborepo** / **Nx**：计算依赖图，仅构建变更的部分
- **Bazel** / **Pants**：语言无关的密封构建，适用于大规模系统

```bash
# Turborepo: build only services affected since 'main'
npx turbo run build --filter=...[origin/main]
```

---

## 3. 多存储库：核心概念

### 中心平台存储库

一个专用存储库（如 `platform-dev`）持有所有共享基础设施：

```
platform-dev/
├── compose.yaml               # Base orchestration (database, queue, cache)
├── compose.dev.yaml           # Development overrides
├── compose.prod.yaml          # Production overrides
├── env/                       # Environment variable files
├── .devcontainer/             # Dev Container definitions per service
├── docker/                    # Shared base Dockerfiles
├── scripts/                   # Setup, deploy, backup scripts
└── docs/                      # Onboarding, architecture docs
```

### 服务存储库

每个服务都是独立的：

```
api-gateway/                   # Independent Git repo
├── Dockerfile                 # Inherits from platform-dev base images
├── src/
├── tests/
└── package.json
```

### Git 凭据管理

Git 凭据（SSH 密钥、令牌）保留在主机上。容器通过 SSH agent 转发重用它们——私钥永远不会进入容器。

---

## 4. 两种模式中的共享库

### 在单体存储库中

本地包通过工作空间工具自动链接：

```
# Application references local library as a normal dependency
{
  "dependencies": {
    "@company/shared-types": "*"    // Resolved to libs/shared-types
  }
}
```

在根目录运行 `npm install` 会将库符号链接到每个应用的 `node_modules` 中。

### 在多存储库中

共享代码必须发布到仓库、进行 vendoring 或通过共享契约暴露：

- **选项 A**：作为私有包发布到 npm/PyPI
- **选项 B**：使用 Git 子模块（由于复杂性通常不推荐）
- **选项 C**：定义 API 契约（OpenAPI、gRPC、GraphQL 模式）并为每个服务生成客户端代码
- **选项 D**：通过同步脚本从平台存储库复制共享类型/模板

---

## 5. 目录结构示例

### 单体存储库布局

```
company-monorepo/
├── apps/
│   ├── api-gateway/
│   │   ├── Dockerfile
│   │   ├── package.json              # @company/api-gateway
│   │   └── src/
│   ├── web-app/
│   │   ├── Dockerfile
│   │   └── package.json              # @company/web-app
│   └── ai-service/
│       ├── Dockerfile
│       └── requirements.txt
│
├── libs/
│   ├── shared-types/
│   │   ├── package.json              # @company/shared-types
│   │   └── src/index.ts
│   └── logger/
│       └── package.json
│
├── infra/
│   ├── compose.yaml
│   ├── compose.dev.yaml
│   └── env/
│
├── .devcontainer/
│   ├── gateway/devcontainer.json
│   └── web/devcontainer.json
│
├── package.json                      # Root: defines workspaces
└── .github/workflows/
```

### 多存储库布局

```
workspace/
├── platform-dev/                     # Infrastructure repo
│   ├── compose.yaml
│   ├── compose.dev.yaml
│   ├── env/
│   ├── .devcontainer/
│   ├── docker/
│   ├── scripts/
│   └── docs/
│
├── api-gateway/                      # Service repo 1
├── web-app/                          # Service repo 2
├── order-worker/                     # Service repo 3
└── ai-service/                       # Service repo 4
```

---

## 6. 决策指南

| 因素 | 单体存储库 | 多存储库 |
|--------|----------|----------|
| 团队规模 | 小型至中型（< 30 名开发者） | 中型至大型 |
| 发布节奏 | 协调发布 | 每个服务独立发布 |
| 共享代码 | 大量跨服务共享 | 最小化共享，优先使用 API 契约 |
| CI/CD 复杂度 | 需要路径过滤 + 构建工具 | 每个仓库流水线更简单 |
| 新成员入职 | 单一克隆 | 多个克隆 + 平台仓库 |
| 所有权 | 可能模糊 | 每个仓库所有权清晰 |
| 语言多样性 | 工作空间工具支持良好 | 每个仓库选择自己的技术栈 |
| 访问控制 | 全有或全无 | 每个仓库精细化控制 |

### 选择单体存储库如果：
- 你的团队跨技术栈高度协作（如全栈开发者在同一个 sprint 中涉及数据库、API 和前端）
- 你在维护内部包或共享依赖时遇到"版本地狱"
- 你依赖跨前端和后端的共享语言生态系统，并希望获得端到端类型安全

### 选择多存储库（带中心平台仓库）如果：
- 你的团队严格专业化（前端团队从不接触计算密集型服务代码）
- 你的某个仓库非常庞大（包含大型模型或重型二进制文件）会拖慢其他开发者的 Git 体验
- 你希望 CI/CD 流水线尽可能简单，无需学习额外工具
- 你需要对每个服务进行精细的访问控制

### 混合方法

将共享相同语言生态系统的服务分组到**单体存储库**中（如前端 + API 网关 + 工作进程），并将具有重型构建上下文的计算密集型服务作为独立的**多存储库**组件保留。无论选择哪种模式，基础设施模式（Compose、Dev Container、环境管理）都保持相似。

---

*下一步：[第二部分：基础设施设置](02-infrastructure-setup.zh-CN.md) — Docker Compose、环境变量和服务网络。*
