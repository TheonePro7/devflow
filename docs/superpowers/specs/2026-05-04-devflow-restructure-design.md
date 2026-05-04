# devflow 重构设计文档

## 概述

将 devflow 从"7 阶段管道"重构为"3 阶段增强壳"，消除与 obra/superpowers 14-skill 管道的功能重叠，深度集成 beads + gitnexus + autoresearch。

## 架构

```
devflow (薄壳)
   │
   ├── Phase 1: Setup    — 项目级初始化
   ├── Phase 2: Develop  — 会话级开发（委派给 superpowers + 工具注入）
   └── Phase 3: Finish   — 善后清理
```

## 核心原则

1. devflow **不重写** superpowers 的任何阶段
2. devflow 的 3 个阶段是跨切面的（Setup 项目级、Develop 会话级、Finish 项目级）
3. 每个工具的注入点有明确定义（谁、何时、怎么用）

## 与当前架构的对比

| 当前 (Phase 0-6) | 新架构 (3 Phase) | 理由 |
|---|---|---|
| 0. Environment Check | 并入 Phase 1 | 空壳，无独立存续价值 |
| 1. Brainstorming | Phase 2 → 委派 superpowers-brainstorming | devflow 不重写 |
| 2. Writing Plans | Phase 2 → 委派 superpowers-writing-plans | 同上 |
| 3. Git Worktree | Phase 2 → 委派 superpowers-using-git-worktrees | 同上 |
| 4. Implementation | Phase 2 → 委派 superpowers-subagent-driven-development | devflow 在此注入工具 |
| 5. Code Review | 移除 → superpowers 自身已实现 | 完全重复 |
| 6. Finish | Phase 3 → beads close + cleanup | devflow 独有的善后 |

## Phase 1: Setup

一次性脚本（setup.ps1 / setup.sh）或首次检测时自动运行：

1. 检测依赖：bd、gitnexus、node、git
2. 初始化 beads：`bd init`
3. 构建 gitnexus 索引：`gitnexus analyze . --force`
4. 写入 `.claude/settings.json` 配置（可选）
5. 报告状态

## Phase 2: Develop

superpowers 管道正常执行，devflow 在 3 个注入点插入工具：

### 注入点 ① — Brainstorming 阶段
- `bd create --type=epic` 创建顶层 issue
- `gitnexus context <symbol>` 输出代码图上下文给设计

### 注入点 ② — Writing Plans 阶段
- 每拆分一个 task → `bd create --parent=<epic>` 创建子任务
- `bd dep add` 建立任务间依赖
- `gitnexus impact <symbol> --depth 2` 注入影响范围

### 注入点 ③ — Subagent-driven-development 阶段
- implementer 启动时附带 `gitnexus context` 数据
- spec-reviewer / quality-reviewer 同理
- `bd ready` 检查阻塞任务

### autoresearch 接入
- 注册为可用命令（非阶段）
- 用户随时可调用 `/autoresearch:debug`、`:fix`、`:ship` 等
- 不强制使用

## Phase 3: Finish

- `bd close` 关闭所有关联 issue
- git worktree 清理（superpowers 已有，devflow 不做重复）
- 最终状态报告

## 文件变更清单

- SKILL.md: 重写为 3 阶段架构
- README.md: 更新描述
- setup.ps1: 移除 prompts 复制，更新为 Phase 1
- setup.sh: 同步更新
- prompts/: 删除 4 个重复 prompt 文件
- 新增 docs/superpowers/specs/: 设计文档
