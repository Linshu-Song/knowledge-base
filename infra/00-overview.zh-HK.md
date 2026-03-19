# 基礎架構與開發指南

## 語言選擇

- [English](00-overview.md) - 英文
- [简体中文](00-overview.zh-CN.md) - 簡體中文
- **繁體中文** (當前) - 本文檔

---

## 關於本指南

本指南涵蓋基礎架構搭建、開發環境、部署、操作同 SSH 密鑰管理。**技術無關**——適用於任何語言堆棧、雲端供應商或編排工具。

**各章節：**

| # | 指南 | 說明 |
|---|---|---|
| 1 | [儲存庫架構概覽](01-architecture-overview.zh-HK.md) | 單一儲存庫 vs 多元儲存庫比較、共享契約模式、邊界強制執行、決策標準 |
| 2 | [基礎架構搭建](02-infrastructure-setup.zh-HK.md) | Docker Compose 架構、環境變數策略、多階段 Dockerfile、服務配置 |
| 3 | [開發環境](03-development-environment.zh-HK.md) | Dev Container 決策框架、配置、SSH Agent 轉發、Git 配置、日常工作流程 |
| 4 | [生產部署](04-production-deployment.zh-HK.md) | 環境分層、映像建構、密鑰管理、資料庫遷移、CI/CD 管線 |
| 5 | [操作與故障排除](05-operations-troubleshooting.zh-HK.md) | 健康檢查、日誌、回滾流程、Docker/Compose/Dev Container/網絡故障排除 |
| 6 | [SSH 與 SSH Key 指南](ssh.zh-HK.md) | SSH 密鑰產生、SSH Agent、Agent 轉發、Docker 整合、安全最佳實踐 |

---

## 前置條件

- 基本了解 Docker 同 Docker Compose
- Git 基礎知識
- 命令列 / Shell 環境（Bash、Zsh 等）

## 範圍

本指南**唔涵蓋**：

- 雲端平台特定服務（例如 AWS、GCP、Azure）
- 應用層代碼模式
- 資料庫模式設計

請參考知識庫其他章節獲取呢啲內容。

---

[← 返回知識庫](../README-zh-HK.md)

*最後更新：2026 年 3 月*
