# devflow

**Claude Code 开发工作流编排器 — 3 阶段（Setup → Develop → Finish）增强 superpowers 管道 + 4 个自动 autoresearch 优化门**

devflow 是一个轻量级 orchestrator skill，包装 [obra/superpowers](https://github.com/obra/superpowers) 的 14-skill 管道，注入 **beads 任务追踪**、**gitnexus 代码图谱**、**autoresearch 自动优化**（4 个自动门：probe → scenario → fix → security）、**plan-grill 拷问**、**PRD→beads 自动拆分**、**TDD 深度参考**六大工具。同时从 [mattpocock/skills](https://github.com/mattpocock/skills) 吸收了 Git guardrails、领域词汇表 (CONTEXT.md) 和架构决策记录 (ADR) 等模式。

---

## 目录

- [一、核心架构](#一核心架构)
- [二、Phase 1：项目初始化（Setup）](#二phase-1项目初始化setup)
- [三、Phase 2：开发循环（Develop）](#三phase-2开发循环develop)
- [四、Phase 3：会话收尾（Finish）](#四phase-3会话收尾finish)
- [五、工具注入详解](#五工具注入详解)
- [六、Git Guardrails 安全防护](#六git-guardrails-安全防护)
- [七、Hook 系统](#七hook-系统)
- [八、项目文件清单](#八项目文件清单)
- [九、安装与初始化](#九安装与初始化)
- [十、常见场景工作流](#十常见场景工作流)
- [十一、FAQ 与故障排除](#十一faq-与故障排除)
- [十二、与生态项目的关系](#十二与生态项目的关系)

---

## 一、核心架构

devflow 采用 3 阶段架构，每个阶段有明确的职责边界：

```
                     devflow (orchestrator)
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
        Phase 1         Phase 2         Phase 3
        Setup           Develop         Finish
                            │
                    ┌───────┴───────┐
                    │               │
               superpowers      autoresearch
               pipeline         auto-injected
                                    │
                           ┌────────┴────────┐
                           │    │       │    │
                          probe scenario fix security
                           ①¾    ②½   ③   ②¾
```

### 设计原则

| 原则 | 说明 |
|------|------|
| **不重写 superpowers** | devflow 不做 superpowers 已做的事。Brainstorming、writing-plans、subagent-dev、code-review、finish-branch 全部委托给 superpowers-* |
| **工具注入** | devflow 的价值在于在 superpowers 管道的定义点注入 beads、gitnexus、grill 等工具 |
| **硬关卡** | Phase 1 未完成不能进入 Phase 2。Plan-grill 未通过不能进入 writing-plans |
| **HITL 优先** | Grill 拷问、Phase 3 报告需要人类确认。自动化不跳过判断 |
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

## 二、Phase 1：项目初始化（Setup）

**触发条件**：SessionStart hook 检测到 `.beads/` 或 `.gitnexus/` 缺失。

### 执行流程

```
SessionStart hook
  │
  ├── 检测 bd 是否安装
  ├── 检测 gitnexus 是否安装
  ├── 检测 .beads/ 是否存在
  └── 检测 .gitnexus/ 是否存在
        │
        如果任一缺失 → 输出:
          systemMessage: "devflow: Phase 1 setup needed..."
          additionalContext: "devflow Phase 1 pending — ..."
        │
        SKILL.md 匹配触发关键词 → 提示用户运行 setup
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
| 3 | `gitnexus analyze . --force` 构建代码图谱 | 提示手动重试 |
| 4 | 创建 `docs/CONTEXT.md`（如果不存在） | 已有则跳过 |
| 5 | 创建 `docs/adr/` + README.md（如果不存在） | 已有则跳过 |
| 6 | 创建 `docs/tdd/` 目录（如果不存在） | 已有则跳过 |
| 7 | 安装 autoresearch（`npx skills add uditgoenka/autoresearch`） | 失败则警告，可跳过: `DEVFLOW_NO_AUTORESEARCH=1` |
| 8 | 检查 `.claude/hooks/guardrails-git.ps1` | 缺失则警告 |

### Phase 1 产物

```
./beads/              # beads 本地仓库
./gitnexus/           # gitnexus 代码图谱索引
docs/CONTEXT.md       # 领域词汇表模板（需手动填充）
docs/adr/README.md    # 架构决策记录目录
docs/tdd/             # TDD 深度参考文档目录
```

---

## 三、Phase 2：开发循环（Develop）

**每个开发任务的会话循环**。这是 devflow 的核心阶段。

### 完整管道

```
用户提出需求
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ① superpowers-brainstorming                     │
│   devflow 注入: beads epic + gitnexus context   │
│   + CONTEXT.md                                  │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ①½ PLAN-GRILL (HITL 关卡)                       │
│   用 CONTEXT.md + ADR + gitnexus 拷问计划       │
│   发现盲点 → 更新 CONTEXT.md → 确认通过        │
│   不通过则返回 brainstorming                    │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ①¾ AUTORESEARCH PROBE ★ 自动                    │
│   /autoresearch:probe                           │
│   8 个对抗人格发现隐藏约束和矛盾                │
│   输出约束报告 → 补充到 plans                   │
│   跳过: DEVFLOW_NO_AUTORESEARCH=1               │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ② superpowers-writing-plans                     │
│   devflow 注入: beads sub-issues + gitnexus     │
│   impact + PRD→beads 自动拆分                   │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ②½ AUTORESEARCH SCENARIO ★ 自动                 │
│   /autoresearch:scenario                        │
│   为每个任务生成边界案例和错误状态              │
│   输出测试场景 → 补充 task 描述                 │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ③ superpowers-subagent-driven-development       │
│   devflow 注入: gitnexus context + beads ready  │
│   + TDD deep docs                               │
│   ┌─ 每个任务完成后 ──────────────────────┐     │
│   │ ★ AUTORESEARCH:FIX 零错误门           │     │
│   │ /autoresearch:fix --target "npm test" │     │
│   │ 通过后才 claim 下一个任务              │     │
│   └────────────────────────────────────────┘     │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ superpowers-requesting-code-review              │
│ (devflow 不参与)                                │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ ②¾ AUTORESEARCH SECURITY ★ 自动                 │
│   /autoresearch:security --diff                 │
│   STRIDE + OWASP Top10 + 红队审计              │
│   Critical/High 必须修复才能 finish             │
├─────────────────────────────────────────────────┤
    │
    ▼
┌─────────────────────────────────────────────────┐
│ superpowers-finishing-a-development-branch      │
│ (devflow 不参与)                                │
└─────────────────────────────────────────────────┘

后台运行: Git guardrails PreToolUse hook
```

### Grill 关卡详解

Plan-grill 是 devflow 从 mattpocock/skills 的 `grill-with-docs` 借鉴的核心模式。它位于 brainstorming 之后、writing-plans 之前，是一个**必须的人工确认关卡**。

**执行步骤**：

1. **词汇验证** — 读取 `docs/CONTEXT.md`，检查设计文档中的所有术语是否已定义。缺失的术语补充到 CONTEXT.md。
2. **ADR 一致性检查** — 读取 `docs/adr/`，检查设计是否与已有架构决策冲突。冲突时标记并建议方案。
3. **代码事实验证** — 使用 `gitnexus context <symbol>` 验证设计中引用的代码符号是否存在、接口是否匹配。
4. **依赖阻塞检查** — 使用 `bd dep check` 或 `bd ready` 检查是否有阻塞依赖未解决。
5. **边界案例发明** — 主动找出设计中未覆盖的边界输入、错误状态、并发访问场景等。
6. **输出拷问报告** — 写入 `docs/superpowers/specs/<design>-grill-report.md`，包含：术语修改记录、发现的盲点及解决方案、与 ADR 的一致性确认。

**产出物**：
- 更新后的 `docs/CONTEXT.md`
- 新增 `docs/superpowers/specs/<design>-grill-report.md`
- 明确的 "通过" / "返回修改" 决策

---

## 四、Phase 3：会话收尾（Finish）

**每个开发会话结束时执行**。

### 执行内容

1. **beads close** — 关闭当前会话中创建或更新的所有 beads issues
   - `bd update <id> --close` (已完成的任务)
   - `bd update <id> --status=wontfix` (不实施的任务)
2. **Session report** — 生成会话摘要
   - 完成的任务列表
   - 未完成的任务及原因
   - 新建或更新的 docs/ 文件
   - 建议的后续步骤

---

## 五、工具注入详解

### ① — Brainstorming 注入

**时机**：`superpowers-brainstorming` 运行前。

```yaml
beads:
  - 命令: bd create --title="<feature>" --type=epic
  - 作用: 将特性创建为可追踪的一级 issue，后续子任务可以挂载

gitnexus:
  - 命令: gitnexus context <key-symbol>
  - 作用: 预取相关代码的上下文（类型定义、接口、调用链），
          喂给 brainstorming 子 agent，避免其在缺乏代码知识
          的情况下做设计

context:
  - 加载 docs/CONTEXT.md，让子 agent 了解领域词汇
  - 加载 docs/adr/，让子 agent 了解过去的架构决策
```

### ①½ — Grill 注入

**时机**：brainstorming 产出设计文档后，writing-plans 分解任务前。

参见[第三节 Grill 关卡详解](#grill-关卡详解)。

### ①¾ — Autoresearch Probe 注入 ★ 自动

**时机**：grill 通过后、writing-plans 前。默认自动执行。

> 调用 `/autoresearch:probe`，8 个对抗人格（架构师、安全分析师、
> 性能工程师、可靠性工程师、魔鬼代言人等）独立分析设计后辩论达成共识。

```yaml
触发: 自动（DEVFLOW_NO_AUTORESEARCH 未设置时）
命令: /autoresearch:probe --chain plan,autoresearch
      Topic: "<feature-title>"

输出: probe/{date}-{slug}/
  - spec.md              — 细化后的需求规约
  - constraints.tsv      — 发现的约束条件
  - contradictions.md    — 需求中的矛盾点
  - assumptions.md       — 被挑战的假设
  - handoff.json         — 传给 writing-plans 的结构化数据

目的: 人工 grill 找明显盲点，autoresearch:probe 找深层隐藏约束。
      两者互补，确保 plans 基于完整的需求理解。
```

**跳过方式**：告诉 agent "skip probe" 或设置 `DEVFLOW_NO_AUTORESEARCH=1`。

### ②½ — Autoresearch Scenario 注入 ★ 自动

**时机**：writing-plans 分解任务后、implementation 前。默认自动执行。

> 调用 `/autoresearch:scenario`，沿 12 个维度生成边界案例。

```yaml
触发: 自动
命令: /autoresearch:scenario
      Scenario: "<task-title>"
      Iterations: 15
      Focus: edge-cases

输出: scenario/{date}-{slug}/
  - 每个任务的边界条件、错误状态、异常流
  - 附加到 beads task 描述中，子 agent 实现时直接使用

维度: happy path, error, edge case, abuse, scale, concurrency,
      temporal, data variation, permissions, integration, recovery,
      state transition
```

**跳过方式**：告诉 agent "skip scenario"。

### ② — Writing Plans 注入

**时机**：计划分解为任务后，每个任务开始前。

```yaml
beads:
  - bd create --title="<task>" --parent=<epic_id> --type=task
  - bd dep add <task_id> <dependency_id>
  - 任务 ID 层级化: bd-xxx.1, bd-xxx.1.1, ...

gitnexus:
  - gitnexus impact <symbol> --depth 2
  - 分析变更的"爆炸半径"（影响范围），注入计划上下文

auto-split (PRD→beads):
  - 如果设计文档包含 "## Task:" 标题，自动运行:
    scripts/prd-to-beads.ps1 -d ./docs/superpowers/specs/<design>.md -e "<title>" -i <epic_id>
  - 或 bash: bash scripts/prd-to-beads.sh -d ... -e ... -i ...
  - 每个 task 创建为一个 beads issue，自动设置 Depends on 关系
```

### ③ — Implementation 注入

**时机**：`superpowers-subagent-driven-development` 执行期间。

```yaml
gitnexus:
  - 主 agent 预取 gitnexus context 传给 implementer/spec-reviewer/quality-reviewer
  - 子 agent 不直接运行 gitnexus（避免重复调用和权限问题）

beads:
  - bd ready: 检查阻塞任务是否完成，防止在依赖未就绪时开始工作
  - bd update <id> --claim: 原子地分配任务，避免多人冲突

tdd-deep-docs:
  - TDD 模式下引用 docs/tdd/*.md:
    - deep-modules.md     — 用简单接口隐藏复杂实现
    - interface-design.md — 为调用者设计契约优先
    - mocking.md          — 仅在系统边界使用 mock
    - refactoring.md      — 一次只做一步重构
    - tests.md            — 测试行为而非实现

autoresearch:fix — 每个任务完成后的零错误门:
  - 每个任务完成后，claim 下一个任务前自动运行:
    /autoresearch:fix --target "npm run build && npm test"
  - :fix 会迭代修复直到错误数为零
  - 通过后才允许 claim 下一个任务
  - 跳过方式: 告诉 agent "skip fix gate"
```

### ②¾ — Autoresearch Security 注入 ★ 自动

**时机**：code-review 完成后、finish-branch 前。默认自动执行。

> 调用 `/autoresearch:security --diff`，只审计本次变更的文件。

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

## 六、Git Guardrails 安全防护

从 mattpocock/skills 的 `git-guardrails-claude-code` 借鉴。

### 行为

每个 Bash 命令执行前，PreToolUse hook 检查命令内容。匹配危险模式则直接拒绝。

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

## 七、Hook 系统

devflow 注册了两个 Claude Code hooks：

### SessionStart Hook

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "powershell -File .claude/hooks/devflow-init-check.ps1",
          "timeout": 10,
          "shell": "powershell",
          "statusMessage": "devflow: checking project state..."
        }]
      }
    ]
  }
}
```

**功能**：每次 Claude Code 会话启动时自动运行，检查 Phase 1 是否完成。如果 `.beads/` 或 `.gitnexus/` 缺失，输出警告并提示运行 setup。

### PreToolUse Hook (Git Guardrails)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "powershell -NoProfile -File .claude/hooks/guardrails-git.ps1",
          "timeout": 5,
          "shell": "powershell",
          "statusMessage": "devflow: checking git safety..."
        }]
      }
    ]
  }
}
```

**功能**：每个 Bash 命令执行前检查是否为危险 git 操作，是则拒绝并给出提示。

### Hook 输出注入机制

SessionStart hook 的输出 JSON 中，`systemMessage` 字段的内容会显示在 Claude Code UI 中，`hookSpecificOutput.additionalContext` 会注入到模型上下文。devflow 的 SKILL.md 描述包含了与 hook 输出匹配的关键词，因此 hook 检测到 Phase 1 未完成时，devflow skill 会自动被加载。

---

## 八、项目文件清单

```
devflow/
│
├── SKILL.md                        # Orchestrator 定义（核心）
│                                     - 3 阶段架构描述
│                                     - 5 个注入点的详细 YAML 配置
│                                     - 设计规则和约束
│
├── setup.ps1                       # Phase 1 安装脚本（Windows PowerShell）
├── setup.sh                        # Phase 1 安装脚本（Unix bash）
├── README.md                       # 本文档
├── LICENSE                         # MIT License
├── .gitignore                      # 排除 node_modules/ + settings.local.json
│
├── .claude/
│   ├── settings.json               # 项目级 Claude Code 配置
│   │   - SessionStart hook: Phase 1 检测
│   │   - PreToolUse hook: Git guardrails
│   │   - additionalDirectories: superpowers skill 路径
│   │
│   ├── settings.local.json         # 本地权限白名单（gitignored）
│   │   - 允许的命令和工具调用
│   │   - 个人/机器特定的覆写
│   │
│   └── hooks/
│       ├── devflow-init-check.ps1  # SessionStart: 检测 beads/gitnexus 初始化状态
│       └── guardrails-git.ps1      # PreToolUse: 检测并拦截危险 git 命令
│
├── scripts/
│   ├── prd-to-beads.ps1            # 设计文档 → beads issues（Windows）
│   │                                 Usage: .\scripts\prd-to-beads.ps1
│   │                                        -DesignDoc .\docs\specs\design.md
│   │                                        -EpicTitle "My Feature"
│   │                                        [-EpicId bd-xxxx]
│   │
│   └── prd-to-beads.sh             # 设计文档 → beads issues（Unix）
│                                     Usage: bash scripts/prd-to-beads.sh
│                                              -d docs/specs/design.md
│                                              -e "My Feature"
│                                              [-i bd-xxxx]
│
├── docs/
│   ├── CONTEXT.md                  # 领域词汇表（Ubiquitous Language）
│   │   - 项目业务术语定义
│   │   - 外部系统引用
│   │   - 编码约定
│   │   - 由 grill 环节和子 agent 使用
│   │
│   ├── adr/
│   │   ├── README.md               # ADR 索引和管理说明
│   │   └── 0001-use-devflow-3-phase-orchestration.md
│   │                                 # 第一条架构决策：采用 devflow 3 阶段编排
│   │
│   └── tdd/
│       ├── deep-modules.md          # 深层模块设计：隐藏复杂度
│       ├── interface-design.md      # 接口设计：先写调用方
│       ├── mocking.md               # Mock 原则：仅系统边界
│       ├── refactoring.md           # 重构模式：一次一步
│       └── tests.md                 # 测试哲学：测试行为而非实现
│
└── docs/superpowers/
    └── specs/                       # superpowers 设计文档存档
        ├── <design-name>.md         # brainstorming 产出的设计文档
        └── <design-name>-grill-report.md  # grill 环节产出的拷问报告
```

---

## 九、安装与初始化

### 全新安装

```bash
# 1. 安装前置全局工具
npm install -g gitnexus
go install github.com/gastownhall/beads/cmd/bd@latest

# 2. 在 Claude Code 中安装 superpowers
#    在 chat 中输入:
/plugin install superpowers@claude-plugins-official

# 3. 安装 devflow skill
git clone https://github.com/TheonePro7/devflow.git ~/.claude/skills/devflow

# 4. 进入项目目录，运行 Phase 1 初始化
#    (会自动安装 autoresearch)
cd your-project
# PowerShell:
.\setup.ps1
# 或 bash:
# bash setup.sh

# 如需跳过 autoresearch 安装:
# $env:DEVFLOW_NO_AUTORESEARCH=1; .\setup.ps1   (PowerShell)
# export DEVFLOW_NO_AUTORESEARCH=1; bash setup.sh (bash)
```

# 5. 进入你的项目目录
cd your-project

# 6. 运行 Phase 1 初始化
# PowerShell:
.\setup.ps1
# 或 bash:
# bash setup.sh

# 7. 编辑 docs/CONTEXT.md，填充项目领域术语
#    编辑 docs/adr/，记录重要架构决策

# 8. 开始开发（在 Claude Code 中）
#    SessionStart hook 会检测 Phase 1 状态，
#    一切就绪后即可进入 Phase 2 开发循环
```

### 验证安装

运行以下命令确认所有组件正常工作：

```bash
bd version          # 确认 beads 可用
gitnexus --version  # 确认 gitnexus 可用
ls .beads/          # 确认 Phase 1 已完成
ls .gitnexus/       # 确认 gitnexus 索引已构建
```

---

## 十、常见场景工作流

### 场景 1：启动新功能开发

```
1. Claude Code 启动 → SessionStart hook 检测 Phase 1
2. 用户提出需求 → devflow 进入 Phase 2
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
8. Phase 3: beads close + session report
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
# 1. 安装依赖 + devflow skill
# 2. 运行 setup.ps1
# 3. 编辑 docs/CONTEXT.md
# 4. git add + commit + push
# 5. 在 Claude Code 中开始开发
#    SessionStart hook 会识别 Phase 1 已完成
#    → devflow 正常进入 Phase 2
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

---

## 十一、FAQ 与故障排除

### Q: SessionStart hook 报错 "devflow Phase 1 pending"？

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

### Q: 如何迁移到新机器？

A: 克隆 devflow skill，在新项目的项目根目录运行 setup.ps1。`.claude/settings.json` 和 hooks 需要重新配置（或从旧项目复制）。

---

## 十二、与生态项目的关系

| 项目 | 角色 | devflow 的使用方式 |
|------|------|-------------------|
| [obra/superpowers](https://github.com/obra/superpowers) | **核心管道** | 委托 brainstorming、writing-plans、subagent-dev、code-review、finish-branch |
| [beads](https://github.com/gastownhall/beads) | **任务追踪** | Phase 1 初始化，Phase 2 创建/更新 issues，Phase 3 关闭 |
| [gitnexus](https://www.npmjs.com/package/gitnexus) | **代码图谱** | Phase 1 构建索引，Phase 2 提供 context/impact 给子 agent |
| [mattpocock/skills](https://github.com/mattpocock/skills) | **模式来源** | grill-with-docs → plan-grill; tdd/ → docs/tdd/; git-guardrails → guardrails-git; CONTEXT.md + ADR 模式 |
| [autoresearch](https://github.com/uditgoenka/autoresearch) | **自动优化引擎** | Phase 2 的 4 个自动门（probe①¾ → scenario②½ → fix-per-task③ → security②¾）。默认开启，`DEVFLOW_NO_AUTORESEARCH=1` 禁用 |

### devflow 不做什么

- 不重新实现任何 superpowers 阶段
- 不包含子 agent 提示模板（由 superpowers-subagent-driven-development 管理）
- 不替代 CI/CD 系统
- 不管理部署或基础设施

---

## License

MIT — 详见 [LICENSE](LICENSE) 文件。
