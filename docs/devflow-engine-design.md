# Devflow Engine 设计文档

> 设计日期: 2026-06-07
> 状态: 已批准，阶段一开发中

---

## 一、概述

Devflow Engine 是一个 Python CLI 工具，为 Claude Code（以及其他 AI 编码代理）提供结构化的产品开发工作流。它不是一个"脚手架生成器"，而是一个**自主工程引擎**——给定一个模糊的想法，它能引导 agent 从需求梳理到代码交付完整走完。

### 核心哲学

- **人提供方向，agent 提供执行，引擎提供纪律**
- 约束必须架构化，不能靠 agent 的自觉
- 数据必须贯通，不能靠 agent 的记忆
- 流程必须自主推进，不能等人按按钮
- 人只参与两件事：需求对焦 + 最终验收

---

## 二、架构总览

```
┌─────────────────────────────────────────────┐
│              Agent (Claude Code)             │
│    通过 CLI / SKILL.md / hooks 与引擎交互    │
└───────────────────┬─────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│              devflow CLI (Python)            │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐ │
│  │ 状态机    │  │ 门禁系统  │  │ 工具编排   │ │
│  │          │  │          │  │           │ │
│  │ state    │  │ check    │  │ beads     │ │
│  │ transiti │  │ run-*    │  │ gitnexus  │ │
│  │ on       │  │ auto-*   │  │ autoresea │ │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘ │
│       │             │              │       │
│       ▼             ▼              ▼       │
│  ┌─────────────────────────────────────┐   │
│  │          beads (持久化层)            │   │
│  │  state_logs / tasks / gates / epic  │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## 三、状态机设计

### 3.1 阶段定义

```
Phase 0: 未初始化
  └─ 条件: .devflow/state 不存在
  └─ 入口: devflow init
  └─ 转移: init → Phase 1

Phase 1: Ideate（需求梳理）
  └─ 条件: 已初始化
  └─ 流程: agent 深度追问（目标用户/场景/痛点/成功标准）
  └─ 出口: PRD 已写入 beads epic
  └─ 出口条件: epic.title && epic.acceptance && epic.description 均非空
  └─ 人介入: 是（回答 agent 的问题）
  └─ 转移: Phase 1 → Phase 2

Phase 2: Design（设计）
  └─ 条件: Phase 1 完成
  └─ 流程: agent 出设计方案 → 自动审批
  └─ 出口: 设计决策已写入 beads decision
  └─ 出口条件: decision.decision 非空
  └─ 人介入: 可选（agent 可以出方案给人确认）
  └─ 转移: Phase 2 → Phase 3

Phase 3: Setup（项目初始化）
  └─ 条件: Phase 2 完成
  └─ 流程: 自动执行 init 脚本
  └─ 出口: beads tasks 已创建
  └─ 出口条件: 至少有一个 epic 下的 task 处于 ready 状态
  └─ 人介入: 否
  └─ 转移: Phase 3 → Phase 4

Phase 4: Develop（开发循环）
  └─ 条件: Phase 3 完成
  └─ 流程: 循环处理每个 task（task → impl → gate close → next）
  └─ 出口: 所有 epic 下的 task 均为 closed
  └─ 出口条件: 无 open/in_progress task
  └─ 人介入: 否（但失败升级到人）
  └─ 转移: Phase 4 → Phase 5

Phase 5: Finish（收尾）
  └─ 条件: Phase 4 完成
  └─ 流程: 自动执行收尾（git push/beads close/report）
  └─ 出口: 全部完成
  └─ 出口条件: git push 成功
  └─ 人介入: 是（最终验收）
```

### 3.2 状态转移检查

```python
PHASE_TRANSITIONS = {
    "phase-0": {
        "next": "phase-1",
        "conditions": []  # 无条件，直接进入
    },
    "phase-1": {
        "next": "phase-2",
        "conditions": [
            Condition("EPIC_EXISTS", "至少有一个 epic 已创建"),
            Condition("EPIC_HAS_ACCEPTANCE", "epic 有 acceptance 标准"),
            Condition("EPIC_HAS_DESCRIPTION", "epic 有完整描述"),
        ]
    },
    "phase-2": {
        "next": "phase-3",
        "conditions": [
            Condition("DECISION_EXISTS", "至少有一个 design decision 已记录"),
        ]
    },
    "phase-3": {
        "next": "phase-4",
        "conditions": [
            Condition("TASKS_CREATED", "至少有一个 task 处于 ready 状态"),
            Condition("SETUP_SCRIPTS_RUN", "初始化脚本已执行"),
        ]
    },
    "phase-4": {
        "next": "phase-5",
        "conditions": [
            Condition("ALL_TASKS_CLOSED", "所有 task 均为 closed"),
        ],
        "loop": True  # 循环执行，不是一次转移
    },
    "phase-5": {
        "next": None,  # 终止状态
        "conditions": [
            Condition("GIT_PUSHED", "代码已推送"),
        ]
    }
}
```

---

## 四、门禁系统

### 4.1 Task 关闭条件

每个 task 要 close，必须满足以下条件（引擎硬编码检查，不是文档建议）：

```python
TASK_CLOSE_CONDITIONS = {
    "gitnexus_impact_checked": {
        "field": "gitnexus_impact_checked",
        "expected": True,
        "hint": "执行 devflow gate run-impact-analysis <task_id>",
        "phase": 4,
        "auto_fix": "devflow gate run-impact-analysis"
    },
    "verification_evidence": {
        "field": "verification_evidence",
        "expected": True,
        "hint": "执行 devflow gate run-verification <task_id>",
        "phase": 4,
        "auto_fix": "devflow gate run-verification"
    },
    "design_approved": {
        "field": "design_approved",
        "expected": True,
        "hint": "设计未批准，需要先完成 brainstorming 阶段的设计审批",
        "phase": 4,
        "auto_fix": None  # 需要人的介入
    },
    "security_checked": {
        "field": "security_checked",
        "expected": True,
        "hint": "执行 devflow gate run-security <task_id>",
        "phase": 4,
        "auto_fix": "devflow gate run-security",
        "optional": True  # 非安全敏感代码可跳过
    }
}
```

### 4.2 Gate 升级机制

```python
GATE_ESCALATION = {
    "max_retries": 3,          # 同一个 gate 最多失败 3 次
    "failure_window": 300,     # 5 分钟内连续失败算一次
    "on_escalate": "pause",    # 升级后暂停，等人介入
    "escalation_message": (
        "⚠️ 已检测到连续 {retries} 次 {gate_name} 未通过\n"
        "→ 建议: 需要你介入看一下\n"
        "→ 入口: 直接告诉我你的想法"
    )
}
```

---

## 五、工具编排

### 5.1 beads 适配器

```
职责:
  - 读取/写入 beads issue
  - 检查 gate 条件
  - 管理状态日志
  - 搜索和查询

接口:
  beads.get_epics() → list[Epic]
  beads.get_tasks(epic_id) → list[Task]
  beads.get_task(task_id) → Task
  beads.create_task(epic_id, title, description, acceptance) → Task
  beads.close_task(task_id, reason) → bool
  beads.update_gate_field(task_id, field, value) → bool
  beads.create_state_record(phase, step, transitions) → Record
  beads.search(query) → list[Issue]
```

### 5.2 gitnexus 适配器

```
职责:
  - 调用 gitnexus CLI 进行影响分析
  - 将分析结果写回 beads task 字段
  - 支持 Docker 降级（Windows SIGSEGV）

接口:
  gitnexus.analyze() → bool
  gitnexus.context(symbol, file) → ContextResult
  gitnexus.impact(symbol, depth) → ImpactResult
  gitnexus.detect_changes(scope) → ChangesResult
```

### 5.3 autoresearch 适配器

```
职责:
  - 调用 autoresearch skill/CLI
  - 将结果和日志写回 beads

接口:
  autoresearch.probe(task_id) → ProbeResult
  autoresearch.security(task_id) → SecurityResult  
  autoresearch.verify(task_id, command) → VerifyResult
```

---

## 六、Agent 交互示例

### agent 第一次进入项目

```
$ devflow state

Phase: 0 (未开始)

可用操作:
  1. devflow init       → 初始化项目
  2. devflow transition phase-1/start → 开始需求梳理
```

### agent 完成需求梳理后

```
$ devflow transition phase-1/complete

✅ Phase 1 → Phase 2 转移成功

自动操作:
  ✅ epub bd-0038 已创建
  ✅ design bd-0039 已创建

下一步:
  - 出技术设计方案
  - design approval 后运行 transition phase-2/complete
```

### agent 完成一个 task

```
$ devflow gate close bd-0042

❌ task bd-0042 不满足关闭条件

缺少 (2):
  1. gitnexus_impact_checked → false
     修复: devflow gate run-impact-analysis bd-0042
  2. verification_evidence → false
     修复: devflow gate run-verification bd-0042
```

### 连续失败升级

```
$ devflow gate run-impact-analysis bd-0042
❌ 失败: gitnexus 无法索引当前代码

$ devflow gate run-impact-analysis bd-0042
❌ 失败: gitnexus 索引损坏

$ devflow gate run-impact-analysis bd-0042
❌ 失败: gitnexus Docker 也无法运行

⚠️ 已检测到连续 3 次 gitnexus_impact_checked 未通过
→ 建议: 需要你介入看看 gitnexus 的问题
→ 入口: 直接告诉我你的想法
```

---

## 七、项目结构

```
devflow/
├── engine/
│   ├── __init__.py
│   ├── state_machine.py    # 状态机定义 + 转移逻辑
│   ├── gates.py             # 门禁条件定义 + 检查逻辑
│   └── escalation.py        # 升级到人机制
├── protocols/
│   ├── __init__.py
│   ├── beads_adapter.py     # beads 工具封装
│   ├── gitnexus_adapter.py  # gitnexus 调用封装
│   └── autoresearch_adapter.py  # autoresearch 调用封装
├── storage/
│   ├── __init__.py
│   └── alias.json           # 别名缓存（非关键数据放文件）
├── cli/
│   ├── __init__.py
│   ├── main.py              # CLI 入口
│   ├── state_cmd.py         # devflow state 命令
│   ├── transition_cmd.py    # devflow transition 命令
│   ├── gate_cmd.py          # devflow gate 命令
│   └── task_cmd.py          # devflow task 命令
├── data/
│   └── phases.json          # Phase 定义（供 engine 读取）
├── hooks/
│   ├── state-check.sh       # 替代旧 hook 脚本（调用 devflow state）
│   └── state-check.ps1
├── pyproject.toml
├── setup.py
└── SKILL.md                 # 精简版，只做路由到 devflow CLI
```

---

## 八、安装与使用

### 安装

```bash
# 全局安装
pip install devflow

# 在项目中初始化
cd my-project
devflow init
```

### `devflow init` 做了什么

1. 检查依赖（beads、gitnexus）
2. 运行 `bd init` 初始化 beads
3. 创建 `.devflow/` 目录（只存 hooks，不存 state）
4. 注册 PreToolUse hook（指向 devflow 引擎）
5. 注册 SessionStart hook（自动运行 devflow state）

### 安全与降级

- gitnexus Windows SIGSEGV → 自动切 Docker
- beads 不可用 → 降级到本地 JSON 文件
- 所有外部工具调用都有超时和重试
- 关键操作记录到 beads（可追溯）
