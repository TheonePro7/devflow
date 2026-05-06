# devflow 整合分析报告

> 基于对 5 个生态项目的完整调研，输出 devflow 当前的整合缺失和优化方案
> 日期: 2026-05-07

---

## 一、当前整合状态总评

```
项目                   整合深度    灵魂缺失
─────────────────────────────────────────────────
obra/superpowers        ⭐⭐⭐✩✩    **中等**
gastownhall/beads       ⭐⭐✩✩✩    **严重**
uditgoenka/autoresearch ⭐⭐⭐✩✩    **中等**
mattpocock/skills       ⭐⭐✩✩✩    **严重**
前端生成工具            ⭐⭐✩✩✩    **严重**
```

---

## 二、各项目缺失深度分析

### 2.1 superpowers — 缺了什么

**当前 devflow 用法**: 列出了 14 个技能的管道图，给每个技能加了 devflow 注入点。

**超级缺失**:

| superpowers 的灵魂 | devflow 有吗 | 问题 |
|---|---|---|
| **HARD GATE**: brainstorming 后用户必须批准设计才能写代码 | ✅ 有 | 但 devflow 的 phase 1 有自己的 ideation 流程，跟 superpowers 的 brainstorming 是两回事，入口混乱 |
| **Anti-Pattern**: "太简单不需要设计" 是陷阱 | ❌ 没有 | devflow Phase 2 的 Claude Direct（1-5 页）跳过了设计审批环节 |
| **writing-plans** 必含 header + 无占位符规则 | ❌ 没有 | devflow 直接跳到 subagent-driven-development，跳过了计划的模板格式和自审查 |
| **verification-before-completion**: 铁律"无验证证据不得声称完成" | ❌ 没有 | devflow 没有这个通用门禁，全靠 autoresearch 填补 |
| **using-git-worktrees**: 专用隔离工作目录 | ❌ 没有 | devflow 直接在项目根目录工作，污染工作区 |
| **requesting-code-review**: per-task 审查子 agent | ❌ 没有 | devflow 把 code-review 标为"devflow 不参与"，但 superpowers 的 code review 是 per-task 的 |
| **receiving-code-review**: 技术验证而非表演性同意 | ❌ 没有 | 完全没集成 |
| **writing-skills**: TDD 应用于流程文档 | ❌ 没有 | devflow 有写技能的需求但没有这个模式 |
| **dispatching-parallel-agents**: 并行子代理 | ❌ 没有 | devflow 全部是串行的 |
| **systematic-debugging**: 根因优先 | ❌ 没有 | devflow 没有 bug 调试流程 |
| **executing-plans**: 隔离会话执行 | ❌ 没有 | 只有 subagent-driven-development |

**核心问题**: devflow 把 superpowers 降级成了一个"技能调用列表"，忽略了他的 **流程纪律**（hard gates、验证铁律、隔离工作区）。

### 2.2 beads — 缺了什么

**当前 devflow 用法**: `bd create` + `bd close` + `bd ready` 在最基本的层面。

**严重缺失**:

| beads 的能力 | devflow 有吗 | 问题 |
|---|---|---|
| **依赖图管理** (`bd link`, `bd dep`) | ❌ | 只有 `bd ready` 检查，没有完整依赖链 |
| **门禁系统** (`bd gate`, `bd merge-slot`) | ❌ | devflow 在 SKILL.md 里自建门禁，忽略了 beads 的原生 gate 系统 |
| **标签/优先级** (`bd label`, `bd priority`) | ❌ | 没有使用 |
| **公式工作流** (`bd mol pour`) | ❌ | 这正好是 devflow 需要的结构化流程 |
| **批量创建** (`bd create` 从 markdown/graph JSON) | ❌ | devflow 自己做 PRD→beads 拆分，但 beads 原生支持批量创建 |
| **搜索查询** (`bd search`) | ❌ | 没利用 |
| **格式化输出** (Unicode + 语义颜色) | ❌ | 只用原始命令 |
| **活动审计** (`bd audit`, `bd note`) | ❌ | 没有任务历史追溯 |
| **质量检查** (`bd lint`, `bd stale`, `bd orphans`, `bd preflight`) | ❌ | 完全没用 |
| **GitHub/Azure DevOps 集成** | ❌ | 没有利用 beads 的外部系统桥接 |
| **Dolt 版本控制** (完整历史回溯) | ❌ | 只知道 beads 用 Dolt，但没有利用版本能力 |
| **配置管理** (`bd config`) | ❌ | 没用 |

**核心问题**: devflow 把 beads 当成"简单的 issue 创建器"，忽略了 beads 是一个**完整的图数据库 issue tracker**，有原生的依赖管理、门禁系统、工作流公式。

### 2.3 autoresearch — 缺了什么

**当前 devflow 用法**: 调用了 probe/scenario/fix/security 4 个门禁，加了一个 optimize 提示。

**中等缺失**:

| autoresearch 的能力 | devflow 有吗 | 问题 |
|---|---|---|
| **完整 loop**: Modify→Verify→Keep/Discard→Repeat 循环 | ❌ 部分 | devflow 有 optimize 提示但没实现真正的循环 |
| **/autoresearch:plan** 交互式目标设置向导 | ❌ | devflow 用 hardcoded 的门 |
| **/autoresearch:debug** 自主 bug 追查 | ❌ | devflow 没有 bug 场景，依赖 superpowers 的 debugging |
| **mechanical metric 要求** | ❌ | devflow 没有 enforce"必须有可度量指标才能运行优化" |
| **TSV 日志 + 迭代记录** | ❌ | 每次优化结果没记录到文件 |
| **自动 git rollback** | ❌ | devflow 跑完不自动比较 keep/discard |
| **8 条铁律** | ❌ | 只有"自动执行门禁"，没有完整的 loop 纪律 |

### 2.4 mattpocock/skills — 缺了什么

**当前 devflow 用法**: 从 mattpocock/skills 复制了 guardrails、CONTEXT.md、ADR 格式、TDD 文档。

**严重缺失**:

| mattpocock 的模式 | devflow 有吗 | 问题 |
|---|---|---|
| **/grill-with-docs** — 用 CONTEXT.md 拷问设计 | ✅ 部分 | 只有基本概念，缺少完整的 6 步拷问流程和术语精确化 |
| **/diagnose** — 6 阶段严格诊断 | ❌ | 完全没有 bug 诊断体系 |
| **/triage** — issue 状态机 | ❌ | beads 自行管理但缺少 triage 流程 |
| **/improve-codebase-architecture** — 深度模式 | ❌ | 代码架构治理完全缺失 |
| **/zoom-out** — 代码库全景分析 | ❌ | 没有 |
| **/to-prd** — 想法→PRD 结构化 | ✅ 有 | devflow Phase 1 有自己的流程，但缺少 to-prd 的原生体验 |
| **CONTEXT-FORMAT.md** — 精确的格式模板 | ❌ | devflow 的 CONTEXT.md 是手动创建的，没有格式约束 |
| **ADR-FORMAT.md** — 完整的架构决策模板 | ❌ | devflow 的 ADR 没有模板规则 |
| **DEEPENING.md** 深度化分析框架 | ❌ | 没有 |
| **INTERFACE-DESIGN.md** 接口优先设计 | ✅ 有 | 复制到了 TDD docs |
| **60,000 订阅者邮件列表** | N/A | 不是代码集成，但说明 mattpocock 的模式有广泛实战验证 |

### 2.5 前端生成工具 — 缺了什么

**当前 devflow 用法**: Claude Direct（默认）+ OpenUI（6-15 页）+ bolt.diy（16+ 页）+ screenshot-to-code（有截图时）。

**严重缺失**:

| 新发现的能力 | devflow 有吗 | 问题 |
|---|---|---|
| **Google Stitch MCP** — MCP-native 设计→代码桥 | ❌ | Google 官方支持 Claude Code，MCP 原生集成 |
| **Open Design** — 71 套设计系统 | ❌ | devflow 只有 7 套映射，Open Design 有 71 套 |
| **Dyad** — 本地优先的 bolt 替代 | ❌ | bolt.diy 太重量级，Dyad 更轻量 |
| **Claudable** — 多 agent 路由 | ❌ | 思路跟 devflow 一致但更成熟 |
| **交互式/可迭代** — 大部分工具支持 prompt 修改再生成 | ❌ | devflow 只做一次性生成 |
| **MCP 统一集成** | ❌ | 各工具各自安装，没有 MCP 统一入口 |

---

## 三、深度整合方案

### 3.1 Phase 1: 用 mattpocock 的 to-prd 替换自定义流程

**现状**: devflow Phase 1 有自己的 4 阶段探索引擎。

**问题**: 重复造轮子。to-prd 已经在 mattpocock/skills 中存在且经 6 万人验证。

**方案**: 
- 保留 Stage 1-4 的引导问题框架（这是 devflow 的特色——对小白友好）
- 但输出格式改用 to-prd（调用 `/to-prd` skill）
- 集成 CONTEXT-FORMAT.md 确保领域词汇规范
- 集成 ADR-FORMAT.md 确保架构决策记录规范

### 3.2 Phase 2: Claude Direct 加入设计审批环节

**现状**: 小项目直接 Claude Direct 生成，无设计审批。

**问题**: 违反了 superpowers 的 HARD GATE ─ "无设计审批不得写代码"。

**方案**:
- Claude Direct 之前必须先跑设计审批（输出架构设计—用户确认—再生成）
- 集成 Open Design 的 71 套设计系统，扩展 devflow 的框架映射表
- 添加 Google Stitch MCP 作为可选的视觉设计工具
- 添加 Dyad 作为 bolt.diy 的轻量替代

### 3.3 Phase 4: superpowers 技能链完整对齐

**现状**: devflow 的 Phase 4 管道是自创的 10 步流程（brainstorming → grill → probe → plans → scenario → impl → review → security → optimize → finish），没有对齐 superpowers 的原始技能链。

**方案**: 改成跟 superpowers 的原始链对齐，在正确点位注入 devflow 的工具：

```
superpowers 原始链                    devflow 注入
───────────────────────────          ──────────────
brainstorming (设计→审批)             → beads epic + gitnexus context
  └─ HARD GATE: 用户批准设计
  └─ using-git-worktrees              → 自动创建隔离工作区
writing-plans (有模板+有自审查)        → beads sub-issues + gitnexus impact
  └─ 无占位符规则
subagent-driven-development (per-task):
  ├─ implementer 子 agent
  ├─ spec-reviewer 子 agent           → 替换 devflow 的 scenario 门禁
  ├─ code-quality-reviewer 子 agent   → 替换 devflow 的 fix 门禁
  └─ requesting-code-review           → devflow 之前说"不参与"
finishing-a-development-branch        → autoresearch security + optimize
  └─ 4 选项: merge/PR/keep/discard
  └─ using-git-worktrees cleanup
```

**关键变化**:
1. 删除 devflow 自定义的 `grill` 步骤 → 用 superpowers 的 `brainstorming` 自带的设计审批替代
2. 删除 devflow 自定义的 `probe` → 移入 `brainstorming` 阶段作为可选增强
3. 删除 devflow 自定义的 `scenario` 门禁 → 由 `subagent-driven-development` 的 `spec-reviewer` 子 agent 覆盖
4. 删除 devflow 自定义的 `fix` 门禁 → 由 `subagent-driven-development` 的 `code-quality-reviewer` 子 agent 覆盖
5. 添加 `using-git-worktrees` → 自动创建隔离工作区
6. 添加 `requesting-code-review` → per-task 审查
7. 保留 `autoresearch security` → 在 finish-branch 前执行
8. 保留 `autoresearch optimize` → 可选优化循环

### 3.4 beads 深度集成

**现状**: 只用 create/close/ready。

**方案（分层增强）**:

| 层 | 集成点 | 实现方式 |
|----|--------|----------|
| **1. 依赖图** | writing-plans 后 | `bd link` 设置任务依赖关系 |
| **2. 门禁** | 每个 sub-agent 完成后 | 用 `bd gate` 代替自建 gate 系统 |
| **3. 标签** | 创建任务时 | 自动加类型/优先级标签 |
| **4. 搜索** | Phase 5 报告时 | `bd search` 查找未完成事项 |
| **5. 公式** | 项目启动时 | `bd mol pour devflow-formula` 自动配置 beads 工作流到跟 devflow 5 阶段对齐 |
| **6. 质量** | 定期/Phase 5 | `bd lint` + `bd stale` + `bd orphans` |
| **7. Dolt 版本** | 决策回溯时 | 利用 Dolt commit history 追溯 issue 变更历史 |

### 3.5 autoresearch 深度集成

**现状**: 调用了 4 个门但没有完整 loop。

**方案**:

```
当前:  probe → scenario → fix → security
目标:  optimize (完整 autoresearch loop)
         └─ 调用 /autoresearch:plan 设置 Goal/Scope/Metric
         └─ 调用 /autoresearch 运行完整 loop (N 轮)
         └─ TSV 日志记录到 docs/superpowers/optimize/
         └─ 自动 git rollback: keep/discard
         └─ 报告: 哪些改进保留、哪些回滚、净效果
         └─ 这个 loop 才是 autoresearch 的灵魂!
```

此外：
- 用 `/autoresearch:debug` 覆盖 devflow 缺失的调试能力
- 用 `/autoresearch:fix` 替换 devflow 的 fix 门禁（更完整：有自动 rollback + 迭代）

### 3.6 前端生成工具深度扩展

**现状**: 3 种工具按复杂度路由。

**方案**: 扩展到 5 种工具 + 1 个设计系统库：

```
用户是否有截图？
  YES → screenshot-to-code → Claude Direct 精修
  
用户是否有 Google Cloud？
  YES → Google Stitch MCP → 视觉设计→代码桥
  
项目复杂度：
  小型（1-5 页）→ Claude Direct + Open Design 设计系统参考
  中型（6-15 页）→ OpenUI 快速原型 + Claude Direct 集成  
  大型（16+ 页）→ Dyad（轻量）或 bolt.diy（重量级）
  
设计质量要求高？
  → Open Design 71 套设计系统 → Claude Direct 应用
```

---

## 四、汇总：哪些灵魂被找回来了

| 灵魂 | 来自哪里 | 之前的状态 | 整合后 |
|------|---------|-----------|--------|
| 无设计审批不得写代码 | superpowers | ❌ Claude Direct 跳过 | ✅ 强制设计→审批→实现 |
| 无证据不得声称完成 | superpowers | ❌ 没有 | ✅ 添加 verification-before-completion |
| 隔离工作区 | superpowers | ❌ 根目录直接工作 | ✅ using-git-worktrees |
| Per-task 代码审查 | superpowers | ❌ "devflow 不参与" | ✅ requesting-code-review |
| 依赖图 + 门禁系统 | beads | ❌ 只用 create/close | ✅ bd link + bd gate |
| 完整优化循环 | autoresearch | ❌ 只有 4 个单点门 | ✅ 完整 loop: plan→modify→verify→keep/discard→log→repeat |
| 严格诊断流程 | mattpocock | ❌ 没有 | ✅ /diagnose 6 阶段 |
| Issue 状态机 triage | mattpocock | ❌ 没有 | ✅ /triage 流程 |
| 71 套设计系统 | Open Design | ❌ 只有 7 套 | ✅ 可选扩展 |
| MCP 原生设计桥 | Google Stitch | ❌ 没有 | ✅ 可选集成 |

---

## 五、实施优先级

| 优先级 | 改动 | 影响范围 | 难度 |
|--------|------|---------|------|
| **P0** | Phase 4 管道对齐 superpowers 原始链 | SKILL.md Phase 4 重写 | 高 |
| **P0** | Phase 2 加入设计的审批环节 | SKILL.md Phase 2 | 中 |
| **P0** | Adding verification-before-completion | SKILL.md 通用门禁 | 低 |
| **P1** | beads 深度集成（依赖 + 门禁 + 质量） | SKILL.md + scripts | 中 |
| **P1** | autoresearch 完整 loop optimize | SKILL.md Phase 4 | 中 |
| **P1** | 前端生成工具扩展（Open Design + Dyad） | SKILL.md Phase 2 | 低 |
| **P2** | using-git-worktrees | SKILL.md 前期 | 中 |
| **P2** | requesting-code-review per-task | SKILL.md Phase 4 | 低 |
| **P2** | /diagnose + /triage | SKILL.md + scripts | 高 |
| **P3** | Google Stitch MCP | SKILL.md Phase 2 可选 | 低 |
| **P3** | Dolt 版本历史利用 | 可选 | 低 |

