# 基础设施与开发指南

## 语言选择

- [English](00-overview.md) - 英文
- **简体中文** (当前) - 本文档
- [繁體中文](00-overview.zh-HK.md) - 繁体中文

---

## 关于本指南

本指南涵盖基础设施搭建、开发环境、部署、运维和 SSH 密钥管理。**技术无关**——适用于任何语言栈、云供应商或编排工具。

**各章节：**

| # | 指南 | 说明 |
|---|---|---|
| 1 | [存储库架构概览](01-architecture-overview.zh-CN.md) | 单体存储库 vs 多存储库对比、共享契约模式、边界强制执行、决策标准 |
| 2 | [基础设施搭建](02-infrastructure-setup.zh-CN.md) | Docker Compose 架构、环境变量策略、多阶段 Dockerfile、服务配置 |
| 3 | [开发环境](03-development-environment.zh-CN.md) | 开发容器决策框架、配置、SSH Agent 转发、Git 配置、日常工作流程 |
| 4 | [生产部署](04-production-deployment.zh-CN.md) | 环境分层、镜像构建、密钥管理、数据库迁移、CI/CD 流水线 |
| 5 | [运维与故障排除](05-operations-troubleshooting.zh-CN.md) | 健康检查、日志、回滚流程、Docker/Compose/开发容器/网络故障排除 |
| 6 | [SSH 与 SSH Key 指南](ssh.zh-CN.md) | SSH 密钥生成、SSH Agent、Agent 转发、Docker 集成、安全最佳实践 |

---

## 前置条件

- 基本了解 Docker 和 Docker Compose
- Git 基础知识
- 命令行 / Shell 环境（Bash、Zsh 等）

## 范围

本指南**不涵盖**：

- 云平台特定服务（如 AWS、GCP、Azure）
- 应用层代码模式
- 数据库模式设计

请参考知识库其他章节获取这些内容。

---

[← 返回知识库](../README-zh-CN.md)

*最后更新：2026 年 3 月*
