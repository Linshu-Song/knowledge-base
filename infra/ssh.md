# SSH & SSH Key Guide

## Language Selection

- **English** (Current) - This document
- [简体中文](ssh.zh-CN.md) - Simplified Chinese
- [繁體中文](ssh.zh-HK.md) - Traditional Chinese

---

## 1. What Is SSH and How Do SSH Keys Work?

**SSH (Secure Shell)** is a cryptographic network protocol for securely operating network services over an unsecured network. Its primary use is remote login to servers and executing commands securely.

### SSH Key Principle (Asymmetric Cryptography)

SSH key authentication uses a **public-key cryptography** pair:

| Key | Location | Visibility |
|---|---|---|
| **Private Key** | Stored on your local machine (`~/.ssh/id_ed25519`) | **Never share** |
| **Public Key** | Placed on remote servers / GitHub (`~/.ssh/id_ed25519.pub`) | **Safe to share** |

**How it works:**

1. The server stores your public key.
2. When you connect, the server sends a random challenge.
3. Your local machine signs the challenge with your private key.
4. The server verifies the signature using the stored public key.
5. If verified, you are authenticated — no password needed.

> The private key never leaves your machine. This makes it far more secure than password authentication.

---

## 2. Generate and Configure SSH Key

### Step 1: Generate a New SSH Key

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

- `-t ed25519` — use the Ed25519 algorithm (recommended, faster and more secure than RSA).
- `-C` — a label/comment, typically your email.

When prompted, press Enter to accept the default file location (`~/.ssh/id_ed25519`), then optionally set a passphrase.

This creates two files:

```
~/.ssh/id_ed25519       # private key — keep secret
~/.ssh/id_ed25519.pub   # public key — share with servers
```

### Step 2: Add the Key to the SSH Agent

```bash
# Start the ssh-agent (if not already running)
eval "$(ssh-agent -s)"
# Output: Agent pid 12345

# Add your private key
ssh-add ~/.ssh/id_ed25519
```

### Step 3: Add Public Key to GitHub

1. Copy the public key:

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

2. Go to **GitHub → Settings → SSH and GPG keys → New SSH key**.
3. Paste the key and give it a descriptive title (e.g., "Work Laptop").
4. Click **Add SSH key**.

### Step 4: Test the Connection

```bash
ssh -T git@github.com
```

Expected output:

```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

> If you see a prompt about host authenticity, type `yes` to add GitHub to `~/.ssh/known_hosts`.

---

## 3. SSH Agent: What, Why, and How

### What Is SSH Agent?

`ssh-agent` is a background program that holds your **decrypted private keys in memory**. Once loaded, you do not need to re-enter your passphrase every time you use the key.

### Why Use It?

- **Convenience** — enter passphrase once per session instead of on every connection.
- **Security** — private key stays in agent memory, not written to disk unencrypted.
- **Required for agent forwarding** (see section 4).

### How to Enable It

```bash
# Start the agent
eval "$(ssh-agent -s)"

# Add your key (prompts for passphrase if one is set)
ssh-add ~/.ssh/id_ed25519

# Verify loaded keys
ssh-add -l
```

### Useful Commands

| Command | Description |
|---|---|
| `ssh-add -l` | List all loaded keys |
| `ssh-add -D` | Remove all keys from the agent |
| `ssh-add -d ~/.ssh/id_ed25519` | Remove a specific key |

> **Tip:** On macOS and many Linux desktops, `ssh-agent` starts automatically. On servers, add `eval "$(ssh-agent -s)"` to your `~/.bashrc` or `~/.zshrc`.

---

## 4. SSH Agent Forwarding

### What Is Agent Forwarding?

SSH agent forwarding lets you **use your local SSH keys on a remote server or Docker container** — without copying private keys to that machine. The remote machine forwards authentication requests back to your local agent.

### Why Use It?

- Clone private Git repos on a remote server using your local GitHub key.
- SSH from a remote server to another server using your local key.
- **Never copy your private key** to remote machines.

### How to Enable It

#### Option A: Command Line

```bash
ssh -A user@remote-server
```

The `-A` flag enables agent forwarding for that session.

#### Option B: SSH Config (`~/.ssh/config`)

```
Host remote-server
    HostName 192.168.1.100
    User deploy
    ForwardAgent yes
```

Then simply `ssh remote-server` — forwarding is automatic.

### Using Agent Forwarding on the Remote Server

Once connected with `-A`, your local keys are available:

```bash
# On the remote server — this uses YOUR local key
ssh -T git@github.com
# Output: Hi your-username! You've successfully authenticated...
```

You can now `git clone`, `git push`, etc. on the remote server using your local credentials.

### Using Agent Forwarding with Docker

#### Method 1: Mount the SSH Agent Socket

```bash
docker run -it \
  -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK \
  -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK \
  ubuntu bash
```

Inside the container:

```bash
apt update && apt install -y openssh-client git
ssh -T git@github.com
# Works! Uses your host machine's loaded keys.
```

#### Method 2: Docker Compose

```yaml
services:
  app:
    build: .
    environment:
      - SSH_AUTH_SOCK=${SSH_AUTH_SOCK}
    volumes:
      - ${SSH_AUTH_SOCK}:${SSH_AUTH_SOCK}
```

#### Method 3: Dockerfile with BuildKit (for `git clone` during build)

```dockerfile
# syntax=docker/dockerfile:1
FROM ubuntu
RUN apt-get update && apt-get install -y openssh-client git
RUN --mount=type=ssh git clone git@github.com:your-org/private-repo.git
```

Build with:

```bash
DOCKER_BUILDKIT=1 docker build --ssh default .
```

### Security Warning

> **Agent forwarding has security risks.** A compromised remote server with root access can potentially use your forwarded agent to authenticate as you to other services. Use it only with trusted servers. Consider using `ProxyJump` as a safer alternative for multi-hop SSH.

---

## Quick Reference

| Task | Command |
|---|---|
| Generate key | `ssh-keygen -t ed25519 -C "email"` |
| Start agent | `eval "$(ssh-agent -s)"` |
| Add key to agent | `ssh-add ~/.ssh/id_ed25519` |
| Test GitHub | `ssh -T git@github.com` |
| SSH with forwarding | `ssh -A user@host` |
| Docker with agent | `docker run -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK ...` |

---

*Last updated: March 2026*
