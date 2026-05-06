# mattpocock/skills — 深度分析

## 概述

**Matt Pocock 的"给真正工程师的技能集"** — 一组为 Claude Code 和 Codex 设计的可组合代理技能。旨在替代重型框架（GSD、BMAD、Spec-Kit），强调小巧、可适应、适用于任何模型的技能。

- **安装：** `npx skills@latest add mattpocock/skills`
- **配置：** 运行 `/setup-matt-pocock-skills` 来配置问题跟踪器、分类标签和文档位置
- **资讯：** aihero.dev/s/skills-newsletter（约 60,000 订阅者）

## 四大核心问题及其解决方案

| 问题 | 解决方案 | 技能 |
|------|---------|------|
| 代理没按你想要的做 | 拷问式对话 — 代理在开始前详细提问 | `/grill-me`、`/grill-with-docs` |
| 代理话太多 | 共享语言文档（CONTEXT.md） | 内置于 `/grill-with-docs` |
| 代码跑不起来 | 通过 TDD 和调试建立反馈循环 | `/tdd`、`/diagnose` |
| 架构腐化（大泥球） | 有意识的设计聚焦 | `/to-prd`、`/zoom-out`、`/improve-codebase-architecture` |

## 完整技能清单

### 工程技能（10 个技能）

#### 1. `/diagnose`
- **描述：** 针对顽固 Bug 和性能回归的规范诊断循环
- **文件：** `skills/engineering/diagnose/SKILL.md`（7,163 字节）
- **子目录：** `scripts/`
- **6 阶段方法：**
  1. **构建反馈循环** — 快速、确定性强、可代理运行的通过/未通过信号
     - 10 种策略：失败测试、curl/HTTP 脚本、带夹具的 CLI 调用、无头浏览器脚本、重放跟踪、一次性脚手架、属性/模糊测试循环、二分测试脚手架、差分循环、人在回路中的 bash 脚本
     - 迭代优化速度、信号清晰度、确定性
     - 如果无法构建，停下来询问用户授权/权限
  2. **复现** — 确认循环能在多次运行中稳定复现用户描述的失败
  3. **提出假设** — 在测试任何假设之前，生成 3-5 个排序的、可证伪的假设
  4. **插桩** — 一次只变一个变量，带唯一前缀的标记调试日志（`[DEBUG-a4f2]`）
  5. **修复 + 回归测试** — 在修复之前先写回归测试（如果存在正确的 seam）
  6. **清理 + 事后复盘** — 移除插桩代码、删除原型、记录本可预防该 Bug 的措施

#### 2. `/grill-with-docs`
- **描述：** 拷问式对话，针对现有领域模型挑战方案，精炼术语，并实时更新 CONTEXT.md 和 ADR
- **文件：** `skills/engineering/grill-with-docs/SKILL.md`（3,552 字节）
- **辅助文件：**
  - `CONTEXT-FORMAT.md`（3,145 字节）— CONTEXT.md 模板和规则
  - `ADR-FORMAT.md`（2,766 字节）— ADR 模板和规则
- **流程：**
  - 一个接一个问题，持续追问
  - 对照 CONTEXT.md 中的术语表进行挑战
  - 用精确的标准术语打磨模糊语言
  - 讨论具体场景，探究边界情况
  - 与代码交叉引用
  - 术语确认后实时更新 CONTEXT.md
  - 谨慎引入 ADR（仅在以下情况：难以逆转、脱离上下文会令人费解、真实权衡的结果）

#### 3. `/triage`
- **描述：** 通过由分类角色驱动的状态机对问题进行分类
- **文件：** `skills/engineering/triage/SKILL.md`
- **两个类别角色：** `bug`（缺陷）、`enhancement`（增强）
- **五个状态角色：** `needs-triage`（需分类）、`needs-info`（需信息）、`ready-for-agent`（可交代理）、`ready-for-human`（需人工处理）、`wontfix`（不修复）
- **流程：** 收集上下文 -> 给出建议 -> 复现（仅限缺陷）-> 拷问（如需）-> 执行结果
- **结果操作：**
  - `ready-for-agent`：发布代理简要说明
  - `ready-for-human`：类似简要说明，但注明为何不能委派
  - `needs-info`：按模板发布分类说明
  - `wontfix`（缺陷）：礼貌解释后关闭
  - `wontfix`（增强）：写入 `.out-of-scope/`，附链接，关闭

#### 4. `/improve-codebase-architecture`
- **描述：** 在代码库中发现可深化的机会，以 CONTEXT.md 语言和 ADR 为指引
- **文件：** `skills/engineering/improve-codebase-architecture/SKILL.md`（5,140 字节）
- **辅助文件：**
  - `DEEPENING.md`（2,565 字节）
  - `INTERFACE-DESIGN.md`（2,725 字节）
  - `LANGUAGE.md`（3,804 字节）— 架构术语表
- **关键术语表（来自 LANGUAGE.md）：**
  - **模块（Module）** — 任何有接口 + 实现的东西
  - **接口（Interface）** — 调用方需要知道的一切（类型、不变量、错误模式、排序、配置）
  - **深度（Depth）** — 接口处提供的杠杆效应（深 = 高杠杆）
  - ** seam ** — 接口所在的位置
  - **适配器（Adapter）** — 在 seam 处满足接口的具体实现
  - **删除测试（Deletion test）** — 如果删除模块后复杂性消失，说明它只是透传
  - **一个适配器 = 假设性 seam，两个适配器 = 真实的 seam**
- **流程：** 探索 -> 提出候选方案 -> 拷问循环

#### 5. `/setup-matt-pocock-skills`
- **描述：** 为所有工程技能搭建每个仓库的配置
- **文件：** `skills/engineering/setup-matt-pocock-skills/SKILL.md`
- **`disable-model-invocation: true`** — 仅限用户触发
- **创建内容：**
  - `docs/agents/issue-tracker.md`
  - `docs/agents/triage-labels.md`
  - `docs/agents/domain.md`
  - 用 `## Agent skills` 块更新 `CLAUDE.md` 或 `AGENTS.md`
- **支持：** GitHub、GitLab、本地 markdown、其他（自由格式文本）

#### 6. `/tdd`
- **描述：** 红-绿-重构循环的测试驱动开发
- **文件：** `skills/engineering/tdd/SKILL.md`（4,395 字节）
- **辅助文件：**
  - `deep-modules.md`（1,239 字节）
  - `interface-design.md`（653 字节）
  - `mocking.md`（1,481 字节）
  - `refactoring.md`（387 字节）
  - `tests.md`（1,640 字节）
- **核心原则：** 测试通过公开接口验证行为，而非实现细节
- **反模式：** 水平切片（先写所有测试，再写所有实现）
- **正确方法：** 垂直 tracer bullet（一个测试 -> 一个实现 -> 重复）
- **工作流：**
  1. **计划** — 确认接口变更、识别深度模块、列出行为
  2. **Tracer bullet** — 红（测试失败）-> 绿（最小化代码）
  3. **增量循环** — 一次一个测试、最小化代码、不做预判
  4. **重构** — 仅在所有测试通过时进行，绝不在红态重构
  5. **每轮检查清单** — 行为 vs 实现、仅公开接口、最小化代码

#### 7. `/to-issues`
- **描述：** 将计划、规格或 PRD 拆解为可独立领取的 issue，使用 tracer-bullet 垂直切片
- **文件：** `skills/engineering/to-issues/SKILL.md`
- **流程：**
  1. 从对话或 issue 跟踪器收集上下文
  2. 探索代码库以获取领域词汇
  3. 起草垂直切片（人在回路中或全自动）
  4. 就粒度、依赖关系、HITL/AFK 标记询问用户
  5. 按依赖顺序发布 issue
- **切片规则：** 每个切片提供一条窄但完整的路径贯穿所有层级（schema、API、UI、测试）

#### 8. `/to-prd`
- **描述：** 将当前对话上下文转化为 PRD 并发布到 issue 跟踪器
- **文件：** `skills/engineering/to-prd/SKILL.md`
- **关键规则：** 不要采访用户 — 综合你已经知道的内容
- **PRD 模板包含：**
  - 问题陈述、解决方案、用户故事（详尽的编号列表）
  - 实现决策（模块、接口、架构、schema、API 契约）
  - 测试决策（什么是好的测试、哪些模块、已有实践）
  - 范围外、补充说明
- **深度模块关注：** 寻找机会抽取那些用简单且不易变的接口封装大量功能的模块

#### 9. `/zoom-out`
- **描述：** 让代理拉远视角，提供更广泛的上下文或更高层次的视角来理解不熟悉的代码
- **文件：** `skills/engineering/zoom-out/SKILL.md`
- 适用于熟悉新代码库或理解系统架构

#### 10. `/prototype`
- **描述：** 构建一次性原型来捋清设计
- **两种模式：** 可运行的终端应用（用于状态/业务逻辑），或 UI 变体

### 效率技能（3 个技能）

#### 1. `/caveman`
- 超压缩通信模式
- 将 token 使用量减少约 75%

#### 2. `/grill-me`
- **描述：** 围绕计划持续追问用户，直到达成共识
- **文件：** `skills/productivity/grill-me/SKILL.md`
- grill-with-docs 的简化版本（无 CONTEXT.md/ADR 集成）
- 一次一个问题，提供推荐答案
- 如果问题能在代码库中找到答案，就去探索代码库

#### 3. `/write-a-skill`
- 指导如何以正确结构创建新的代理技能
- 渐进式文档编写方法

### 杂项技能（5 个技能）

- `git-guardrails-claude-code/` — git 安全护栏
- `migrate-to-shoehorn/` — 迁移工具
- `scaffold-exercises/` — 练习脚手架
- `setup-pre-commit/` — pre-commit 钩子配置

### 已弃用和进行中

- `skills/deprecated/` — 已归档/移除的技能
- `skills/in-progress/` — 正在开发的技能

### 个人技能（2 个技能）

- `edit-article/` — 文章编辑工作流
- `obsidian-vault/` — Obsidian 知识库管理

## 关键模式与约定

### YAML 前置元数据

每个 SKILL.md 以如下内容开头：
```yaml
---
name: skill-name
description: 何时使用该技能的人类可读描述
---
```

### 技能结构

- **What-to-do 部分** — 通过 `<what-to-do>` 标签（grill-with-docs 模式）
- **Supporting-info 部分** — 通过 `<supporting-info>` 标签
- **交叉引用** — 通过相对路径引用其他技能和文档

### 文档约定

**CONTEXT.md 格式：**
- 每个领域上下文一个 `CONTEXT.md`
- 结构：上下文名称、语言（术语及其定义和别名）、关系、示例对话、标记的歧义
- 规则：有观点、明确标记冲突、定义精炼（一句话）、用量化关系展示关联
- 通用编程概念不应包含在内
- 多上下文仓库在根目录使用 `CONTEXT-MAP.md`

**ADR 格式：**
- 文件位于 `docs/adr/`，使用顺序编号：`0001-slug.md`
- 可以是单个段落
- 可选：状态前置元数据、备选方案、后果
- 仅在以下情况创建：难以逆转、脱离上下文会令人费解、真实权衡的结果

### 分类状态机

```
未标记 -> 需分类 -> 需信息（等待报告人）
                  -> 可交代理（可全自动处理）
                  -> 需人工处理（需要人参与）
                  -> 不修复（已关闭）
需信息 -> 需分类（当报告人回复时）
```

### 垂直切片架构

- 每个 issue 是一个贯穿所有集成层的薄垂直切片
- 尽可能优先选择全自动（AFK）而非人在回路中（HITL）
- 按依赖顺序发布，以便知道阻塞 ID
- Issue 模板：要构建什么、验收标准、被谁阻塞

## Git 护栏模式

**git-guardrails-claude-code** 技能（来自 mattpocock）是一个 PreToolUse 钩子，用于拦截 12 种危险的 git 模式：

### 被拦截的模式（共 12 种）

```
git push --force     （而非 --force-with-lease）
git push -f          （缩写形式）
git reset --hard     （而非 --soft）
git clean -fd        （强制清理目录）
git clean -df        （交替参数顺序）
git branch -D        （强制删除，而非 -d）
git checkout .       （丢弃工作目录所有更改）
git checkout --      （丢弃特定文件）
git restore .        （通过 restore 丢弃所有更改）
git restore --staged .  （取消暂存所有文件）
git rebase --skip    （变基过程中的危险操作）
git merge --abort    （合并过程中的危险操作）
```

### 实现模式（来自 devflow 本地副本）

钩子接收 stdin JSON：
```json
{"tool_name":"Bash","tool_input":{"command":"git push --force"}}
```

返回 JSON 决策：
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "护栏阻止了危险 GIT 命令：<pattern>"
  }
}
```

**需要两套并行的实现：**
- `.ps1`（PowerShell）— 使用 `ConvertFrom-Json` / `ConvertTo-Json`
- `.sh`（bash）— 使用 `grep`/`sed` 解析 JSON（不依赖 jq）

两者必须拦截相同的 12 种模式，并且必须保持同步。

### 护栏测试模式

每个实现都有对应的测试脚本，用于验证：
- **拦截测试：** 12 种危险模式必须被拒绝
- **放行测试：** 10 种以上安全模式必须被允许
- **边界情况：** `git push --force-with-lease`（允许）、`git reset --soft`（允许）

测试脚本注入模拟的 stdin JSON 并检查输出中是否包含 `permissionDecision.*deny`。

## 钩子系统模式

mattpocock/skills 确立了 devflow 所使用的钩子架构：

### settings.json 中的钩子注册

```json
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "..."}]}],
    "PreToolUse": [{"hooks": [{"type": "command", "command": "..."}]}],
    "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "..."}]}],
    "PreCompact": [{"hooks": [{"type": "command", "command": "..."}]}]
  }
}
```

### 使用的钩子类型

1. **SessionStart** — 项目初始化检查、上下文加载
2. **PreToolUse** — git 安全护栏、Edit/Write 前的阶段检查
3. **UserPromptSubmit** — 状态提醒、状态注入
4. **PreCompact** — 数据持久化（例如 beads 的 `bd prime`）

## 技能开发模式

### SKILL.md 结构（来自 mattpocock 约定）

```yaml
---
name: skill-name
description: 何时触发此技能
---
```

关键结构要素：
- **YAML 前置元数据** — 包含名称和描述，用于自动发现
- **HARD-GATE 标签** — 标记不可跳过的步骤
- **SUBAGENT-STOP 标签** — 用于子代理模式
- **检查清单** — 通过 TodoWrite 创建任务
- **引用文件** — 存放在 `references/` 子目录
- **脚本** — 存放在 `scripts/` 子目录
- **辅助文档** — 提供深层上下文（例如 refactoring.md、tests.md）

### devflow 采用的关键模式

1. **双平台脚本** — 每个自动化功能都提供 `.ps1` + `.sh`（devflow 有 8 对以上脚本）
2. **JSON stdin/stdout 钩子** — 钩子通过 stdin JSON 接收上下文，通过 stdout JSON 返回决策
3. **幂等合并语义** — 安装脚本检测已有配置，仅追加缺失的模式
4. **CONTEXT.md + ADR** — 领域术语表 + 架构决策记录，作为持久化知识
5. **拷问协议** — 一次一个问题，结合代码库交叉引用进行追问
6. **垂直切片规划** — 每个任务提供一条窄但完整的路径贯穿所有层级
7. **护栏测试** — 通过模拟输入/输出验证钩子行为

## 与 devflow 的集成

该技能体系直接影响 devflow 的架构：

1. **`/grill-with-docs`** -> devflow Phase 1 构思阶段（结构化发现）
2. **`/to-prd`** -> devflow Phase 1 构思阶段（PRD 生成）
3. **`/setup-matt-pocock-skills`** -> devflow Phase 3 配置阶段（脚手架搭建）
4. **`/to-issues`** -> devflow `scripts/prd-to-beads.ps1`（任务拆分）
5. **`/tdd`** -> devflow TDD 技能集成
6. **`/diagnose`** -> devflow superpowers 中引用的调试方法
7. **`/grill-me`** -> devflow Phase 4 中的"拷问"步骤
8. **`CONTEXT.md`** -> devflow `docs/CONTEXT.md` 模式
9. **`docs/adr/`** -> devflow `docs/adr/` 模式
10. **Git 护栏** -> devflow `guardrails-git` 脚本
