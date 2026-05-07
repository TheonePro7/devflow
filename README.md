# devflow

**Claude Code 产品级编排器 — 5 阶段（Ideate → Design → Setup → Develop → Finish）从创意到落地，小白也能用的全流程产品开发**

[English](README.en.md) • ![CI](https://github.com/TheonePro7/devflow/actions/workflows/ci.yml/badge.svg)

devflow 是面向 Claude Code 的全生命周期产品编排器。从**灵感到成品**，覆盖 5 个阶段：创意梳理（Phase 1）→ 前端设计（Phase 2）→ 项目初始化（Phase 3）→ 开发循环（Phase 4）→ 会话收尾（Phase 5）。

包装 [obra/superpowers](https://github.com/obra/superpowers) 的 14-skill 管道，注入 **beads 任务追踪**、**gitnexus 代码图谱**（通过 Docker 运行，绕过 Windows tree-sitter 兼容性问题）、**autoresearch 自动优化**（4 个自动门）、**screenshot-to-code 前端生成**、**plan-grill 拷问**、**PRD→beads 自动拆分**、**TDD 深度参考**。同时从 [mattpocock/skills](https://github.com/mattpocock/skills) 吸收了 Git guardrails、领域词汇表 (CONTEXT.md) 和架构决策记录 (ADR) 等模式。

即使没有技术背景，也可以从一个模糊的想法开始，经过结构化引导，最终落地为可交付的产品。

---

## 目录

- [一、核心架构](#一核心架构)
- [二、Phase 1：创意梳理（Ideate）](#二phase-1创意梳理ideate)
- [三、Phase 2：前端设计（Design）](#三phase-2前端设计design)
- [四、Phase 3：项目初始化（Setup）](#四phase-3项目初始化setup)
- [五、Phase 4：开发循环（Develop）](#五phase-4开发循环develop)
- [六、Phase 5：会话收尾（Finish）](#六phase-5会话收尾finish)
- [七、工具注入详解](#七工具注入详解)
- [八、Git Guardrails 安全防护](#八git-guardrails-安全防护)
- [九、Hook 系统](#九hook-系统)
- [十、项目文件清单](#十项目文件清单)
- [十一、安装与初始化](#十一安装与初始化)
- [十二、常见场景工作流](#十二常见场景工作流)
- [十三、FAQ 与故障排除](#十三faq-与故障排除)
- [十四、开发者资源](#十四开发者资源)
- [十五、与生态项目的关系](#十五与生态项目的关系)

---

## 一、核心架构

devflow 采用 **5 阶段**架构，从灵感到成品的全生命周期：

```
                     devflow (orchestrator)
                            │
       ┌────────────────────┼────────────────────┐
       ▼                    ▼                    ▼
   Phase 1             Phase 2             Phase 3-5
   Ideate              Design              Setup→Develop→Finish

   Idea → PRD          PRD → Frontend      Full-stack dev

   Claude 引导        4 阶段 UI 设计      superpowers 管道
   用户画像           引擎                + autoresearch 门禁
   + 问题分析          + 自动框架匹配      + git guardrails
   + to-prd 输出       + Claude Direct
```

### 设计原则

| 原则 | 说明 |
|------|------|
| **从灵感到产品** | Phase 1 帮助非技术用户梳理想法；Phase 2 生成前端设计；Phase 3-5 工程落地 |
| **不重写 superpowers** | devflow 不做 superpowers 已做的事。Brainstorming、writing-plans、subagent-dev、code-review、finish-branch 全部委托给 superpowers-* |
| **工具注入** | devflow 的价值在于在管道的定义点注入 beads、gitnexus、grill、screenshot-to-code 等工具 |
| **硬关卡** | Phase 1 → Phase 2 → Phase 3 顺序执行。Plan-grill 未通过不能进入 writing-plans |
| **HITL 优先** | Grill 拷问、Phase 5 报告需要人类确认。自动化不跳过判断 |
| **安全默认** | Git guardrails 默认拦截危险操作，覆写需要显式意图 |

### 与 superpowers 的职责划分

| 能力 | 所有者 | devflow 的参与 |
|------|--------|----------------|
| 需求讨论 → 设计文档 | superpowers-brainstorming | ① 注入 beads epic + gitnexus context + CONTEXT.md |
| 拷问计划盲点 | **devflow (plan-grill)** | ①½ 新增环节，使用 CONTEXT.md + ADR + gitnexus |
| 设计 → 任务拆分 | superpowers-writing-plans | ② 注入 beads sub-issues + gitnexus impact + PRD→beads |
| 子代理 3 阶段开发 | superpowers-subagent-driven-development | ③ 注入 gitnexus context + beads ready + TDD docs |
| 代码审查 | superpowers-requesting-code-review | 不参与 |
| Git 工作树 | superpowers-using-git-worktrees | 不参与 |
| 完成分支 | superpowers-finishing-a-development-branch | 不参与 |
| TDD | superpowers-test-driven-development | docs/tdd/ 深度文档作为参考 |
| 危险命令防护 | **devflow (guardrails)** | PreToolUse hook，持续后台运行 |

---

## 二、Phase 1：创意梳理（Ideate）

**面向人群**：有想法但不知道如何落地的用户。不需要编程或设计经验。

### 发生了什么

用户说出自己的想法，Claude 启动 **4 阶段自适应探索引擎**：

```
Stage 1: 问题发现
  ├── 痛点 → 现状 → 时机 → 竞品分析
  └── 输出: Problem Statement

Stage 2: 用户与场景
  ├── 提炼 2-3 个用户角色
  ├── 每个角色分析场景与诉求
  └── 输出: Personas + User Stories

Stage 3: 功能探索 (发散→收敛)
  ├── 发散: brainstorm 所有功能
  ├── 收敛: MoSCoW 优先级归类
  └── 输出: 功能清单 + Deep Module 识别

Stage 4: 约束与成功标准
  ├── 技术/时间/平台/业务约束
  ├── 成功率指标 (定性+定量)
  └── 风险评估与缓解

自适应机制: 用户已说清的环节跳过，只追问模糊地带
```

探索完成后输出结构化 JSON 到 `.devflow/prd-context.json`，然后自动调用 **to-prd** 技能格式化生成最终 PRD，同时保存到 `docs/prd/` 和 GitHub Issues。

### 核心价值

- **降低门槛**：不需要写需求文档，用自然语言描述即可
- **自适应探索**：不会问重复问题，只挖掘信息缺口
- **结构化输出**：从模糊想法到可执行的完整 PRD
- **无缝衔接**：PRD 直接喂给 Phase 2 做前端设计，或 Phase 4 做开发

---

## 三、Phase 2：前端设计（Design）

**面向人群**：需要前端界面但不懂设计或前端开发的用户。

### 发生了什么

Phase 1 生成 PRD 后，**强制进入 Phase 2**。这是一个 4 阶段流程引擎，和 Phase 1 一样有明确定义的阶段、输出物和确认点：

```
PRD 完成
  │
  ├── Stage 1: UI 需求提取 (step=ui-req)
  │   ├── 从 PRD 提取页面/界面清单
  │   ├── 提取用户流程与交互路径
  │   ├── 提取数据展示需求
  │   ├── 自动分类项目类型 (landing/admin/ecommerce/...)
  │   └── 输出: UI 需求摘要
  │
  ├── Stage 2: 架构蓝图 (step=arch-decision)
  │   ├── 自动选型: 框架 + 设计系统（不询问用户）
  │   ├── 定义组件树（父子层级）
  │   ├── 定义状态管理模式
  │   └── 定义 API 集成点
  │
  ├── Stage 3: 前端代码生成 (step=scaffold)
  │   ├── Claude Direct（默认，1-5 页）— 零安装
  │   ├── OpenUI（6-15 页，按需安装）
  │   ├── bolt.diy（16+ 页，按需安装）
  │   ├── screenshot-to-code（有设计稿时）
  │   └── 应用设计令牌（颜色、间距、排版）
  │
  └── Stage 4: 设计文档化 (step=ux-docs → design-done)
      ├── 保存到 docs/ux/<feature>/
      ├── 创建 beads 前端开发任务
      ├── 更新 prd-context.json
      └── 移交 Phase 4 开发管道
```

### 核心价值

- **自动决策**：框架和设计系统自动匹配，用户不需要懂前端技术
- **Claude Direct 默认**：80% 的项目零依赖，无需安装任何工具
- **可升级**：项目复杂时，可以无缝切换到 OpenUI/bolt.diy/screenshot-to-code
- **设计决策持久化**：所有选择记录在 docs/ux/，后续开发有据可查

---

## 四、Phase 3：项目初始化（Setup）

**触发条件**：SessionStart hook 检测到 `.beads/` 或 `.gitnexus/` 缺失。

### 执行流程

**新项目（未初始化）:**

```
用户在 Claude Code 中打开新项目目录
    │
    ├── 🌐 全局 SessionStart Hook 触发
    │   └── 检测 .devflow/state 不存在 → 提示 devflow 可用
    │
    └── 用户说「用 devflow 开发」
        │
        ├── 📜 SKILL.md 新项目检测逻辑
        │   └── .devflow/state 不存在 → 自动运行 setup.sh
        │
        ├── 🔧 setup.sh 执行:
        │   ├── beads init
        │   ├── gitnexus analyze
        │   ├── 写入 CLAUDE.md 最高指示
        │   ├── 注册 hooks（SessionStart + UserPromptSubmit + PreToolUse）
        │   ├── 创建 .devflow/state
        │   ├── 创建 docs/
        │   └── 安装 autoresearch
        │
        └── 初始化完成 → 进入 Phase 1（需求梳理）
```

**已有项目（已初始化）:**

```
SessionStart hook (全局 + 项目级)
    │
    ├── .devflow/state 存在 → 静默通过
    ├── 检测 bd + gitnexus + .beads/
    │
    完成 → 等待用户提出需求
         │
         ├── 🧠 CLAUDE.md 最高指示生效
         ├── 🔒 UserPromptSubmit Hook 每步注入状态
         └── 🔒 PreToolUse Hook 拦截跳步骤
```

### 手动运行

PowerShell：
```powershell
.\setup.ps1
```

bash：
```bash
bash setup.sh
```

### setup 脚本执行内容

| 步骤 | 操作 | 失败处理 |
|------|------|----------|
| 1 | 检查 bd + gitnexus 是否安装 | 缺失则退出，提示安装命令 |
| 2 | `bd init` 初始化 beads 仓库 | 已初始化则忽略 |
| 3 | `bash scripts/gitnexus-docker.sh analyze --force` 构建代码图谱（通过 Docker，绕过 Windows SIGSEGV） | 提示安装 Docker Desktop 后重试 |
| 4 | 创建 `docs/CONTEXT.md`（如果不存在） | 已有则跳过 |
| 5 | 创建 `docs/adr/` + README.md（如果不存在） | 已有则跳过 |
| 6 | 创建 `docs/tdd/` 目录（如果不存在） | 已有则跳过 |
| 7 | 安装 autoresearch（`npx skills add uditgoenka/autoresearch`） | 失败则警告，可跳过: `DEVFLOW_NO_AUTORESEARCH=1` |
| 8 | 检查 `.claude/hooks/guardrails-git.ps1` + `.sh` | 缺失则自动复制 |

### Phase 3 产物

```
./beads/              # beads 本地仓库
./gitnexus/           # gitnexus 代码图谱索引
docs/CONTEXT.md       # 领域词汇表模板（需手动填充）
docs/adr/README.md    # 架构决策记录目录
docs/tdd/             # TDD 深度参考文档目录
```

---

## 五、Phase 4：开发循环（Develop）

**每个开发任务的会话循环**。这是 devflow 的核心阶段。

### 完整管道

```
用户提出需求
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ① superpowers-brainstorming                     │
│   设计探索 → 2-3 方案 → user 审批                │
│   ★ HARD GATE: user 批准前不得写代码             │
│   devflow 注入: beads epic + gitnexus context   │
├─────────────────────────────────────────────────┤
    │ 用户批准设计
    ▼
┌─────────────────────────────────────────────────┐
│ using-git-worktrees                             │
│   创建隔离工作区，不污染主项目                   │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ①½ AUTORESEARCH PROBE ★ HARD GATE               │
│   /autoresearch:probe                           │
│   8 个对抗人格发现隐藏约束和矛盾                │
│   跳过: 设置 gate_probe=skipped                │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ② superpowers-writing-plans                     │
│   按 superpowers 格式: header + 无占位符规则     │
│   devflow 注入: beads sub-issues + gitnexus     │
│   impact + PRD→beads 自动拆分                   │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ③ superpowers-subagent-driven-development       │
│   完整 per-task 循环:                            │
│   ├─ implementer 子 agent                       │
│   ├─ spec-reviewer 子 agent                     │
│   ├─ quality-reviewer 子 agent                  │
│   └─ requesting-code-review (devflow 参与!)     │
│   devflow 注入: gitnexus context + beads depth  │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ②¾ AUTORESEARCH SECURITY ★ HARD GATE            │
│   /autoresearch:security --diff                 │
│   STRIDE + OWASP Top10 + 红队审计              │
│   Critical/High 必须修复才能 finish             │
│   跳过: 设置 gate_security=skipped             │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ③¼ AUTORESEARCH OPTIMIZE (交互式)               │
│   完整 loop: plan→modify→verify→keep/discard→log │
│   /autoresearch:plan 设置 Goal+Scope+Metric     │
│   /autoresearch 运行 N 轮                       │
│   TSV 日志 → 自动 git rollback → keep/discard   │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ⑤ superpowers-finishing-a-development-branch    │
│   4 选项: merge / PR / keep / discard           │
│   cleanup: using-git-worktrees 清理             │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ PHASE 4→5 HANDOFF → Phase 5 close + push       │
└─────────────────────────────────────────────────┘

后台运行:
  - Git guardrails PreToolUse hook
  - verification-before-completion 通用门禁
  - beads 质量检查 (lint/stale/orphans)
```

### Phase 4 设计理念

devflow Phase 4 不再自创 10 步流程，而是**完全对齐 superpowers 的原始技能链**，只在定义点注入 devflow 的工具（beads + gitnexus + autoresearch）。

**关键变更（与旧版对比）**:

| 旧版 devflow 步骤 | 新版 | 理由 |
|------|------|------|
| brainstorming → grill → probe → plans → scenario → impl → review → security → optimize → finish | brainstorming(HARD GATE) → probe → plans → impl (含 spec-review + quality-review + code-review) → security → optimize | 消除重复：grill 被 brainstorming 的设计审批替代；scenario 被 spec-reviewer 子 agent 覆盖；fix 被 quality-reviewer 覆盖 |
| `devflow 不参与` code review | ✅ 现在参与 | superpowers 的 requesting-code-review 是 per-task 的 |
| 不创建隔离工作区 | ✅ adding using-git-worktrees | 防止污染主工作区 |
| autoresearch 4 门（probe/scenario/fix/security） | autoresearch 3 重（probe/security/optimize） | scenario 和 fix 由 superpowers 的子 agent 覆盖 |
| optimize 只是提示 | ✅ 完整 autoresearch loop | plan→modify→verify→keep/discard→log→repeat |

**产出物**：
- 更新后的 `docs/CONTEXT.md`
- 新增 `docs/superpowers/specs/<design>-grill-report.md`
- 明确的 "通过" / "返回修改" 决策

---

## 六、Phase 5：会话收尾（Finish）

**每个开发会话结束时执行**。Phase 4 的 autoresearch optimize 步骤已处理优化，Phase 5 只做轻量收尾。

### 执行内容

1. **更新 .devflow/state** — `phase=5, step=finish → done`
2. **beads close** — 关闭当前会话中创建或更新的所有 beads issues
   - `bd update <id> --close` (已完成的任务)
   - `bd update <id> --status=wontfix` (不实施的任务)
3. **git add + git commit + git push** — 提交并推送所有变更
4. **Session report** — 生成会话摘要
   - 完成的任务列表
   - 未完成的任务及原因
   - 新建或更新的 docs/ 文件
   - 建议的后续步骤

---

## 七、工具注入详解

### ① — Brainstorming 注入

**时机**：`superpowers-brainstorming` 运行前。

```yaml
beads:
  - 命令: bd create --title="<feature>" --type=epic
  - 作用: 将特性创建为可追踪的一级 issue，后续子任务可以挂载

gitnexus:
  - 命令: bash scripts/gitnexus-docker.sh context <key-symbol>
  - 作用: 预取相关代码的上下文（类型定义、接口、调用链），
          喂给 brainstorming 子 agent，避免其在缺乏代码知识
          的情况下做设计
  - 注意: 需要 Docker Desktop 运行；docker 不可用时跳过（非致命）

context:
  - 加载 docs/CONTEXT.md，让子 agent 了解领域词汇
  - 加载 docs/adr/，让子 agent 了解过去的架构决策
```

### ① — Brainstorming + HARD GATE

**时机**：理解用户需求后。**这是 devflow Phase 4 的入口。**

> 调用 `superpowers-brainstorming` Skill。这是 superpowers 原生的设计探索技能。

**HARD GATE: 必须先呈现设计给用户批准，才能写代码。**

```yaml
流程:
  1. beads: bd create --title="<feature>" --type=epic
  2. gitnexus context + CONTEXT.md + ADR 加载
  3. 一步步提出方案（2-3 种），推荐最优
  4. 呈现设计 → 用户审批（HARD GATE）
  5. 写设计文档 → docs/superpowers/specs/
  6. 创建隔离工作区: using-git-worktrees
```

**拦截机制**: brainstorming 步骤中如果 agent 直接写代码 → PreToolUse hook 告警。

### ①½ — Autoresearch Probe 注入 ★ HARD GATE

**时机**：设计批准后、writing-plans 前。**3 层强制不可跳过。**

> 调用 `/autoresearch:probe`，8 个对抗人格发现隐藏约束。

```yaml
触发: 自动
命令: /autoresearch:probe --chain plan,autoresearch
      Topic: "<feature-title>"

输出: probe/{date}-{slug}/
  - 约束条件、矛盾点、假设、handoff.json

跳过: 设置 gate_probe=skipped
拦截: PreToolUse hook 在 step=probe 时检查
```

### ② — Writing Plans + beads 深度注入

**时机**：probe 完成后。

> 调用 `superpowers-writing-plans` Skill。按 superpowers 格式写计划。

```yaml
beads:
  - bd create --title="<task>" --parent=<epic_id> --type=task
  - bd link <task> <dependency>    # 设置依赖图
  - bd label add <id> <type>       # 标签

gitnexus:
  - scripts/gitnexus-docker.sh impact <symbol> --depth 2

auto-split:
  - scripts/prd-to-beads.sh -d <design.md>

执行选择:
  提供两种选项: subagent-driven-development (推荐) 或 executing-plans
```

### ③ — Subagent-Driven Development + 全注入

**时机**：计划分解后。

> 调用 `superpowers-subagent-driven-development` Skill。

完整的 per-task 循环：implementer → spec-reviewer → quality-reviewer → **requesting-code-review**

```yaml
gitnexus:
  - 主 agent 预取 context 传给每个子 agent

beads (深度):
  - bd ready → bd update --claim → bd note 记录进度

requesting-code-review:
  - 每个 task 完成后调用，不再标注"devflow 不参与"
  - 使用 superpowers 原生模板

verification-before-completion:
  - 通用门禁: 无验证证据不得声称完成
```

### ②¾ — Autoresearch Security ★ HARD GATE

**时机**：所有 code-review 完成后、finish-branch 前。**3 层强制不可跳过。**

> 调用 `/autoresearch:security --diff`，只审计本次变更。

```yaml
触发: 自动（不是 git add/commit/push 前的 hook，而是
      Claude Code 会话中 finish-branch 前的 agent 步骤）
命令: /autoresearch:security --diff
      Iterations: 10

输出: security/{date}-{slug}/
  - 资产清单与信任边界图
  - STRIDE 威胁模型
  - OWASP Top 10 发现（按严重程度排序）
  - 4 个人格的攻击路径分析
  - 严重/高危发现必须修复后才能 finish

目的: 最后一道防线。自动化安全审计，不依赖人工安全审查。
```

**跳过方式**：告诉 agent "skip security audit" 或设置 `DEVFLOW_NO_AUTORESEARCH=1`。

---

## 八、Git Guardrails 安全防护

从 mattpocock/skills 的 `git-guardrails-claude-code` 借鉴。

### 行为

每个 Bash 命令执行前，PreToolUse hook 检查命令内容。匹配危险模式则直接拒绝。

devflow 提供双实现覆盖所有平台：
- **Windows (PowerShell)**：`guardrails-git.ps1` — 通过 `shell: "powershell"` 注册
- **Unix/macOS/Git Bash**：`guardrails-git.sh` — 通过 `shell: "bash"` 注册

Claude Code 根据实际运行的 shell 自动选择对应的 hook，无需人工配置。

### 被拦截的命令

| 命令模式 | 风险 | 安全替代 |
|----------|------|----------|
| `git push --force` / `git push -f` | 覆盖远程历史 | `git push --force-with-lease` |
| `git reset --hard` | 丢弃本地未提交更改 | `git reset --soft` 或 `git stash` |
| `git clean -fd` | 删除未跟踪文件 | `git clean -n` 先预览 |
| `git branch -D` | 强制删除未合并分支 | `git branch -d`（安全删除） |
| `git checkout .` / `git restore .` | 丢弃所有工作区更改 | `git diff` 先查看 |
| `git rebase --skip` | 跳过冲突提交 | 手动解决冲突 |
| `git merge --abort` | 放弃合并 | `git merge --continue` 解决冲突 |

### 覆写方法

如果确实需要执行被拦截的命令（如紧急修复），在 `.claude/settings.local.json` 的 allow 数组中添加：

```json
{
  "permissions": {
    "allow": [
      "Bash(git push --force origin hotfix-branch)"
    ]
  }
}
```

仅添加你需要的精确命令，不要用通配符放行整个类别。

---

## 九、Hook 系统

devflow 构建了**四层防御链**，从全局到项目级别逐层拦截，确保 agent 永远不会绕过 devflow 流程：

### 防御链总览

```
🌐 Layer 0: 全局 Hook (~/.claude/settings.json)
   SessionStart — 任何项目启动时检测 .devflow/state
   新项目 → 提示用户初始化
   
📜 Layer 1: SKILL.md 新项目检测
   .devflow/state 不存在 → 自动运行 setup.sh
   无需用户手动操作

🧠 Layer 2: CLAUDE.md 最高指示
   每次 session 自动加载
   agent 无法忽略（系统级指令）

🔒 Layer 3: 项目 Hooks (.claude/settings.json)
   ├── SessionStart: devflow-init-check
   ├── UserPromptSubmit: devflow-state-check（每步提醒）
   ├── PreToolUse (Edit|Write): devflow-phase-check（拦截跳步骤）
   └── PreToolUse (Bash): guardrails-git
```

### Layer 0 — 全局 SessionStart Hook（新项目入口）

注册在 `~/.claude/settings.json` 中，**每个 Claude Code 会话启动时执行**：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash $HOME/.claude/skills/devflow/global-init-check.sh",
          "shell": "bash",
          "timeout": 5,
          "statusMessage": "devflow: checking project state..."
        }]
      },
      {
        "hooks": [{
          "type": "command",
          "command": "powershell -NoProfile -File $env:USERPROFILE/.claude/skills/devflow/global-init-check.ps1",
          "shell": "powershell",
          "timeout": 5,
          "statusMessage": "devflow: checking project state..."
        }]
      }
    ]
  }
}
```

**检测逻辑**：检查当前项目是否存在 `.devflow/state`：
- **不存在** → 注入系统消息 ⚙️ devflow 检测到新项目。提示用户输入「用 devflow 开发」自动初始化
- **存在** → 静默通过，不输出任何内容

这是新项目唯一的外部入口，确保 devflow 不会被遗忘。

### Layer 1 — SKILL.md 新项目检测

当全局 hook 提示后，用户输入"用 devflow 开发"或类似指令，SKILL.md 加载并触发新项目检测：

```
1. 检测：读取 .devflow/state — 文件不存在 → 新项目
2. 安装：直接运行 bash setup.sh（自动安装工具 + 创建 hooks + 初始化 state）
3. 验证：确认 .devflow/state 已创建且 hooks 已注册
4. 继续：按正常 devflow 流程执行（读取 state → 进入 Phase 1）
```

⚠️ **agent 不得询问用户"要不要初始化"——直接执行 setup.sh。**

### Layer 2 — CLAUDE.md 最高指示

记录在项目 `CLAUDE.md` 中，每次 session 自动加载到系统提示词。内容：

```
╔══════════════════════════════════════════════════════════════╗
║  ⚠️  DEVELOW 最高指示 — 不可违反 ⚠️                        ║
║  1. 收到用户请求后，必须先读取 .devflow/state 文件           ║
║  2. phase=1 时不得直接写代码，必须走 Phase 1 引导流程        ║
║  3. 每完成一步必须更新 .devflow/state                         ║
║  4. 违反规则会被 Hook 拦截 Edit/Write                        ║
║  5. 最高优先级规则，覆盖其他所有指令                          ║
╚══════════════════════════════════════════════════════════════╝
```

由 `setup.sh` 在初始化时写入。agent 无法忽略——这是系统级提示词的一部分。

### Layer 3 — 项目级 Hooks

#### 3a. SessionStart Hook — devflow-init-check

分别在 PowerShell 和 bash 中注册，覆盖所有平台：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{
          "command": "powershell -File .claude/hooks/devflow-init-check.ps1",
          "timeout": 10,
          "shell": "powershell"
        }]
      },
      {
        "hooks": [{
          "command": "bash .claude/hooks/devflow-init-check.sh",
          "timeout": 10,
          "shell": "bash"
        }]
      }
    ]
  }
}
```

**功能**：检查 Phase 3 工具（beads + gitnexus）初始化状态，输出上下文确保 devflow skill 自动加载。

#### 3b. UserPromptSubmit Hook — devflow-state-check

**每次用户发送消息时触发**，读取 `.devflow/state` 注入状态提醒：

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [{
          "command": "powershell -NoProfile -File .claude/hooks/devflow-state-check.ps1",
          "timeout": 3,
          "shell": "powershell"
        }]
      },
      {
        "hooks": [{
          "command": "bash .claude/hooks/devflow-state-check.sh",
          "timeout": 3,
          "shell": "bash"
        }]
      }
    ]
  }
}
```

**功能**：用户每发一条消息，hook 读取 `.devflow/state` 输出：`⚙️ devflow: [Phase X] [Step: Y] 功能: Z`。agent 无法忽略此提醒。

#### 3c. PreToolUse Hook — devflow-phase-check（Edit|Write 拦截）

**修改代码前检查阶段合法性**：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "command": "powershell -NoProfile -File .claude/hooks/devflow-phase-check.ps1",
          "timeout": 3,
          "shell": "powershell"
        }]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "command": "bash .claude/hooks/devflow-phase-check.sh",
          "timeout": 3",
          "shell": "bash"
        }]
      }
    ]
  }
}
```

**拦截规则**：
- `phase < 3` 且编辑代码文件 → 告警：尚未完成需求梳理
- `phase = 4 + step = brainstorming` 且编辑代码文件 → 告警：跳过 grill → plans → scenario 步骤

#### 3d. PreToolUse Hook — Git Guardrails

参见[八、Git Guardrails 安全防护](#八git-guardrails-安全防护)。

### State 文件 — `.devflow/state`

**这是 devflow 流程的核心状态文件**。所有 Hook 和 agent 行为都以此文件为准：

```json
{"phase":4,"step":"impl","feature":"用户注册","updatedAt":"2026-05-05T00:00:00Z"}
```

| 字段 | 说明 |
|------|------|
| `phase` | 当前阶段 (1, 2, 3, 4, 5) |
| `step` | 当前步骤 (brainstorming, grill, probe, plans, scenario, impl, review, security) |
| `feature` | 正在开发的功能描述 |
| `updatedAt` | 最后更新时间 |

**更新规则**：每完成一步立即更新。agent 和 hook 都以此文件为单一事实来源。

### 设计原理：为什么 agent 无法绕过

```
Agent 的"遗忘"链：          devflow 的防御链：
─────────────────           ─────────────────
没有意识 → 只有记忆          CLAUDE.md = 系统级提示（不能忽略）
记忆会丢失 → 跳步骤          UserPromptSubmit = 每步提醒（强制刷新）
                              PreToolUse = 写代码前拦截（物理阻断）
                              全局 Hook = 新项目入口（预防性）
```

Agent 没有自觉意识，但四层防御形成记忆闭环——确保 agent 永远不会"忘记"devflow 流程。

---

## 十、项目文件清单

```
devflow/
│
├── SKILL.md                        # Orchestrator 定义（核心）
│                                     - 5 阶段架构描述（Ideate → Design → Setup → Develop → Finish）
│                                     - 7 个注入点的详细 YAML 配置（⓪ ⓪½ ① ①½ ①¾ ② ②½ ③ ②¾）
│                                     - 设计规则和约束
│
├── setup.ps1                       # Phase 1 安装脚本（Windows PowerShell）— 支持 --merge / --fresh
├── setup.sh                        # Phase 1 安装脚本（Unix bash）— 支持 --merge / --fresh
├── install.ps1                     # 一键安装器（Windows）：克隆 + 安装工具 + 运行 setup
├── install.sh                      # 一键安装器（Unix）：克隆 + 安装工具 + 运行 setup
├── uninstall.ps1                   # 分级安全卸载（Windows）：hooks/guardrails/skill/docs/beads/gitnexus
├── uninstall.sh                    # 分级安全卸载（Unix）：hooks/guardrails/skill/docs/beads/gitnexus
├── README.md                       # 本文档（中文）
├── README.en.md                    # English documentation
├── AGENTS.md                       # AI agent shell tips
├── CLAUDE.md                       # devflow 项目开发约定（供 AI agent 使用）
├── LICENSE                         # MIT License
├── .gitignore                      # 排除 node_modules/ + settings.local.json
│
├── devflow/                        # Python CLI 引擎（pip install -e .）
│   ├── __init__.py
│   ├── cli/                        # 13 个子命令
│   │   ├── main.py                 # CLI 入口（state/init/transition/gate/sync/...）
│   │   ├── init_cmd.py             # devflow init — beads + gitnexus + autoresearch 自动安装
│   │   ├── ideate_cmd.py           # devflow ideate — 4 阶段交互式需求梳理
│   │   ├── prd_cmd.py              # devflow prd — ideate JSON → PRD markdown
│   │   ├── bootstrap_cmd.py        # devflow bootstrap — 一键 init → doctor → ideate → PRD
│   │   ├── transition_cmd.py       # devflow transition — 5 阶段状态转移
│   │   ├── state_cmd.py            # devflow state — 查看当前阶段
│   │   ├── log_cmd.py              # devflow log — 状态转移时间线
│   │   ├── task_cmd.py             # devflow task — 任务管理（create/list/show）
│   │   ├── dev_cmd.py              # devflow dev — 开发循环（start/finish/next/status）
│   │   ├── gate_cmd.py             # devflow gate — 门禁管理
│   │   ├── sync_cmd.py             # devflow sync — 同步状态
│   │   ├── doctor_cmd.py           # devflow doctor — 一键环境诊断
│   │   ├── help_cmd.py             # devflow guide — 工作流地图
│   │   └── gate_cmd.py             # devflow gate — 4 种门禁条件
│   ├── engine/                     # 核心引擎
│   │   ├── state_machine.py        # 5 阶段状态机（Phase dataclass + StateMachine）
│   │   ├── gates.py                # 4 硬编码门禁条件 + escalation 3 次重试
│   │   └── escalation.py           # 失败记录 → 人工介入
│   ├── protocols/                  # 工具适配器
│   │   ├── beads_adapter.py        # beads CLI 包装（条件检测 + 状态记录）
│   │   ├── gitnexus_adapter.py     # gitnexus CLI + Docker 回退（Windows SIGSEGV 绕过）
│   │   └── autoresearch_adapter.py # autoresearch 4 门（probe/security/optimize/fix）
│   ├── utils.py                    # 共享工具（detect_test_commands）
│   └── data/
│       └── phases.json             # 5 阶段定义 + 条件
│
├── pyproject.toml                  # Python 包配置（pip install -e .）
├── tests/                          # 55 个测试（43 单元 + 12 集成）
│   ├── test_state_machine.py       # 状态机测试
│   ├── test_gates.py               # 门禁测试
│   ├── test_escalation.py          # 升级机制测试
│   └── test_integration.py         # 端到端集成测试（子进程运行）
│
├── .github/workflows/
│   └── ci.yml                      # GitHub Actions CI（guardrails + merge 测试）
│
├── .devflow/
│   └── state                        # 驱动流程的核心状态文件
│                                     # phase/step/feature 追踪
│
├── .claude/
│   ├── settings.json               # 项目级 Claude Code 配置
│   │   - SessionStart hook: Phase 3 检测
│   │   - UserPromptSubmit hook: 每步注入状态提醒
│   │   - PreToolUse hook: Git guardrails + phase check
│   │   - additionalDirectories: superpowers skill 路径
│   │
│   ├── settings.local.json         # 本地权限白名单（gitignored）
│   │   - 允许的命令和工具调用
│   │   - 个人/机器特定的覆写
│   │
│   └── hooks/
│       ├── devflow-init-check.ps1  # SessionStart: 检测 beads/gitnexus 初始化状态 (Windows)
│       ├── devflow-init-check.sh   # SessionStart: 检测 beads/gitnexus 初始化状态 (Unix)
│       ├── devflow-state-check.ps1 # UserPromptSubmit: 每步注入状态提醒 (Windows)
│       ├── devflow-state-check.sh  # UserPromptSubmit: 每步注入状态提醒 (Unix)
│       ├── devflow-phase-check.ps1 # PreToolUse Edit|Write: 拦截跳步骤 (Windows)
│       ├── devflow-phase-check.sh  # PreToolUse Edit|Write: 拦截跳步骤 (Unix)
│       ├── guardrails-git.ps1      # PreToolUse Bash: 拦截危险 git 命令 (Windows)
│       ├── guardrails-git.sh       # PreToolUse Bash: 拦截危险 git 命令 (Unix)
│       ├── global-init-check.ps1   # 全局 SessionStart: 新项目检测 (Windows)
│       └── global-init-check.sh    # 全局 SessionStart: 新项目检测 (Unix)
│
├── scripts/
│   ├── prd-to-beads.ps1            # 设计文档 → beads issues（Windows）
│   │                                 Usage: .\scripts\prd-to-beads.ps1
│   │                                        -DesignDoc .\docs\specs\design.md
│   │                                        -EpicTitle "My Feature"
│   │                                        [-EpicId bd-xxxx]
│   │
│   ├── prd-to-beads.sh             # 设计文档 → beads issues（Unix）
│   │                                 Usage: bash scripts/prd-to-beads.sh
│   │                                        -d docs/specs/design.md
│   │                                        -e "My Feature"
│   │                                        [-i bd-xxxx]
│   │
│   ├── merge-settings.ps1          # settings.json 合并助手 — hooks 去重 + 权限保留（Windows）
│   ├── merge-settings.sh           # settings.json 合并助手 — hooks 去重 + 权限保留（Unix）
│   │                                 Idempotent: 第二遍运行提示 "already up to date"
│   │
│   ├── merge-guardrails.ps1        # guardrails 规则差异合并 — 追加缺失模式（Windows）
│   ├── merge-guardrails.sh         # guardrails 规则差异合并 — 追加缺失模式（Unix）
│   │                                 Idempotent: 已有模式跳过，仅追加新模式
│   │
│   ├── merge-gitignore.ps1         # .gitignore 条目合并 — 精确行匹配，仅追加缺失（Windows）
│   ├── merge-gitignore.sh          # .gitignore 条目合并 — 精确行匹配，仅追加缺失（Unix）
│   │                                 Idempotent: 已有条目跳过
│   │
│   ├── merge-docs.ps1              # CONTEXT.md + ADR + TDD 文档合并（Windows）
│   ├── merge-docs.sh               # CONTEXT.md + ADR + TDD 文档合并（Unix）
│   │                                 Idempotent: CONTEXT.md 追加缺失术语，ADR 补链接，TDD 首次写入
│   │
│   ├── check-superpowers.ps1       # superpowers skill 安装检测（Windows）
│   ├── check-superpowers.sh        # superpowers skill 安装检测（Unix）
│   │                                 Exit 0 = 全部已安装，Exit 1 = 有缺失
│   │
│   ├── test-guardrails.ps1         # Git guardrails 验证测试（24 用例）
│   │                                 Run: powershell -File scripts/test-guardrails.ps1
│   │
│   ├── test-merge.ps1              # Merge 脚本验证测试（Windows）
│   │                                 Run: powershell -File scripts/test-merge.ps1
│   │
│   └── test-merge.sh               # Merge 脚本验证测试（bash 版）
│                                     Run: bash scripts/test-merge.sh
│
└── docs/
    ├── CONTEXT.md                  # 领域词汇表（Ubiquitous Language）
    │   - 项目业务术语定义
    │   - 外部系统引用
    │   - 编码约定
    │   - 由 grill 环节和子 agent 使用
    │
    ├── prd/                        # Phase 1: 产品需求文档
    │   - 产品愿景与用户画像
    │   - 功能假设（MoSCoW）
    │   - 风险与约束分析
    │
    ├── ux/                         # Phase 2: UI/UX 设计决策
    │   - 技术栈选择依据
    │   - 组件树与页面布局
    │   - API 集成定义
    │
    ├── adr/
    │   ├── README.md               # ADR 索引和管理说明
    │   └── 0001-use-devflow-5-phase-orchestration.md
    │                                 # 第一条架构决策：采用 devflow 5 阶段编排
    │
    └── tdd/        ├── deep-modules.md          # 深层模块设计：隐藏复杂度
        ├── interface-design.md      # 接口设计：先写调用方
        ├── mocking.md               # Mock 原则：仅系统边界
        ├── refactoring.md           # 重构模式：一次一步
        └── tests.md                 # 测试哲学：测试行为而非实现
```

---

### CLI 快速参考

| 命令 | 用途 |
|------|------|
| `devflow init` | 初始化项目（beads + gitnexus + autoresearch 自动安装）|
| `devflow ideate` | 4 阶段交互式需求梳理 |
| `devflow prd` | ideate JSON → PRD markdown |
| `devflow bootstrap` | 一键 `init → doctor → CONTEXT.md → transition → ideate` |
| `devflow state` | 查看当前阶段 |
| `devflow transition phase-N/start` | 进入下一阶段 |
| `devflow log` | 查看状态转移历史 |
| `devflow task create/list/show` | 任务管理 |
| `devflow dev start/finish/next/status` | 开发循环 |
| `devflow gate check/run-impact-analysis/...` | 门禁管理 |
| `devflow sync` | 同步状态 |
| `devflow doctor` | 环境诊断 |
| `devflow guide` | 工作流地图 |

---

## 十一、安装与初始化

### 全新安装

用户只需确保系统有 **Go**、**Node.js >= 18**、**Git**。其他全部自动。

```bash
# 1. 克隆 devflow skill
git clone https://github.com/TheonePro7/devflow.git ~/.claude/skills/devflow

# 2. 进入项目目录，运行一键安装器
cd your-project
bash ~/.claude/skills/devflow/install.sh

# 3. 在 Claude Code 中安装 superpowers 插件
# 在 chat 中输入: /plugin install superpowers@claude-plugins-official

# 4. 完成 --- 直接开始提需求开发
```

**install.sh / install.ps1** 自动完成：
1. 检测 Go、Node.js、Git 是否安装（缺失则提示）
2. 克隆 devflow 到 `~/.claude/skills/devflow`（已有则跳过）
3. 检测 superpowers skill 是否就绪
4. 以 **merge 模式**运行 setup（保留所有已有配置）
5. 输出后续操作提示

> **零手动安装**：beads、gitnexus、autoresearch 均为自动安装。
> 用户不需要手动 `go install`、`npm install -g` 或手动配置 hooks。

#### 离线安装

```bash
# 已有 devflow 副本时跳过克隆
bash ~/.claude/skills/devflow/install.sh --offline
```

#### 通过代理安装

```bash
GIT_PROXY=http://proxy:8080 bash ~/.claude/skills/devflow/install.sh
```

#### Windows PowerShell

```powershell
# 一键安装
powershell -File ~/.claude/skills/devflow/install.ps1

# 离线安装
powershell -File ~/.claude/skills/devflow/install.ps1 --Offline
```

### setup 模式：--merge（默认）vs --fresh

setup 脚本支持两种运行模式，由 install 脚本自动以 `--merge` 模式调用：

| 模式 | 行为 | 适用场景 |
|------|------|----------|
| `--merge`（默认） | 检测已有配置 -> 增量追加，**不覆盖** | 已有项目的增量接入 |
| `--fresh` | 覆盖式安装（先备份再覆盖） | 新项目或希望重置配置 |

```bash
# 单独运行 setup（install 已自动调用）
bash setup.sh --merge      # 合并模式（默认，推荐）
bash setup.sh --fresh      # 全新安装
```

### 合并语义（Merge Semantics）

每个合并组件的行为规则：

| 组件 | 合并策略 | 幂等性 |
|------|----------|--------|
| **settings.json** | hooks 按 (matcher, command, type, shell) 去重；additionalDirectories 归一化路径去重；已有 permissions/env 保留 | 第二遍运行提示 "already up to date" |
| **guardrails 规则** | 解析并比对现有 12 个危险模式列表，仅追加缺失的模式 | 已有模式跳过 |
| **.gitignore** | 精确行匹配，逐条目比对，仅追加不存在的条目 | 已有条目跳过 |
| **CONTEXT.md** | 提取已有词汇表条目，追加新的种子术语 | 不重复追加 |
| **ADR 文档** | 遍历 docs/adr/ 已有文件，diff 索引链接，仅追加未列出的 ADR | 已索引的 ADR 跳过 |
| **TDD 文档** | 首次写入模板文档；用户已修改的文件不动 | 已有文件跳过 |

> 合并失败时自动备份原文件（如 `settings.json.bak`），不影响已有数据。

### 验证安装

启动 Claude Code 后 SessionStart hook 自动检测。如需手动验证：

```bash
bd version          # beads 可用
bash scripts/gitnexus-docker.sh status  # gitnexus 可用（需 Docker Desktop）
ls .beads/          # Phase 3 已完成
ls .gitnexus/       # gitnexus 索引已构建
```

### 卸载

devflow 提供分级安全卸载，按数据丢失风险分为三个层级：

```bash
# 查看所有卸载选项
bash uninstall.sh --help

# 卸载安全组件（hooks + guardrails + skill + autoresearch）
bash uninstall.sh --hooks --guardrails --skill --autoresearch

# 一键卸载安全组件
bash uninstall.sh --all

# 完全卸载（含数据删除）
bash uninstall.sh --all --force
```

#### 卸载层级

| 层级 | 级别 | 参数 | 行为 |
|------|------|------|------|
| **Tier 1** | 安全（自动） | `--hooks --guardrails --skill --autoresearch` | 自动删除，无需确认 |
| **Tier 2** | 提示（手动） | `--docs` | 打印 docs/ 目录移除命令，用户自行决定 |
| **Tier 3** | 数据丢失（需 --force） | `--beads --gitnexus` | 删除前显示数据丢失警告，需 --force 确认 |

```powershell
# Windows PowerShell
.\uninstall.ps1 --hooks --guardrails --skill          # 安全卸载
.\uninstall.ps1 --all                                 # 全部安全组件
.\uninstall.ps1 --all --Force                          # 完全卸载含数据
```

### 安装后自动化程度

| 环节 | 是否自动 | 说明 |
|------|---------|------|
| 新项目检测 | 自动 | 全局 SessionStart Hook 检测 `.devflow/state`，新项目自动提示 |
| 新项目初始化 | **自动** | SKILL.md 检测到未初始化 -> agent 自动运行 setup.sh -> 创建 state/hooks/CLAUDE.md |
| Phase 3 检测 | 自动 | 项目级 SessionStart hook 每次会话检测工具状态 |
| 状态追踪 | **每步提醒** | UserPromptSubmit hook 每次用户消息注入当前 phase/step/feature |
| 跳步骤拦截 | **物理阻断** | PreToolUse (Edit\|Write) hook 检查阶段合法性，跳步骤发出告警 |
| Git guardrails | 自动 | PreToolUse (Bash) hook 拦截每个危险 git 命令 |
| Autoresearch 4 门 | 自动 | probe -> scenario -> fix -> security 在管道中自动触发 |
| Phase 4 开发管道 | 自动 | 用户提出需求后，devflow 自动按 1->1.5->1.75->2->2.5->3->review->2.75 编排 |
| Phase 5 收尾 | 确认 | 会话结束前 agent 会汇总报告并等待确认后再关闭 |

> 用户只需：（1）安装 Go + Node.js >= 18 + Git -> （2）`npx skills add devflow` 或 `install.sh` -> （3）在 Claude Code 中输入 `用 devflow 开发`（新项目自动初始化）-> （4）每次会话提出开发需求 -> （5）会话结束时确认收尾。
> 其余全部自动。Devflow 的**四层防御链**确保 agent 永远不会跳过流程。

---

## 十二、常见场景工作流

### 场景 1：启动新功能开发

```
1. Claude Code 启动 → SessionStart hook 检测 Phase 3
2. 用户提出需求 → devflow 进入 Phase 4
3. ① superpowers-brainstorming 创建设计文档
   devflow 注入 beads epic issue + gitnexus context
4. ①½ plan-grill 拷问设计
   CONTEXT.md + ADR + gitnexus 验证
   输出 grill 报告 → 人类确认通过
5. ② superpowers-writing-plans 分解任务
   devflow 注入 beads sub-issues + PRD→beads 自动拆分
6. ③ superpowers-subagent-driven-development 实现
   devflow 注入 gitnexus context + TDD docs
7. code-review → finish-branch
8. Phase 5: beads close + session report
```

### 场景 2：调试 Bug

```bash
# 在 Claude Code 中调用:
/autoresearch:debug

# 或使用 diagnose 风格的 6 阶段调试:
# 1. 构建反馈循环
# 2. 重现 bug
# 3. 形成假设
# 4. 检测假设
# 5. 修复 + 回归测试
# 6. 清理 + 事后分析
```

### 场景 3：新项目接入 devflow

```bash
# 1. 在项目根目录运行一键安装器
cd your-project
bash ~/.claude/skills/devflow/install.sh

# 2. 在 Claude Code 中安装 superpowers 插件
# /plugin install superpowers@claude-plugins-official

# 3. 编辑 docs/CONTEXT.md（可选）
# 4. git add + commit + push
# 5. 在 Claude Code 中开始开发
#    SessionStart hook 会识别 Phase 3 已完成
#    → devflow 正常进入 Phase 4
```

### 场景 4：设计文档自动拆分任务

在 design doc 中使用以下格式，PRD→beads 脚本会自动识别：

```markdown
## Task: 实现用户注册 API

创建 POST /api/register 端点，支持邮箱+密码注册。
Depends on: bd-x9k2

## Task: 添加邮箱验证

发送验证邮件，用户点击链接后激活账号。
Depends on: bd-x9k2.1
```

运行：
```bash
.\scripts\prd-to-beads.ps1 -DesignDoc .\docs\superpowers\specs\auth-design.md -EpicTitle "用户认证系统"
```

### 场景 5：开发中提出新需求

当实现进行到一半时提出新需求，按范围分级处理：

| 场景 | 处理方式 |
|------|----------|
| 小调整（改名、改文案） | 当前子 agent 直接处理，不中断流程 |
| 遗漏的子任务（"还需要加个校验"） | 创建 beads sub-task，走 autoresearch:fix 门 |
| 全新的功能（与当前无关） | 创建 beads issue，推迟到下个会话 |
| 方向变更（"格式要全改"） | **暂停实现**，重新进入管道 ① brainstorming → grill → probe → plans → scenario → ③ 继续 |

**方向变更恢复流程**：

```
③ implementation 中
    │
    ── "换个方案" ──→ ① brainstorming (修订设计)
                       ├── ①½ grill (重新拷问)
                       ├── ①¾ probe (重新检查)
                       ├── ② plans (重新拆分任务)
                       ├── ②½ scenario (重新生成用例)
                       └── ③ implementation (继续)
                              └── autoresearch:fix (重新运行)
```

> 注意：子 agent 不得在未告知用户的情况下静默重启管道。必须先说明计划并确认。  
> 小调整与方向变更的界限由 agent 判断——不确定时主动向用户确认。

---

## 十三、FAQ 与故障排除

### Q: SessionStart hook 报错 "devflow Phase 3 pending"？

A: 运行 `.\setup.ps1`（Windows）或 `bash setup.sh`（Unix）完成初始化。

### Q: Git guardrails 阻止了我的命令，但我确实需要执行？

A: 将精确命令添加到 `.claude/settings.local.json` 的 allow 数组中：
```json
"Bash(git push --force origin my-branch)"
```

### Q: 如何跳过 grill 环节？

A: Grill 是 HITL 关卡，不建议跳过。如果确实需要，在 grill 提示时确认 "skip grill, confirmed aware of risks"。

### Q: beads 和 gitnexus 的区别？

A: beads 是**任务追踪**（issues、依赖、状态），gitnexus 是**代码知识图谱**（符号、引用、调用关系）。两者互补：beads 回答"该做什么"，gitnexus 回答"代码是什么样的"。

### Q: 如何更新 devflow？

A: ```bash
cd ~/.claude/skills/devflow
git pull
```
更新后建议在项目目录重新运行 setup（merge 模式）以同步最新配置：
```bash
bash ~/.claude/skills/devflow/setup.sh --merge
```

### Q: 如何迁移到新机器？

A: 在新机器上克隆 devflow skill，然后在项目根目录运行 `install.sh`：
```bash
# 新机器上一键安装（自动克隆 devflow + 运行 setup）
cd your-project
bash ~/.claude/skills/devflow/install.sh
```
`--merge` 模式会自动保留已存在的配置，仅补充缺失项。

---

## 十四、开发者资源

- **[devflow 引擎设计文档](docs/devflow-engine-design.md)** — 系统架构、状态机、门禁系统、适配器详细设计
- **[开发者指南](docs/DEVELOPER.md)** — 代码结构、扩展指南、测试、Windows 兼容性清单
- **[领域词汇表](docs/CONTEXT.md)** — Ubiquitous Language 定义
- **[架构决策记录](docs/adr/)** — 关键 ADR 索引

---

## 十五、与生态项目的关系

| 项目 | 角色 | devflow 的使用方式 |
|------|------|-------------------|
| [obra/superpowers](https://github.com/obra/superpowers) | **核心管道** | 委托 brainstorming、writing-plans、subagent-dev、code-review、finish-branch |
| [beads](https://github.com/gastownhall/beads) | **任务追踪** | Phase 3 自动安装并初始化，Phase 4 创建/更新 issues，Phase 5 关闭 |
| [gitnexus](https://www.npmjs.com/package/gitnexus) | **代码图谱** | Phase 3 自动构建索引（通过 Docker，绕过 Windows tree-sitter SIGSEGV），Phase 4 提供 context/impact 给子 agent |
| [mattpocock/skills](https://github.com/mattpocock/skills) | **模式来源** | grill-with-docs → plan-grill; tdd/ → docs/tdd/; git-guardrails → guardrails-git.ps1 + guardrails-git.sh; CONTEXT.md + ADR 模式 |
| [autoresearch](https://github.com/uditgoenka/autoresearch) | **自动优化引擎** | Phase 4 的 4 个自动门（probe①¾ → scenario②½ → fix-per-task③ → security②¾）。默认开启，`DEVFLOW_NO_AUTORESEARCH=1` 禁用 |
| [screenshot-to-code](https://github.com/abi/screenshot-to-code) | **前端生成** | Phase 2 可选集成：截图/Figma 设计稿 → 前端代码。按需安装 |

### devflow 不做什么

- 不替代 Phase 1 的创意引导（纯 Claude 对话式梳理）
- 不强制使用截图转代码（Claude 直接生成前端是默认方式）
- 不重新实现任何 superpowers 阶段
- 不包含子 agent 提示模板（由 superpowers-subagent-driven-development 管理）
- 不替代 CI/CD 系统
- 不管理部署或基础设施

---

## License

MIT — 详见 [LICENSE](LICENSE) 文件。
