# Phase 0.5 Auto-Designer — Design Spec

## Overview

Auto-Designer 是 devflow Phase 0.5（Design）的核心增强模块。它将用户模糊的前端需求转化为专业级项目代码，自动匹配框架和设计系统，按项目复杂度选择最佳生成引擎。

## Architecture

```
User Input (natural language)
    │
    ▼
┌──────────────────────────────────────┐
│        Requirements Analyzer         │ ← Claude-driven
│  ─ classify project type             │
│  ─ match framework + design system   │
│  ─ score complexity                  │
└──────────────┬───────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│        Complexity Router              │
│                                      │
│  Small  (1-5)   → Claude Direct      │
│  Medium (6-15)  → OpenUI (on-demand) │
│  Large  (16+)   → bolt.diy (on-demand│
│  Has screenshot → screenshot-to-code │
└──────────────┬───────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│        Unified Post-Processor        │
│  ─ inject design tokens              │
│  ─ scaffold project structure        │
│  ─ register beads dev tasks          │
└──────────────────────────────────────┘
               │
               ▼
       Ready for Phase 2
```

## Requirements Analyzer

### Project Type Classification

| Type | Examples |
|------|----------|
| landing | Company site, marketing page, portfolio |
| admin | Dashboard, CRM, analytics panel |
| social | Forum, chat app, community platform |
| ecommerce | Store, product catalog, checkout |
| tool | Calculator, converter, text editor |
| content | Blog, news site, documentation |
| mobile | Mobile app UI (React Native / Ionic) |

### Framework Matching (automatic)

| Type | Default Framework | Why |
|------|------------------|-----|
| landing | Next.js + Tailwind | SSR for SEO, fast loads |
| admin | React + Ant Design | Enterprise-grade table/form components |
| social | Next.js + Tailwind | SSR + real-time friendly |
| ecommerce | Next.js + Tailwind | SSR for product pages |
| tool | React + shadcn/ui | Lightweight, clean components |
| content | Next.js + Tailwind | MDX support, SSR |
| mobile | React Native + NativeWind | Cross-platform |

### Complexity Scoring

```
score = pageCount × 2 + modelCount × 3 + apiEndpointCount × 1

1-5   → Claude Direct
6-15  → OpenUI
16+   → bolt.diy
```

If user provides screenshots/Figma links → always route to screenshot-to-code.

## Generator Layer

### Claude Direct (built-in, zero dependencies)

- Default for 80% of projects
- Claude generates full project scaffold in session
- Uses SKILL.md prompt templates for consistent output
- No install, no setup, no external process

### OpenUI (on-demand, 22.3k⭐)

- Triggered when user confirms "use stronger frontend generator"
- Auto-installed via `pip install openui` or Docker
- Natural language → live preview → export to code
- Supports React / Svelte / Web Components

### bolt.diy (on-demand, 19.3k⭐)

- Triggered for large projects or when user requests
- Auto-installed via `git clone` + `npm install`
- Browser-based IDE with real-time preview
- Supports 19+ AI providers
- Generates Node.js full-stack projects

### screenshot-to-code (on-demand, 72.4k⭐)

- Triggered when user provides screenshots/Figma
- Auto-installed via Docker (`docker pull` already available)
- Converts screenshots to HTML/React/Vue/Tailwind

## Unified Post-Processor

Every generator output goes through this pipeline:

1. **Design Token Injection**: Apply consistent color palette, spacing, typography
2. **Project Structure Normalization**: Ensure standard React/Next.js directory layout
3. **Beads Task Registration**: Auto-create dev tasks from generated pages/components
4. **Integration Stubs**: Add API call patterns matching devflow's Phase 2 conventions

## On-Demand Install Strategy

```
# Lightweight — always available, zero cost
Claude Direct ─────────────────────────► built into SKILL.md

# On-demand — only installed when user says "yes"
OpenUI          →  pip install openui          ~100MB
bolt.diy        →  git clone + npm install     ~200MB
screenshot-to-code → docker compose up         ~500MB
```

Installation is triggered by user confirmation:

> "这个项目比较大，需要安装 Bolt 来生成前端。需要几分钟，继续吗？"
> [Yes / No]

## Files to Change

| File | Change |
|------|--------|
| `SKILL.md` | Add Phase 0.5 Auto-Designer section with routing logic |
| `setup.sh` / `setup.ps1` | Add `--with-designer` flag for pre-installing optional generators |
| `scripts/` | New `auto-designer.sh` / `auto-designer.ps1` as the orchestrator entry point |

## Non-Goals

- Not replacing Phase 2 superpowers pipeline (generated frontend still goes through dev → review → finish)
- Not maintaining our own component library (delegate to Ant Design / shadcn/ui / Tailwind)
- Not generating backend code (bolt.diy generates full-stack, but we only consume the frontend output)
- Not modifying user's existing project without explicit confirmation
