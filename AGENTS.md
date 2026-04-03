# AGENTS.md

## 1. Project Overview

SAILTECHTEAM internal knowledge base covering Deep Learning, Python, Git, and Infrastructure. Hosted on GitHub Pages.

## 2. Tech Stack

- **Docusaurus 3.9** + `.mdx` (all docs use MDX format)
- `remark-math` + `rehype-katex` for math; `@docusaurus/theme-mermaid` for diagrams
- Rspack + SWC via `@docusaurus/faster`; **bun** as package manager; Node >= 20
- Deployed via GitHub Actions

| Command | Purpose |
| :--- | :--- |
| `bun run start` | Dev server (hot reload) |
| `bun run build` | Production build |
| `bun run serve` | Serve build locally |

## 3. i18n

English (`en`) is the default and source of truth. Always write English first in `docs/`, then translate to:

| Locale | Directory |
| :--- | :--- |
| `en` | `docs/` |
| `zh-CN` | `i18n/zh-CN/docusaurus-plugin-content-docs/current/` |
| `zh-HK` | `i18n/zh-HK/docusaurus-plugin-content-docs/current/` |

Keep same directory structure, file name, and frontmatter across locales. Adapt content only.

## 4. Writing Style

- Professional, technical, objective — no slang or first-person opinions.
- Action-oriented: "Install the package" not "You should install the package".
- Concise and precise. Remove filler words.

## 5. Document Template

Follow `docs/template.mdx` for formatting conventions (frontmatter, admonitions, code blocks, diagrams, tone). Additional rules:

- **File ordering** — Use numbered prefixes (e.g. `01-architecture-overview.mdx`) and `_category_.json` for sidebar labels.
