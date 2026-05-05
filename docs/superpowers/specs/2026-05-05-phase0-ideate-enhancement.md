# Phase 0 Ideate Enhancement — 结构化 PRD 发现引擎

> **设计文档**
> 将模糊想法通过结构化探索转化为完整 PRD，输出给 `to-prd` 技能进行格式化。

**Goal:** 增强 devflow Phase 0 (Ideate)，从简单的 4 问题问答升级为 4 阶段自适应结构化探索，产出的结构化上下文直接喂给 `to-prd` 技能生成最终 PRD。

**Architecture:** 4 阶段自适应访谈（问题发现 → 用户场景 → 功能探索 → 约束与标准），每阶段自动判断用户已说清的内容并跳过，只追问模糊地带。探索完成后调用 `to-prd` 技能格式化输出。

**借鉴来源:** `to-prd` (mattpocock/skills) — Deep Module 思维、User Story 格式、"As a <actor>, I want <feature>, so that <benefit>" 模板、领域词汇对齐、ADR 尊重。

**Tech Stack:** 纯 Prompt 工程 — 修改 SKILL.md Phase 0 节。无外部依赖，无额外 LLM 调用。

---

## 架构总览

```
用户: "我有一个想法..."
       │
       ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 0 结构化探索                                      │
│                                                          │
│  Stage 1 ── 问题发现                                      │
│  │  痛点 → 现状 → 时机 → 竞品                              │
│  │  输出: Problem Statement                               │
│  │                                                        │
│  Stage 2 ── 用户与场景                                    │
│  │  角色提炼 → 场景分析 → User Stories                    │
│  │  输出: Personas + Stories                              │
│  │                                                        │
│  Stage 3 ── 功能探索                                      │
│  │  发散(功能 brainstorm) → 收敛(MoSCoW 归类)              │
│  │  输出: Feature List + Prioritized Stories              │
│  │                                                        │
│  Stage 4 ── 约束与成功标准                                 │
│  │  技术/业务约束 → KPIs → 风险评估                        │
│  │  输出: Constraints + Metrics + Risks                   │
│  │                                                        │
│  特征: 自适应跳过、每阶段确认、to-prd 经验全程注入           │
└──────────────────────┬───────────────────────────────────┘
                       │ 结构化上下文 (JSON)
                       ▼
┌─────────────────────────────────────────────────────────┐
│  to-prd 技能调用                                         │
│  ├── 加载 CONTEXT.md 领域词汇                            │
│  ├── 检查相关 ADR                                       │
│  ├── Deep Module 识别提示                                │
│  ├── 按模板输出 PRD 到 GitHub Issues                     │
│  └── 同时保存到 docs/prd/<feature-slug>.md              │
└─────────────────────────────────────────────────────────┘
```

---

## 4 阶段详细设计

### Stage 1：问题发现

**目标:** 验证想法价值，产出 Problem Statement。

| 维度 | 触发追问的条件 | 追问示例 |
|------|---------------|---------|
| 痛点 | 用户只说"我要做 X"没说原因 | "为什么你觉得这是个问题？谁在承受这个痛点？" |
| 现状 | 用户没提现有方案 | "现在这个问题怎么解决的？有没有在用替代方案？" |
| 时机 | 看起来是老问题但用户突然想做 | "为什么是现在做？发生了什么变化？" |
| 竞品 | 明显有竞品但用户没提 | "你和 XX（竞品）的区别是什么？用户为什么选你不选它？" |

**自适应逻辑:** 如果用户上述信息都已包含在初始描述中，直接确认后进 Stage 2。

**产出:** 1-2 段 Problem Statement，包含痛点描述、现状分析、机会窗口。

---

### Stage 2：用户与场景

**目标:** 建立用户画像，生成 User Stories。

**流程:**
1. Claude 根据项目领域自动推断典型用户角色（每个角色包含：身份、核心诉求、当前痛点）
2. 用户确认/修正角色设定
3. 每个角色生成 3-5 条 User Story

**User Story 格式（借鉴 `to-prd`）:**
```
As a <角色>, I want <功能/能力>, so that <价值/收益>
```

示例:
```
As a 小店主, I want 一键生成商品海报, so that 不需要请设计师就能发朋友圈推广
```

**自适应逻辑:** 如果用户一上来就说了目标用户是谁，直接细化角色，不空泛提问"用户是谁"。

**产出:** 2-3 个用户画像 + 6-15 条 User Stories。

---

### Stage 3：功能探索

**目标:** 从发散到收敛，确定功能优先级。

**两阶段:**

**发散阶段:**
- 基于前两阶段信息，先问用户："为了实现这个，你觉得需要哪些具体功能？"
- 如果用户想不全，Claude 基于领域知识和竞品分析补充建议
- 完整列出所有候选功能

**收敛阶段（MoSCoW 归类）:**
- **Must** — 核心路径，没有就不能用
- **Should** — 重要但有替代方案，可以晚几周
- **Could** — 锦上添花，有资源再做
- **Won't** — 明确本轮不做，但记录备查

**产出:** MoSCoW 分类功能列表，每个 Must/Should 功能绑定到 Stage 2 的 User Story。

---

### Stage 4：约束与成功标准

**目标:** 收口袋，确保 PRD 可行可衡量。

**约束清单（自动扫描是否有遗漏）:**

| 约束类型 | 检查项 |
|---------|--------|
| 技术栈 | 团队用什么语言/框架？有偏好吗？ |
| 时间 | 期望什么时候上线？ |
| 平台 | Web / iOS / Android / 全平台？ |
| 业务 | 合规要求？安全等级？权限模型？ |

**成功标准:**
- **定性:** 用户怎么才算"用起来了"？什么场景下用户会觉得"这东西不错"？
- **定量:** 明确的数字指标（DAU、转化率、响应时间、覆盖率等）

**风险评估:**
- 最大的 3 个风险是什么？
- 每个风险的缓解方案

**产出:** 约束清单 + 成功指标 + 风险矩阵。

---

## to-prd 集成

4 阶段探索完成后，Phase 0 将以下结构化上下文传递给 `to-prd` 技能：

```json
{
  "phase": 0,
  "stage": "complete",
  "outputs": {
    "problemStatement": "...",
    "personas": [
      { "name": "...", "needs": "...", "painPoints": "..." }
    ],
    "userStories": [
      "As a ..., I want ..., so that ..."
    ],
    "featurePriority": {
      "must": ["..."],
      "should": ["..."],
      "could": ["..."],
      "wont": ["..."]
    },
    "constraints": {
      "tech": "...",
      "timeline": "...",
      "platform": "...",
      "business": "..."
    },
    "successMetrics": {
      "qualitative": "...",
      "quantitative": "..."
    },
    "risks": [
      { "risk": "...", "mitigation": "..." }
    ]
  }
}
```

**调用流程:**
1. 输出 JSON 到临时文件 `.devflow/prd-context.json`
2. 确认用户准备好创建 PRD
3. 运行 `/to-prd` 技能（自动读取当前上下文 + JSON 上下文）
4. `to-prd` 格式化 PRD → GitHub Issues (`needs-triage`)
5. 同时复制到 `docs/prd/<feature-slug>.md`

---

## 借鉴 to-prd 经验清单

| to-prd 要素 | 如何在 Phase 0 中使用 |
|------------|---------------------|
| Deep Module 识别 | Stage 3 结束后、调 to-prd 前，提示 Claude 思考"这里是否存在可以抽取为 deep module 的独立功能块" |
| User Story 格式 | Stage 2-3 全程使用 `As a <actor>, I want <feature>, so that <benefit>` 格式 |
| 领域词汇对齐 | 探索全程加载 CONTEXT.md，使用项目已有术语 |
| ADR 尊重 | Stage 4 检查相关 ADR，避免与历史决策冲突 |
| Do NOT interview | 这条是 to-prd 自用规则——Phase 0 恰恰是 interview 阶段，但 interview 完成后调 to-prd 时不重复采访 |
| Issue tracker 集成 | 保留 to-prd 发 GitHub Issues 的能力，额外存 docs/prd/ 作为本地备份 |

---

## 修改范围

### 修改文件

| 文件 | 修改内容 |
|------|---------|
| `SKILL.md:81-100` | 替换 Phase 0 节为新的 4 阶段设计 + to-prd 集成流程 |
| `.devflow/state` | Phase 0 步骤扩展为 `problem` → `users` → `features` → `constraints` → `prd` |

### 不修改文件

| 文件 | 理由 |
|------|------|
| `scripts/auto-designer.*` | Phase 0.5 工具，不相关 |
| `setup.*` | 无安装变化 |
| `to-prd` 技能 | 直接调用，不改上游 |

---

## 边界情况处理

| 情况 | 处理方式 |
|------|---------|
| 用户一上来就有完整 PRD | 跳过 Stage 1-3，直接 Stage 4 验证完整性 → to-prd |
| 用户说"我不确定" | 提供选项让用户选，而非让用户填空 |
| 用户中途改变想法 | 重新从 Stage 1 开始，但保留已确认的信息 |
| 用户赶时间 | 提供"快速模式"——每阶段只问最关键的一个问题 |
| 项目没有 CONTEXT.md | Phase 0 自动创建并填充基础词汇 |
