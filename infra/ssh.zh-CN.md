# SSH 与 SSH Key 指南

## 语言选择

- [English](ssh.md) - 英文
- **简体中文** (当前) - 本文档
- [繁體中文](ssh.zh-HK.md) - 繁体中文

---

## 1. 什么是 SSH？SSH Key 的原理是什么？

**SSH（Secure Shell，安全外壳协议）** 是一种加密网络协议，用于在不安全的网络安全地操作远程服务。最常见的用途是远程登录服务器和安全执行命令。

### SSH Key 原理（非对称加密）

SSH Key 认证使用**公钥加密**密钥对：

| 密钥 | 存放位置 | 可见性 |
|---|---|---|
| **私钥（Private Key）** | 保存在本地机器（`~/.ssh/id_ed25519`） | **绝不能泄露** |
| **公钥（Public Key）** | 放在远程服务器或 GitHub 上（`~/.ssh/id_ed25519.pub`） | **可以公开** |

**工作流程：**

1. 服务器保存你的公钥。
2. 连接时，服务器发送一个随机挑战（challenge）。
3. 本地机器用私钥对挑战进行签名。
4. 服务器用保存的公钥验证签名。
5. 验证通过即完成认证——无需输入密码。

> 私钥永远不会离开你的机器，因此比密码认证安全得多。

---

## 2. 生成并配置 SSH Key

### 第一步：生成新的 SSH Key

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

- `-t ed25519` — 使用 Ed25519 算法（推荐，比 RSA 更快更安全）。
- `-C` — 标签/注释，一般填写你的邮箱。

提示输入文件路径时，按 Enter 使用默认路径（`~/.ssh/id_ed25519`），然后可选设置密码短语（passphrase）。

生成后得到两个文件：

```
~/.ssh/id_ed25519       # 私钥 — 保密
~/.ssh/id_ed25519.pub   # 公钥 — 可以分享给服务器/GitHub
```

### 第二步：将 Key 添加到 SSH Agent

```bash
# 启动 ssh-agent（如未运行）
eval "$(ssh-agent -s)"
# 输出示例：Agent pid 12345

# 添加私钥
ssh-add ~/.ssh/id_ed25519
```

### 第三步：将公钥添加到 GitHub

1. 复制公钥内容：

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

2. 打开 **GitHub → Settings → SSH and GPG keys → New SSH key**。
3. 粘贴公钥，填写描述性标题（如 "工作笔记本"）。
4. 点击 **Add SSH key**。

### 第四步：测试连接

```bash
ssh -T git@github.com
```

期望输出：

```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

> 如果提示主机真实性确认，输入 `yes` 将 GitHub 添加到 `~/.ssh/known_hosts`。

---

## 3. SSH Agent：是什么、为什么用、怎么用

### 什么是 SSH Agent？

`ssh-agent` 是一个后台程序，将你**解密后的私钥保存在内存中**。加载后，每次使用密钥时无需重复输入密码短语。

### 为什么使用它？

- **方便** — 每个会话只需输入一次密码短语，而非每次都输入。
- **安全** — 私钥保存在 agent 内存中，不会以未加密形式写入磁盘。
- **支持 agent 转发**（见第 4 节）。

### 如何启用

```bash
# 启动 agent
eval "$(ssh-agent -s)"

# 添加密钥（如有密码短语会提示输入）
ssh-add ~/.ssh/id_ed25519

# 验证已加载的密钥
ssh-add -l
```

### 常用命令

| 命令 | 说明 |
|---|---|
| `ssh-add -l` | 列出所有已加载的密钥 |
| `ssh-add -D` | 从 agent 中移除所有密钥 |
| `ssh-add -d ~/.ssh/id_ed25519` | 移除指定密钥 |

> **提示：** 在 macOS 和许多 Linux 桌面环境中，`ssh-agent` 会自动启动。在服务器上，可将 `eval "$(ssh-agent -s)"` 添加到 `~/.bashrc` 或 `~/.zshrc`。

---

## 4. SSH Agent 转发（Agent Forwarding）

### 什么是 Agent 转发？

SSH Agent 转发允许你**在远程服务器或 Docker 容器中使用本地的 SSH 密钥**——无需将私钥复制到远程机器。远程机器将认证请求转发回你的本地 agent。

### 为什么使用它？

- 在远程服务器上使用本地 GitHub Key 克隆私有仓库。
- 从远程服务器跳转到另一台服务器时使用本地密钥。
- **永远不需要把私钥复制到远程机器上**。

### 如何启用

#### 方式 A：命令行

```bash
ssh -A user@remote-server
```

`-A` 参数为该会话启用 agent 转发。

#### 方式 B：SSH 配置文件（`~/.ssh/config`）

```
Host remote-server
    HostName 192.168.1.100
    User deploy
    ForwardAgent yes
```

之后直接 `ssh remote-server`，转发自动生效。

### 在远程服务器上使用 Agent 转发

使用 `-A` 连接后，本地密钥在远程服务器上可用：

```bash
# 在远程服务器上 — 使用的是你本地的密钥
ssh -T git@github.com
# 输出：Hi your-username! You've successfully authenticated...
```

现在可以在远程服务器上执行 `git clone`、`git push` 等操作，使用本地凭据。

### 在 Docker 中使用 Agent 转发

#### 方法 1：挂载 SSH Agent Socket

```bash
docker run -it \
  -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK \
  -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK \
  ubuntu bash
```

在容器内：

```bash
apt update && apt install -y openssh-client git
ssh -T git@github.com
# 成功！使用的是宿主机上已加载的密钥。
```

#### 方法 2：Docker Compose

```yaml
services:
  app:
    build: .
    environment:
      - SSH_AUTH_SOCK=${SSH_AUTH_SOCK}
    volumes:
      - ${SSH_AUTH_SOCK}:${SSH_AUTH_SOCK}
```

#### 方法 3：Dockerfile + BuildKit（构建时 `git clone`）

```dockerfile
# syntax=docker/dockerfile:1
FROM ubuntu
RUN apt-get update && apt-get install -y openssh-client git
RUN --mount=type=ssh git clone git@github.com:your-org/private-repo.git
```

构建命令：

```bash
DOCKER_BUILDKIT=1 docker build --ssh default .
```

### 安全警告

> **Agent 转发存在安全风险。** 如果远程服务器被入侵且攻击者拥有 root 权限，可能利用你转发的 agent 以你的身份认证其他服务。请仅在信任的服务器上使用。对于多跳 SSH，可考虑使用更安全的替代方案 `ProxyJump`。

---

## 速查表

| 操作 | 命令 |
|---|---|
| 生成密钥 | `ssh-keygen -t ed25519 -C "email"` |
| 启动 agent | `eval "$(ssh-agent -s)"` |
| 添加密钥到 agent | `ssh-add ~/.ssh/id_ed25519` |
| 测试 GitHub 连接 | `ssh -T git@github.com` |
| 带转发的 SSH | `ssh -A user@host` |
| Docker 使用 agent | `docker run -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK ...` |

---

*最后更新：2026 年 3 月*
