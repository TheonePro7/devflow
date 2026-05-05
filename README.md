# devflow

**Claude Code 开发工作流编排器 — 3 阶段（Setup → Develop → Finish）增强 superpowers 管道**

devflow 是一个轻量级 orchestrator skill，包装 [obra/superpowers](https://github.com/obra/superpowers) 的 14-skill 管道，注入 **beads 任务追踪**、**gitnexus 代码图谱**、**autoresearch 自治循环**、**plan-grill 拷问**、**PRD→beads 自动拆分**、**TDD 深度参考**六大工具。

```
Phase 1: Setup       → beads init + gitnexus analyze + docs/ seed + guardrails
Phase 2: Develop     → superpowers pipeline + tool injection + grill gate
Phase 3: Finish      → beads close + session report

on-demand: /autoresearch  (debug/fix/ship/security)
background: Git guardrails (PreToolUse hook)
```

## 与 superpowers 的关系

devflow **不重写** superpowers 的任何阶段。以下阶段全部由 superpowers 原生执行：

| 能力 | 所有者 |
|------|--------|
| Brainstorming → 设计文档 | superpowers-brainstorming |
| Writing Plans → 任务拆分 | superpowers-writing-plans |
| Git Worktree → 隔离分支 | superpowers-using-git-worktrees |
| 子代理 3 阶段开发 | superpowers-subagent-driven-development |
| 代码审查 | superpowers-requesting-code-review |
| 完成分支 | superpowers-finishing-a-development-branch |

devflow 的增值在于**工具注入**：

- **beads**: 在每个阶段创建/更新/关闭任务 issue，建立层级和依赖
- **gitnexus**: 预取代码图谱上下文喂给子 agent，不做"黑盒分析"
- **autoresearch**: 注册为可用命令，用户按需调用自治循环
- **plan-grill**: 在 brainstorming → writing-plans 之间插入拷问环节（HITL），使用 CONTEXT.md + ADR + gitnexus 检查盲点
- **PRD→beads**: 自动解析设计文档中的 `## Task:` 标题，为每个 task 创建 beads issue
- **TDD 深度文档**: 5 份参考文档（deep-modules, interface-design, mocking, refactoring, tests）补充 TDD 阶段

## 新增特性（从 mattpocock/skills 借鉴）

| 特性 | 来源 | 说明 |
|------|------|------|
| Git guardrails | `git-guardrails-claude-code` | PreToolUse hook 拦截危险 git 操作 |
| Plan-grill | `grill-with-docs` | CONTEXT.md+ADR 拷问计划盲点 |
| PRD→beads | `to-prd` + `to-issues` | 设计文档自动拆分为 beads issues |
| TDD deep docs | `tdd/` 参考文档 | 5 份测试哲学/模式指导 |
| CONTEXT.md+ADR | `CONTEXT.md` + `docs/adr/` | 领域词汇表 + 架构决策记录 |

## 前置依赖

- [beads](https://github.com/gastownhall/beads) — Dolt-backed issue tracker
- [gitnexus](https://www.npmjs.com/package/gitnexus) — code knowledge graph
- [obra/superpowers](https://github.com/obra/superpowers) — 14-skill pipeline
- [autoresearch](https://github.com/uditgoenka/autoresearch) (可选) — 自治改进循环
- Node.js ≥ 18, Git

## 安装

```bash
# 1. 安装前置依赖
npm install -g gitnexus
go install github.com/gastownhall/beads/cmd/bd@latest

# 2. 安装 superpowers (Claude Code plugin marketplace)
/plugin install superpowers@claude-plugins-official

# 3. 安装 autoresearch (可选)
npx skills add uditgoenka/autoresearch

# 4. 安装 devflow
git clone https://github.com/TheonePro7/devflow.git ~/.claude/skills/devflow

# 5. 初始化项目 (在项目根目录)
# PowerShell:
.\setup.ps1
# bash:
# bash setup.sh
```

## 目录结构

```
devflow/
├── SKILL.md                    # Orchestrator 定义
├── setup.ps1                   # Phase 1 Setup (Windows)
├── setup.sh                    # Phase 1 Setup (Unix)
├── README.md
├── LICENSE
├── .gitignore
├── .claude/
│   ├── settings.json           # 项目级 hooks 注册
│   ├── settings.local.json     # 本地权限覆写 (.gitignored)
│   └── hooks/
│       ├── devflow-init-check.ps1  # SessionStart: Phase 1 检测
│       └── guardrails-git.ps1      # PreToolUse: 危险 git 拦截
├── scripts/
│   ├── prd-to-beads.ps1        # 设计文档 → beads issues (Windows)
│   └── prd-to-beads.sh         # 设计文档 → beads issues (Unix)
├── docs/
│   ├── CONTEXT.md              # 领域词汇表 (ubiquitous language)
│   ├── adr/                    # 架构决策记录
│   │   ├── README.md
│   │   └── 0001-use-devflow-3-phase-orchestration.md
│   └── tdd/                    # TDD 深度参考文档
│       ├── deep-modules.md
│       ├── interface-design.md
│       ├── mocking.md
│       ├── refactoring.md
│       └── tests.md
└── docs/superpowers/
    └── specs/                  # 设计文档存档
```

## 工具注入点

| superpowers 阶段 | devflow 注入 |
|---|---|
| brainstorming | beads: create epic issue; gitnexus: 代码上下文; CONTEXT.md: 领域词汇 |
| **GRILL GATE** ═══ | CONTEXT.md + ADR 拷问计划; gitnexus 验证代码事实; beads 检查依赖阻塞 |
| writing-plans | beads: 为每个 task 建子 issue; gitnexus: impact 分析; PRD→beads: 自动拆分 |
| subagent-driven-dev | gitnexus context 喂给子 agent; beads: 依赖检查; TDD docs: 参考 |
| **background** | Git guardrails 阻止危险操作 (--force, reset --hard 等) |

## Credits

- [obra/superpowers](https://github.com/obra/superpowers) — agentic skills framework
- [mattpocock/skills](https://github.com/mattpocock/skills) — DDD-driven skills (grill, TDD docs, guardrails)
- [beads](https://github.com/gastownhall/beads) — Dolt-backed issue tracker
- [gitnexus](https://www.npmjs.com/package/gitnexus) — code intelligence graph
- [autoresearch](https://github.com/uditgoenka/autoresearch) — autonomous iteration loop
