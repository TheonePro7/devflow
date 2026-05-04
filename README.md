# devflow

**Claude Code 开发工作流编排器 — 3 阶段（Setup → Develop → Finish）增强 superpowers 管道**

devflow 是一个轻量级 orchestrator skill，包装 [obra/superpowers](https://github.com/obra/superpowers) 的 14-skill 管道，注入 **beads 任务追踪**、**gitnexus 代码图谱**、**autoresearch 自治循环** 三大工具。

```
Phase 1: Setup       → beads init + gitnexus analyze
Phase 2: Develop     → superpowers pipeline + tool injection
Phase 3: Finish      → beads close + session report

on-demand: /autoresearch  (debug/fix/ship/security)
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
├── SKILL.md                   # Orchestrator 定义
├── setup.ps1                  # Phase 1 Setup (Windows)
├── setup.sh                   # Phase 1 Setup (Unix)
├── README.md
├── LICENSE
├── .gitignore
└── docs/
    └── superpowers/
        └── specs/             # 设计文档存档
```

## 工具注入点

| superpowers 阶段 | devflow 注入 |
|---|---|
| brainstorming | beads: create epic issue; gitnexus: 代码上下文 |
| writing-plans | beads: 为每个 task 建子 issue; gitnexus: impact 分析 |
| subagent-driven-dev | gitnexus context 喂给子 agent; beads: 依赖检查 |

## Credits

- [obra/superpowers](https://github.com/obra/superpowers) — agentic skills framework
- [beads](https://github.com/gastownhall/beads) — Dolt-backed issue tracker
- [gitnexus](https://www.npmjs.com/package/gitnexus) — code intelligence graph
- [autoresearch](https://github.com/uditgoenka/autoresearch) — autonomous iteration loop
