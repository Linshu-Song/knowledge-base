# Part 1: Repository Architecture Overview

## Language Selection

- **English** (Current) - This document
- [简体中文](01-architecture-overview.zh-CN.md) - Simplified Chinese
- [繁體中文](01-architecture-overview.zh-HK.md) - Traditional Chinese

## Table of Contents

1. [Monorepo vs Polyrepo](#1-monorepo-vs-polyrepo)
2. [Monorepo: Key Concepts](#2-monorepo-key-concepts)
3. [Polyrepo: Key Concepts](#3-polyrepo-key-concepts)
4. [Shared Libraries in Both Models](#4-shared-libraries-in-both-models)
5. [Directory Structure Examples](#5-directory-structure-examples)
6. [Decision Guide](#6-decision-guide)

---

## 1. Monorepo vs Polyrepo

Two primary repository strategies exist for multi-service platforms. Neither is universally superior; the right choice depends on team size, release cadence, and organizational structure.

### Feature-by-Feature Comparison

| Dimension | Monorepo | Polyrepo |
|-----------|----------|----------|
| **Code Sharing** | Excellent. Native imports across apps. A shared library can be consumed directly by frontend and API. | Complex. Requires publishing to a private registry or using Git submodules. |
| **Atomic Changes** | Yes. A single PR can change the API contract, backend implementation, and frontend consumer. | No. Requires multiple PRs across repositories and careful coordination. |
| **Onboarding** | Simple. `git clone` once. All code, infra, and docs immediately available. | Moderate. Requires cloning a platform repo plus multiple service repos. |
| **CI/CD Complexity** | High. Pipelines must use path-filtering or tools like Nx/Turborepo. | Low. Standard pipelines — if a repo is pushed, build and deploy that repo. |
| **Git Clone Size** | Larger. Contains all history for all services. | Smaller. Developers only pull what they work on. |
| **Language Mixing** | Moderate. Mixing ecosystems (e.g., different dependency managers) requires discipline. | Easy. Each repo is purely dedicated to its own language ecosystem. |
| **Access Control** | All-or-nothing. Usually everyone has read access to the whole codebase. | Granular. Easy to restrict access to specific services. |

### Monorepo

All services, applications, and shared libraries live in a **single Git repository**.

**Advantages:**
- Atomic cross-service changes (one commit touches both API and frontend)
- Shared code via local references — no publishing to a package registry
- Unified CI/CD pipeline with path-based filtering
- Single clone, single branch strategy
- IDE and compiler surface errors across all consumers when a shared interface changes

**Trade-offs:**
- Repository grows large over time
- CI must use path filtering to avoid rebuilding everything
- Requires tooling (e.g., Nx, Turborepo, Bazel) as complexity grows
- Blurred ownership boundaries if team is large

### Polyrepo

Each service has its own **independent Git repository**. A central "platform" repository manages shared infrastructure (Compose files, Dev Containers, environment configs).

**Advantages:**
- Independent CI/CD, versioning, and release cadence per service
- Clear team ownership boundaries
- Smaller, focused repositories
- No monorepo tooling overhead
- Natural boundary enforcement — developers can't accidentally couple services

**Trade-offs:**
- Cross-service changes require coordinating multiple PRs
- Shared code must be published to a registry (npm, PyPI, etc.) or vendored
- Onboarding requires cloning multiple repos
- Keeping infrastructure config in sync is manual (mitigated by central platform repo)

---

### Deep Dive: The Monorepo Advantage

#### The "Shared Contract" Pattern

In a multi-service platform, the backend API, frontend, and background workers often share **data transfer objects (DTOs)**, validation schemas, and event payloads.

**In a Polyrepo**, adding a new field to a message payload:
1. Update the shared-contracts repo → publish a new version
2. Update the API gateway repo → install the new version → deploy
3. Update the worker repo → install the new version → deploy

**In a Monorepo**:
1. Update the shared contract file, update the gateway and the worker in the **same branch**
2. Run tests. Merge one PR. Both services deploy together.

#### Refactoring Confidence

When you change a core utility or API interface in a monorepo, your IDE and compiler immediately surface errors in *every* application that consumes it. In a polyrepo, you might not discover the breakage until CI runs on the downstream repo — hours or days later.

---

### Deep Dive: The Polyrepo Advantage

#### Boundary Enforcement

Polyrepos naturally prevent "spaghetti code". In a monorepo, a developer might directly import a database model from one service into another. A polyrepo makes this impossible, forcing communication over actual network boundaries (APIs, message queues, etc.).

#### Build Isolation

If one team maintains heavy, compute-intensive builds with a completely different toolchain, they don't have to navigate through unrelated configurations. Their CI/CD pipeline remains focused and self-contained.

---

## 2. Monorepo: Key Concepts

### Workspaces

Most language ecosystems support workspace linking:

```
# Node.js (npm/yarn/pnpm)
"workspaces": ["apps/*", "libs/*"]

# Python (poetry/uv)
# Use path dependencies in pyproject.toml

# Go
# Use Go modules with replace directives
```

### Path-Based CI/CD

Only rebuild and redeploy services affected by a change:

```yaml
# Example: trigger deploy only when specific paths change
on:
  push:
    paths:
      - 'apps/api-gateway/**'
      - 'libs/shared-types/**'   # Shared dependency changes trigger rebuild
```

### Build Tooling

As the monorepo grows, dependency-aware build tools become essential:

- **Turborepo** / **Nx**: Compute the dependency graph, build only what changed
- **Bazel** / **Pants**: Language-agnostic, hermetic builds for large-scale systems

```bash
# Turborepo: build only services affected since 'main'
npx turbo run build --filter=...[origin/main]
```

---

## 3. Polyrepo: Key Concepts

### Central Platform Repository

A dedicated repository (e.g., `platform-dev`) holds all shared infrastructure:

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

### Service Repositories

Each service is standalone:

```
api-gateway/                   # Independent Git repo
├── Dockerfile                 # Inherits from platform-dev base images
├── src/
├── tests/
└── package.json
```

### Git Credential Management

Git credentials (SSH keys, tokens) stay on the host machine. Containers reuse them via SSH agent forwarding — private keys never enter the container.

---

## 4. Shared Libraries in Both Models

### In a Monorepo

Local packages are linked automatically via workspace tooling:

```
# Application references local library as a normal dependency
{
  "dependencies": {
    "@company/shared-types": "*"    // Resolved to libs/shared-types
  }
}
```

Running `npm install` at the root symlinks the library into each app's `node_modules`.

### In a Polyrepo

Shared code must be published to a registry, vendored, or exposed via a shared contract:

- **Option A**: Publish to npm/PyPI as a private package
- **Option B**: Use Git submodules (generally discouraged due to complexity)
- **Option C**: Define API contracts (OpenAPI, gRPC, GraphQL schemas) and generate client code per service
- **Option D**: Copy shared types/templates via a sync script from the platform repo

---

## 5. Directory Structure Examples

### Monorepo Layout

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

### Polyrepo Layout

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

## 6. Decision Guide

| Factor | Monorepo | Polyrepo |
|--------|----------|----------|
| Team size | Small–Medium (< 30 devs) | Medium–Large |
| Release cadence | Coordinated releases | Independent per service |
| Shared code | Heavy cross-service sharing | Minimal sharing, API contracts preferred |
| CI/CD complexity | Needs path filtering + build tools | Simpler per-repo pipelines |
| Onboarding | Single clone | Multiple clones + platform repo |
| Ownership | Can be ambiguous | Clear per-repo ownership |
| Language diversity | Works well with workspace tooling | Each repo chooses its own stack |
| Access control | All-or-nothing | Granular per-repo |

### Choose Monorepo if:
- Your teams work highly collaboratively across the stack (e.g., full-stack developers touching the database, API, and frontend in the same sprint)
- You suffer from "version hell" maintaining internal packages or shared dependencies
- You rely on a shared language ecosystem across frontend and backend and want end-to-end type safety

### Choose Polyrepo (with a central platform repo) if:
- Your teams are strictly specialized (frontend team never touches compute-intensive service code)
- One of your repos is massive (containing large models or heavy binaries) and would slow down other developers' Git experience
- You want the simplest possible CI/CD pipelines without learning extra tooling
- You need granular access control per service

### Hybrid Approach

Group services that share the same language ecosystem in a **monorepo** (e.g., frontend + API gateway + workers), and keep compute-intensive services with heavy build contexts as separate **polyrepo** components. The infrastructure patterns (Compose, Dev Containers, env management) remain similar regardless of which model you choose.

---

*Next: [Part 2: Infrastructure Setup](02-infrastructure-setup.md) — Docker Compose, environment variables, and service networking.*
