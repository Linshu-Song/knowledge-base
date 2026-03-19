# Part 3: Development Environment

## Language Selection

- **English** (Current) - This document
- [简体中文](03-development-environment.zh-CN.md) - Simplified Chinese
- [繁體中文](03-development-environment.zh-HK.md) - Traditional Chinese

## Table of Contents

1. [What is a Dev Container?](#1-what-is-a-dev-container)
2. [Dev Container vs. Local Development](#2-dev-container-vs-local-development)
3. [Dev Container vs. Docker Compose Alone](#3-dev-container-vs-docker-compose-alone)
4. [When to Use Dev Containers](#4-when-to-use-dev-containers)
5. [When NOT to Use Dev Containers](#5-when-not-to-use-dev-containers)
6. [Decision Matrix](#6-decision-matrix)
7. [Dev Container Configuration](#7-dev-container-configuration)
8. [devcontainer.json Property Reference](#8-devcontainerjson-property-reference)
9. [SSH Agent Forwarding](#9-ssh-agent-forwarding)
10. [Git Configuration](#10-git-configuration)
11. [First-Time Setup](#11-first-time-setup)
12. [Daily Workflow](#12-daily-workflow)
13. [Common Issues](#13-common-issues)

---

## 1. What is a Dev Container?

A **Dev Container** is a standardized way to define a complete development environment inside a Docker container. It's primarily a **VS Code feature** (though other IDEs like JetBrains are catching up).

### Core Concept

Instead of:
- Installing Node.js, Python, PostgreSQL client, Redis CLI, etc. on your local machine
- Dealing with version conflicts (macOS has Python 3.9, you need 3.11)
- Having different setups across team members

You get:
- **One `devcontainer.json` file** that specifies: OS, runtime versions, extensions, ports to forward, volumes to mount
- **Reproducible environment** across all developers and CI/CD
- **Isolation** from your host machine's global state

### Under the Hood

When you open a folder in VS Code with a `devcontainer.json`:
1. The Dev Containers extension reads the `devcontainer.json` file
2. It spins up a Docker container (or uses Docker Compose)
3. It installs the **VS Code Server** inside the container
4. VS Code's UI stays on your host, but the terminal, file explorer, and debugger all run **inside** the container
5. Ports are forwarded so `localhost:3000` on your host reaches the container

---

## 2. Dev Container vs. Local Development

### Local Development (Traditional)

```
# Setup
brew install node@20
brew install python@3.11
git clone <repo>
cd repo
npm install
npm run dev
```

| Pros | Cons |
|------|------|
| Instant feedback loop (no container overhead) | Environment drift: Developer A has Node 18, B has Node 20 |
| Direct access to IDEs, Git, SSH keys | "Works on my machine" — OS-specific differences |
| Easy to debug with native debuggers | Global state pollution across projects |
| | Onboarding pain: 20-step install guide |
| | Machine bloat: every runtime accumulates |

### Dev Container Approach

```
# Setup
git clone <repo>
# VS Code: Cmd+Shift+P → "Dev Containers: Reopen in Container"
# Wait 30 seconds. Done.
```

| Pros | Cons |
|------|------|
| Reproducibility: same Dockerfile = same environment everywhere | Docker overhead: 10-30s startup (one-time per session) |
| Isolation: host machine stays clean | File I/O lag on macOS bind mounts (mitigated with modern Docker) |
| Easy onboarding: clone → select container → done | Resource usage: Docker Desktop uses 2-4 GB RAM |
| No version conflicts per project | Learning curve: teams must understand Docker basics |

---

## 3. Dev Container vs. Docker Compose Alone

### Docker Compose Alone

You define infrastructure in `compose.yaml` and run your app locally:

```bash
docker compose up -d        # Database, cache, queue running in containers
npm run dev                  # Your local Node.js connects to containerized PostgreSQL
```

**Pros**: Simple setup, fast local feedback, familiar loop.

**Cons**: Runtime consistency issue (your local Node version may differ from prod), debugging complexity across local + containerized processes, SSH/credentials must be passed manually.

### Dev Container + Docker Compose

Both infrastructure **and** your app run in containers:

```json
{
  "dockerComposeFile": ["compose.yaml", "compose.dev.yaml"],
  "service": "gateway",
  "workspaceFolder": "/workspace/api-gateway"
}
```

- `postgres`, `rabbitmq`, `redis` run as separate containers
- **Your app code also runs inside a container**, matching your Dockerfile
- VS Code connects to the app container
- The app container reaches database services by hostname (Docker DNS)

**Pros**: True environment parity (local dev ≈ production), automatic service discovery, credential security via SSH agent forwarding.

**Cons**: More complex initial setup, developers must understand Docker Compose + Dev Containers together.

---

## 4. When to Use Dev Containers

**Team Using Multiple Operating Systems**
Some developers on macOS, others on Linux, others on Windows (WSL2). Dev Containers abstract away OS differences — everyone develops in the same Linux container.

**Complex Infrastructure Dependencies**
Your app requires PostgreSQL, Redis, RabbitMQ, etc. Developers shouldn't install all of this locally. New team members should be productive in 5 minutes.

**Polyrepo with Shared Platform Infrastructure**
Multiple services share common infra. Each has different runtime requirements (Node.js vs. Python). Developers often switch between services.

**Monorepo with Shared Libraries**
`libs/shared-types` is used by both `apps/api-gateway` and `apps/web-app`. When you change the library, both apps see changes instantly via workspace symlinks.

**Mixed-Language Stack**
Core services are Node.js, AI inference is Python + CUDA. Separate Dev Containers for each stack, shared Compose infra.

---

## 5. When NOT to Use Dev Containers

**Performance-Critical Development**
Real-time graphics, game development, or build loops where 100ms latency matters. Docker adds I/O overhead, especially on macOS.

**Solo Developer, Single Machine**
No team consistency to gain. Use Docker Compose for dependencies, run your app locally.

**Simple Frontend-Only Project**
Vanilla JavaScript or simple React app with no backend. Docker overhead doesn't justify the simplicity.

**Incompatible Tooling**
Team uses IDEs that don't support Dev Containers (older JetBrains, Sublime, Emacs) or corporate policy forbids Docker.

**Rapid Experimentation / Throwaway Code**
Exploring a new library with code that will be deleted. Just `npm install` and go.

---

## 6. Decision Matrix

| Factor | Yes to Dev Containers | No to Dev Containers |
|--------|----------------------|---------------------|
| Team size | 3+ developers | 1-2 developers |
| Operating systems | Mixed (macOS, Linux, Windows) | Single OS |
| Infrastructure complexity | 3+ services (DB, Cache, Queue) | Local-only, simple |
| Language diversity | Python + Node.js + C++ | Single language |
| Code sharing | Monorepo with `libs/` | Isolated services |
| IDE usage | VS Code primary | Other IDEs |
| Performance critical | No | Yes |
| Onboarding frequency | Frequent (growing team) | Rare |
| Production parity | High (dev ≈ prod) | Low (dev ≠ prod) |

**Scoring:**
- **5+ "Yes"** → Strongly recommend Dev Containers
- **3-4 "Yes"** → Consider Dev Containers, weigh trade-offs
- **1-2 "Yes"** → Skip Dev Containers, use Docker Compose alone
- **0 "Yes"** → Local development only

---

## 7. Dev Container Configuration

### Monorepo: `.devcontainer/gateway/devcontainer.json`

```json
{
  "name": "API Gateway (Monorepo)",
  "dockerComposeFile": [
    "../../infra/compose.yaml",
    "../../infra/compose.dev.yaml"
  ],
  "service": "gateway",
  "workspaceFolder": "/workspace/apps/api-gateway",
  "remoteUser": "vscode",
  "updateRemoteUserUID": true,
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "eamodio.gitlens"
      ],
      "settings": {
        "editor.formatOnSave": true
      }
    }
  },
  "features": {
    "ghcr.io/devcontainers/features/git:1": {}
  },
  "runServices": ["gateway", "database", "message-queue"],
  "forwardPorts": [3000],
  "portsAttributes": {
    "3000": { "label": "API Gateway", "onAutoForward": "notify" }
  },
  "postCreateCommand": "cd /workspace && npm install"
}
```

### Polyrepo: `platform-dev/.devcontainer/gateway/devcontainer.json`

```json
{
  "name": "API Gateway Dev",
  "dockerComposeFile": [
    "../../compose.yaml",
    "../../compose.dev.yaml"
  ],
  "service": "gateway",
  "workspaceFolder": "/workspace/api-gateway",
  "remoteUser": "vscode",
  "updateRemoteUserUID": true,
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "eamodio.gitlens"
      ],
      "settings": {
        "editor.formatOnSave": true
      }
    }
  },
  "features": {
    "ghcr.io/devcontainers/features/git:1": {}
  },
  "runServices": ["gateway", "database", "message-queue", "cache"],
  "forwardPorts": [3000],
  "portsAttributes": {
    "3000": { "label": "API Gateway", "onAutoForward": "notify" }
  },
  "postCreateCommand": "npm ci && npm run db:migrate"
}
```

### GPU-Enabled Service (e.g., AI Inference)

```json
{
  "name": "AI Service Dev",
  "dockerComposeFile": [
    "../../compose.yaml",
    "../../compose.dev.yaml"
  ],
  "service": "ai-service",
  "workspaceFolder": "/workspace/ai-service",
  "remoteUser": "vscode",
  "updateRemoteUserUID": true,
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  },
  "runServices": ["ai-service", "message-queue", "cache"],
  "forwardPorts": [8001],
  "runArgs": [
    "--gpus=all",
    "--cap-add=SYS_PTRACE"
  ],
  "postCreateCommand": "pip install -r requirements.txt",
  "remoteEnv": {
    "CUDA_VISIBLE_DEVICES": "0"
  }
}
```

## 8. devcontainer.json Property Reference

| Property | Purpose | Example |
|----------|---------|---------|
| `name` | Display name in VS Code picker | `"API Gateway Dev"` |
| `image` | Standalone Docker image (don't combine with `dockerComposeFile`) | `"node:20-alpine"` |
| `dockerComposeFile` | Array of compose YAML files | `["compose.yaml", "compose.dev.yaml"]` |
| `service` | Which service in compose.yaml to attach to | `"gateway"` |
| `workspaceFolder` | Where VS Code terminal opens | `"/workspace/api-gateway"` |
| `remoteUser` | Username inside container (non-root recommended) | `"vscode"` |
| `updateRemoteUserUID` | Sync host UID to container user (prevents permission issues) | `true` |
| `runServices` | Which services to start | `["gateway", "database", "redis"]` |
| `forwardPorts` | Expose container ports to host | `[3000, 8001]` |
| `runArgs` | Extra Docker run arguments | `["--gpus=all"]` |
| `customizations.vscode.extensions` | VS Code extensions to auto-install | `["ms-python.python"]` |
| `customizations.vscode.settings` | VS Code settings (per-container) | `{"editor.formatOnSave": true}` |
| `features` | Automated setup helpers | `"ghcr.io/devcontainers/features/git:1"` |
| `postCreateCommand` | Run after container initialization | `"npm install"` |
| `remoteEnv` | Environment variables inside container | `{"NODE_ENV": "development"}` |
| `mounts` | Docker bind mounts (SSH agent, etc.) | `"source=~/.ssh,target=/root/.ssh,type=bind,readonly"` |

---

## 9. SSH Agent Forwarding

Git authentication inside containers uses the host's SSH agent. **Private keys never enter the container.**

### How It Works

```
Host Machine                          Container
┌─────────────────┐                  ┌─────────────────┐
│ SSH Agent        │                  │ Git              │
│ (~/.ssh/id_*)   │── socket ──────→ │ calls SSH        │
│                  │   forwarded      │ SSH connects to  │
│ Private keys     │   via Docker     │ forwarded socket │
│ stay HERE        │   volume mount   │ signs operation  │
└─────────────────┘                  └─────────────────┘
```

1. Host runs SSH agent, holding private keys in memory
2. `SSH_AUTH_SOCK` environment variable points to the agent's socket
3. Dev Containers extension forwards this socket into the container
4. Git inside the container calls SSH, which connects to the forwarded socket
5. Private key never leaves the host

### One-Time Host Setup

#### macOS

```bash
# SSH agent typically runs by default
ssh-add -l

# If no keys listed, add your key:
ssh-add ~/.ssh/id_ed25519
```

#### Linux

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add your key
ssh-add ~/.ssh/id_ed25519

# Make persistent (add to ~/.bashrc):
echo 'eval "$(ssh-agent -s)" 2>/dev/null' >> ~/.bashrc
```

#### Windows (WSL2)

```bash
# Inside WSL2 terminal
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### Verify in Container

Once connected to a Dev Container, verify SSH forwarding works:

```bash
# Inside container terminal
echo $SSH_AUTH_SOCK
# Should output: /run/host-services/ssh-auth.sock

ssh-add -l
# Should list your host keys

ssh -T git@github.com
# Should authenticate successfully
```

---

## 10. Git Configuration

Git config is inherited from the host. Configure it once on the host machine.

### One-Time Host Setup

```bash
# Set identity
git config --global user.name "Your Full Name"
git config --global user.email "your.email@company.com"

# Line endings
# macOS/Linux:
git config --global core.autocrlf input
git config --global core.fileMode true

# Windows:
git config --global core.autocrlf true
git config --global core.fileMode false

# Allow all directories (needed for bind-mounted container repos)
git config --global --add safe.directory '*'
```

### Handling Multiple Git Accounts

```bash
# ~/.ssh/config on host
Host github.com-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_work
    IdentitiesOnly yes

Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_personal
    IdentitiesOnly yes
```

Then clone using aliases:

```bash
git clone git@github.com-work:work-org/repo.git
git clone git@github.com-personal:personal-user/repo.git
```

### HTTPS Alternative

If you prefer HTTPS over SSH:

```bash
# Configure credential helper
git config --global credential.helper osxkeychain   # macOS
git config --global credential.helper pass          # Linux
# Windows: usually built-in with Git for Windows
```

---

## 11. First-Time Setup

### Step-by-Step (Polyrepo Example)

```bash
# 1. Configure SSH agent on host
ssh-add ~/.ssh/id_ed25519

# 2. Configure Git on host
git config --global user.name "Your Name"
git config --global user.email "you@company.com"
git config --global --add safe.directory '*'

# 3. Verify SSH connectivity
ssh -T git@github.com

# 4. Clone repositories
mkdir -p ~/workspace && cd ~/workspace
git clone git@github.com:company/platform-dev.git
git clone git@github.com:company/api-gateway.git
git clone git@github.com:company/web-app.git

# 5. Start infrastructure
cd platform-dev
docker compose \
  --env-file ./env/compose.dev.env \
  -f compose.yaml \
  -f compose.dev.yaml \
  --profile dev \
  up -d database message-queue cache

# 6. Verify services are healthy
docker compose ps

# 7. Open in VS Code
code .

# 8. Cmd+Shift+P → "Dev Containers: Reopen in Container"
# 9. Select service (e.g., "API Gateway Dev")
# 10. Wait for container to build (~2-3 min)

# 11. Inside container, verify Git works
git config user.name
ssh -T git@github.com

# 12. Test push
cd /workspace/api-gateway
git checkout -b test-ssh-push
git commit --allow-empty -m "Test push from container"
git push -u origin test-ssh-push
git checkout main
git branch -D test-ssh-push
git push origin :test-ssh-push
```

### Monorepo Difference

For monorepo, steps 4-5 simplify:

```bash
# Single clone
git clone git@github.com:company/monorepo.git
cd monorepo

# npm install at root links all workspaces
npm install

# Start infrastructure
docker compose -f infra/compose.yaml -f infra/compose.dev.yaml up -d
```

---

## 12. Daily Workflow

### Starting Work

```bash
# On host
cd ~/workspace/platform-dev    # or monorepo root

# Start all services
docker compose \
  --env-file ./env/compose.dev.env \
  -f compose.yaml \
  -f compose.dev.yaml \
  --profile dev \
  up -d

# Verify health
docker compose ps
```

### Working on Code

1. Open VS Code connected to the relevant Dev Container
2. Edit code — changes are reflected instantly via bind mounts
3. Hot reload picks up changes automatically (nodemon, webpack-dev-server, uvicorn --reload, etc.)

### Committing Changes

Git operations work naturally from inside the container:

```bash
# Inside VS Code terminal (container)
git status
git add src/handler.ts
git commit -m "Add new request handler"
git push origin feature-branch
# No password prompts — SSH agent handles auth
```

### Cross-Service Calls

Inside any container, call other services by Docker DNS name:

```javascript
// From api container, call ai-service
const response = await fetch('http://ai-service:8001/api/infer', {
  method: 'POST',
  body: JSON.stringify({ input: '...' })
});
```

```python
# From ai-service container, call api
import requests
response = requests.get('http://api:3000/api/users')
```

From the host browser, use `localhost` with the mapped port:

```
http://localhost:3000    # API
http://localhost:3001    # Frontend
http://localhost:8080    # Adminer (DB UI)
http://localhost:15672   # Queue management UI
```

### Inspecting Logs

```bash
# On host
docker compose logs -f api              # Follow API logs
docker compose logs --tail=100 ai-service  # Last 100 lines
docker compose logs | grep -i error     # Search for errors
```

### Database Access

```bash
# Option 1: Web UI (Adminer)
# Open http://localhost:8080 in browser

# Option 2: CLI inside container
docker compose exec database psql -U devuser -d platform_db

# Option 3: From application code
# Most apps read DATABASE_URL from environment automatically
```

### Message Queue Inspection

```bash
# Management UI: http://localhost:15672 (guest/guest)

# Or CLI
docker compose exec message-queue rabbitmqctl list_queues
```

### Restarting After Env Changes

```bash
# Recreate specific service
docker compose up -d --force-recreate api

# Or full restart
docker compose down && docker compose up -d
```

---

## 13. Common Issues

### "SSH_AUTH_SOCK not set" or SSH key not available

**Cause**: SSH agent not running on host, or socket not forwarded.

**Fix**:

```bash
# On host
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Restart containers
docker compose down && docker compose up -d
```

### "fatal: detected dubious ownership in repository"

**Cause**: Container user UID differs from repo file UID.

**Fix**:

```bash
# Option 1: Already set globally, but can be explicit
git config --global --add safe.directory '/workspace/api-gateway'

# Option 2: Ensure devcontainer.json has:
# "updateRemoteUserUID": true

# Option 3: Restart container
docker compose down && docker compose up -d
```

### "Permission denied (publickey)" when pushing

**Cause**: SSH agent not forwarded, or wrong key permissions.

**Fix**:

```bash
# On host — check key permissions
ls -la ~/.ssh/id_ed25519
# Should be: -rw------- (600)

chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Verify agent has the key
ssh-add -l
ssh-add ~/.ssh/id_ed25519  # If not listed

# Test from host
ssh -T git@github.com
```

### "Could not resolve host github.com"

**Cause**: DNS not working in container.

**Fix**:

```bash
# Restart containers (usually fixes transient DNS issues)
docker compose restart

# Or add DNS to compose.yaml:
# services:
#   api:
#     dns: [8.8.8.8, 1.1.1.1]
```

---

*Previous: [Part 2: Infrastructure Setup](02-infrastructure-setup.md)*
*Next: [Part 4: Production Deployment](04-production-deployment.md) — Image building, secrets management, migrations, and CI/CD.*
