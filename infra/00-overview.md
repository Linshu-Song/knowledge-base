# Infrastructure & Development Guide

## Language Selection

- **English** (Current) - This document
- [简体中文](00-overview.zh-CN.md) - Simplified Chinese
- [繁體中文](00-overview.zh-HK.md) - Traditional Chinese

---

## About This Guide

This guide covers infrastructure setup, development environments, deployment, operations, and SSH key management. It is **tech-agnostic** — the principles apply to any language stack, cloud provider, or orchestrator.

**Sections:**

| # | Guide | Description |
|---|---|---|
| 1 | [Repository Architecture Overview](01-architecture-overview.md) | Monorepo vs Polyrepo comparison, shared contract pattern, boundary enforcement, and decision criteria |
| 2 | [Infrastructure Setup](02-infrastructure-setup.md) | Docker Compose architecture, environment variable strategy, multi-stage Dockerfiles, and service configuration |
| 3 | [Development Environment](03-development-environment.md) | Dev Container decision framework, configuration, SSH agent forwarding, Git config, and daily workflow |
| 4 | [Production Deployment](04-production-deployment.md) | Environment tiers, image building, secrets management, database migrations, and CI/CD pipelines |
| 5 | [Operations & Troubleshooting](05-operations-troubleshooting.md) | Health checks, logging, rollback procedures, Docker/Compose/Dev Container/network troubleshooting |
| 6 | [SSH & SSH Key Guide](ssh.md) | SSH key generation, SSH agent, agent forwarding, Docker integration, and security best practices |

---

## Prerequisites

- Basic familiarity with Docker and Docker Compose
- Git basics
- A terminal / shell environment (Bash, Zsh, etc.)

## Scope

This guide **does not** cover:

- Cloud-specific services (e.g., AWS, GCP, Azure)
- Application-level code patterns
- Database schema design

For those topics, refer to other sections of this knowledge base.

---

[← Back to Knowledge Base](../README.md)

*Last updated: March 2026*
