# Devflow Engine 设计文档

> 状态: **已实现** | 最后更新: 2026-05-07 (v2)
> 对应版本: devflow v1.0.0 (Python CLI)

---

## 一、概述

Devflow Engine 是一个 Python CLI 工具，为 AI 编码代理提供结构化的产品开发工作流。它不是一个"脚手架生成器"，而是一个**自主工程引擎**——给定一个模糊的想法，它能引导 agent 从需求梳理到代码交付完整走完。

### 核心哲学

- **人提供方向，agent 提供执行，引擎提供纪律**
- 约束必须架构化，不能靠 agent 的自觉
- 数据必须贯通，不能靠 agent 的记忆
- 流程必须自主推进，不能等人按按钮
- 人只参与两件事：需求对焦 + 最终验收

### 与 superpowers 的职责划分

devflow 不做 superpowers 已做的事，而是在正确的时间点注入增强：

| superpowers skill | devflow 的参与 |
|---|---|
| brainstorming | ① 注入 beads epic + gitnexus context + CONTEXT.md |
| plan-grill **(devflow 专有)** | ①½ 新增环节，使用 CONTEXT.md + ADR + gitnexus |
| writing-plans | ② 注入 beads sub-issues + gitnexus impact + PRD→beads |
| subagent-driven-development | ③ 注入 gitnexus context + beads ready + TDD docs |
| code-review | 不参与 |
| finish-branch | 不参与 |
| TDD | docs/tdd/ 深度文档作为参考 |

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
│  ┌──────────────────────────────────────┐   │
│  │              CLI Layer                │   │
│  │  main.py → argparse 路由 (15 命令)    │   │
│  │  cli/*_cmd.py → 每个命令的 run_*()    │   │
│  ├──────────────────────────────────────┤   │
│  │            Engine Layer               │   │
│  │  state_machine.py → 5-Phase 状态机   │   │
│  │  gates.py → 4 条件门禁 + 3-重试升级   │   │
│  │  escalation.py → 连续失败暂停到人      │   │
│  ├──────────────────────────────────────┤   │
│  │          Protocols Layer               │   │
│  │  beads_adapter.py → 持久化 (CLI→文件) │   │
│  │  gitnexus_adapter.py → 代码图谱       │   │
│  │  autoresearch_adapter.py → 质量闭环   │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│              External Tools                  │
│  beads (Dolt issue tracker)                 │
│  gitnexus (code knowledge graph)            │
│  autoresearch (autonomous iteration loop)   │
│  superpowers-* (14 Claude Code skills)      │
└─────────────────────────────────────────────┘
```

### 包结构

```
devflow/
├── __init__.py             # 包标识
├── utils.py                # 共享工具函数 (detect_test_commands)
├── data/
│   └── phases.json         # 5-Phase 定义 + 条件 + 流转
├── engine/
│   ├── __init__.py
│   ├── state_machine.py    # Phase/ConditionResult/StateMachine
│   ├── gates.py            # GateCondition/GateResult/门禁检查
│   └── escalation.py       # EscalationRecord/3-重试升级
├── cli/
│   ├── __init__.py
│   ├── main.py             # argparse 入口, 15 子命令
│   ├── state_cmd.py        # devflow state
│   ├── transition_cmd.py   # devflow transition
│   ├── gate_cmd.py         # devflow gate (check/close/run-*)
│   ├── task_cmd.py         # devflow task (create/list/show)
│   ├── dev_cmd.py          # devflow dev (start/finish/next/status)
│   ├── init_cmd.py         # devflow init
│   ├── ideate_cmd.py       # devflow ideate (4 阶段需求梳理)
│   ├── prd_cmd.py          # devflow prd (ideate→PRD markdown)
│   ├── doctor_cmd.py       # devflow doctor (环境诊断)
│   ├── sync_cmd.py         # devflow sync (工具状态同步)
│   ├── log_cmd.py          # devflow log (状态时间线)
│   ├── bootstrap_cmd.py    # devflow bootstrap (新项目快速开始)
│   └── help_cmd.py         # devflow guide (工作流地图)
├── protocols/
│   ├── __init__.py
│   ├── beads_adapter.py        # beads 适配器 (CLI + 本地降级)
│   ├── gitnexus_adapter.py     # gitnexus 适配器 (原生 + Docker)
│   └── autoresearch_adapter.py # autoresearch 适配器 (内置实现)
└── storage/                # 预留存储层
    └── __init__.py
```

---

## 三、状态机设计

### 3.1 5-Phase 定义

定义在 `devflow/data/phases.json`，由 `StateMachine` 类加载：

```json
{
  "phases": {
    "phase-0": { "name": "未初始化", "next": "phase-1", "auto_transition": true },
    "phase-1": { "name": "Ideate（需求梳理）", "next": "phase-2",
      "conditions": ["EPIC_EXISTS", "EPIC_HAS_ACCEPTANCE", "EPIC_HAS_DESCRIPTION"] },
    "phase-2": { "name": "Design（设计）", "next": "phase-3",
      "conditions": ["DECISION_EXISTS"] },
    "phase-3": { "name": "Setup（项目初始化）", "next": "phase-4",
      "conditions": ["TASKS_CREATED", "SETUP_SCRIPTS_RUN"], "auto_transition": true },
    "phase-4": { "name": "Develop（开发）", "next": "phase-5",
      "conditions": ["ALL_TASKS_CLOSED"], "loop": true },
    "phase-5": { "name": "Finish（收尾）", "next": null,
      "conditions": ["GIT_PUSHED"] }
  },
  "flow": { "entry": "phase-0", "terminal": "phase-5" }
}
```

### 3.2 Phase 流转

```
Phase-0 (未初始化)
  │  devflow init 或 devflow bootstrap
  ▼
Phase-1 (Ideate)
  │  agent 追问: 目标用户/场景/痛点/成功标准
  │  输出: .devflow/ideate.json → beads epic → PRD markdown
  │  出口条件: epic exists + has acceptance + has description
  ▼
Phase-2 (Design)
  │  agent 出技术方案 + 架构 + UI 设计
  │  输出: beads decisions + design docs
  │  出口条件: decision exists
  ▼
Phase-3 (Setup)
  │  自动: beads init → gitnexus analyze → hooks 注册
  │  出口条件: tasks created + setup scripts run
  ▼
Phase-4 (Develop) ←── 循环
  │  task → impl → gate close → next task
  │  门禁: gitnexus impact + verification + design approval + security
  │  出口条件: ALL_TASKS_CLOSED
  ▼
Phase-5 (Finish)
  │  beads close → git push → 报告
  │  出口条件: GIT_PUSHED
```

### 3.3 核心接口

```python
class StateMachine:
    def __init__(self, phases_path: Optional[Path] = None)
    def get_phase(self, phase_id: str) -> Optional[Phase]
    def get_next_phase_id(self, current_id: str) -> Optional[str]
    def can_transition(self, current_id: str, bead_adapter) -> tuple[bool, list[ConditionResult]]
    def get_available_transitions(self, current_id: str) -> list[dict]
    def get_state(self, bead_adapter) -> dict  # get whole state snapshot

class ConditionResult:
    id: str       # e.g. "EPIC_EXISTS"
    description: str
    met: bool
    hint: str     # what to do if not met
```

### 3.4 条件检测

每个条件 ID 对应 `BeadsAdapter.check_condition()` 中的真实检测逻辑：

| ID | 检测方式 | 说明 |
|---|---|---|
| `EPIC_EXISTS` | `bd list --type=epic --status=open --json` | 有 open epic |
| `EPIC_HAS_ACCEPTANCE` | epic 对象的 `acceptance` 字段非空 | 有验收标准 |
| `EPIC_HAS_DESCRIPTION` | epic 对象的 `description` 字段非空 | 有描述 |
| `DECISION_EXISTS` | `_check_local_json("decisions")` | 有设计决策 |
| `TASKS_CREATED` | `bd list --type=task --status=open --json` | 有 open task |
| `SETUP_SCRIPTS_RUN` | `.devflow/` 目录存在 | 已初始化 |
| `ALL_TASKS_CLOSED` | 无 open/in_progress task | 全完成 |
| `GIT_PUSHED` | `git log origin/main..HEAD` 为空 | 已推送 |

---

## 四、门禁系统

### 4.1 4 个 Task 关闭条件

定义在 `devflow/engine/gates.py`，每个 task close 前必须检查：

| 条件 ID | 强制 | 自动修复 | 说明 |
|---|---|---|---|
| `gitnexus_impact_checked` | 是 | `devflow gate run-impact-analysis` | 影响范围分析 |
| `verification_evidence` | 是 | `devflow gate run-verification` | 测试/验证通过 |
| `design_approved` | 是 | 无（需要人介入） | 设计审批 |
| `security_checked` | 可选 | `devflow gate run-security` | 安全审计 |

可选的 `security_checked` ：非安全敏感代码可跳过，不影响 task 关闭。

### 4.2 执行流程

```
devflow gate check <task_id>
    → 读取 task 的 4 个 gate 字段
    → 逐一比较 expected=True vs actual value
    → 输出: 每项 ✅ / ❌ / ⬜(optional)
    → 失败则打印 hint + auto_fix 命令

devflow gate run-impact-analysis <task_id>
    → 检查 gitnexus 可用性
    → 索引代码库 (如未索引)
    → 运行 detect-changes
    → 写回 beads: gitnexus_impact_checked = True

devflow gate run-verification <task_id>
    → detect_test_commands() 自动检测框架
    → 通过 autoresearch 运行验证
    → 写回 beads: verification_evidence = True

devflow gate run-security <task_id>
    → 调用 autoresearch.security()
    → 写回 beads: security_checked = True

devflow gate close <task_id>
    → 检查所有条件
    → 满足 → bd close
    → 不满足 → 打印缺什么
```

### 4.3 3-重试升级机制

定义在 `devflow/engine/escalation.py`：

```
同一个 gate 连续失败 3 次 → 升级到人
    └─ 输出: "⚠️ 已检测到连续 N 次 {gate} 未通过"
    └─ "→ 需要你介入看一下"
    └─ "→ 入口: 直接告诉我你的想法"
    └─ 人确认后 → mark_resolved() 重置状态
```

升级状态持久化到 `.devflow/escalation.json`（`EscalationStore` 类），进程重启不丢失。
未指定 `project_path` 时使用内存模式（单元测试用）。
`gates.py` 的 `record_gate_failure` 委托给 `escalation.py`，两套代码已合并。

---

## 五、CLI 命令参考

| 命令 | 功能 | 关键参数 |
|---|---|---|
| `devflow state` | 显示当前阶段、条件、可用操作 | `--path` |
| `devflow init` | 初始化项目（自动安装工具） | `--path`, `--force`, `--skip-beads` |
| `devflow transition` | 状态转移（前进需条件检查，回退自由通行） | `--path`, `--dry-run`, `target` |
| `devflow gate` | 门禁管理 | `action={check,close,run-*}` |
| `devflow task` | 任务管理 | `action={create,list,show}` |
| `devflow dev` | 开发循环自动化 | `action={start,finish,next,status}` |
| `devflow ideate` | 4 阶段需求梳理引导 | `--resume`, `--force` |
| `devflow prd` | ideate→PRD markdown | `--title`, `--force` |
| `devflow doctor` | 一键环境诊断 | `--fix` |
| `devflow sync` | 工具状态同步 | `--path` |
| `devflow log` | 状态时间线 | `--tail`, `--json` |
| `devflow bootstrap` | 新项目快速开始 | `--path` |
| `devflow guide` | 工作流地图 | — |

---

## 六、工具适配器

### 6.1 BeadsAdapter — 持久化层

**核心职责**：Phase 存储、条件检测、任务管理。

**双模运行**：
- **beads CLI 可用**：通过 `bd` 子进程读写 issue
- **降级到本地文件**：`.devflow/state.json` + `.devflow/state.log` + `.devflow/tasks.json` + `.devflow/epics.json` + `.devflow/decisions.json`

**Windows 特殊处理**：
- `_find_bd()` 优先选择 `.cmd`（npm 安装，无 CGO 问题）而非 `.exe`（Go 编译，CGO_ENABLED=0 无法打开 Dolt 嵌入 DB）
- 所有 `subprocess.run` 必须设置 `encoding="utf-8", errors="replace"`（防 GBK 解码崩溃）
- 本地文件读取使用 `encoding="utf-8-sig"`（兼容 PowerShell 的 BOM）

**Phase 存储方案**：
- beads 中创建 title 为 `"state:phase-X"` 的 issue
- `get_current_phase()` 解析 title 前缀 `"state:"` 提取 phase ID
- 初始创建 `create_state_record()` 写入 beads + 本地 state.json + state.log

### 6.2 GitNexusAdapter — 代码知识图谱

**核心职责**：影响分析、符号上下文、变更检测。

**双模运行**：
1. **原生模式**: `npx --yes gitnexus`（Linux/macOS 首选）
2. **Docker 模式**: `docker run ghcr.io/abhigyanpatwari/gitnexus:latest`（Windows 首选）

**Windows SIGSEGV 解决方案**：
- gitnexus 在 Windows/Node 22 下 tree-sitter 原生模块 crash（exit code 139）
- Docker 容器内 Linux 环境下 tree-sitter 正常运行
- `_run()` 方法自动检测：原生失败且含 SIGSEGV 标志 → 切 Docker
- Docker 路径映射：`F:\AI\devflow` → `/f/AI/devflow`

**核心方法**：
- `analyze(force=False)` — 索引仓库
- `context(symbol, file_path)` — 符号 360 视图
- `impact(target, depth, include_tests)` — 影响范围
- `detect_changes(scope)` — 当前变更检测
- `status()` — 索引状态

### 6.3 AutoResearchAdapter — 质量闭环

**核心职责**：安全审计、测试验证、优化循环。

**注意**：autoresearch 本身是 SKILL.md（prompt 集合），不是可执行 CLI。
因此适配器不依赖 `npx skills run`，而是直接内置实现核心逻辑：

**核心方法**：
- `probe(context)` — 返回提示信息，引导上层用子代理加载 autoresearch SKILL.md
- `security(diff_mode)` — **内置实现**：扫描 shell=True 调用、敏感文件不在 .gitignore 等
- `optimize(goal, n_iterations)` — 返回提示信息，引导上层启动子代理
- `fix()` — 返回提示信息
- `debug(symptom)` — 返回提示信息
- `run_verification(command)` — **保留**：直接运行测试/构建命令（不依赖 autoresearch）

**所有 subprocess.run 必须**：`encoding="utf-8", errors="replace"`

---

## 七、编码约定

### 7.1 Windows 编码（反复踩坑总结）

```python
# 所有子进程调用必须设置编码（否则 GBK 崩溃）
subprocess.run(..., encoding="utf-8", errors="replace")

# 所有 npx 调用必须加 --yes（否则交互弹窗挂起）
subprocess.run(["npx", "--yes", ...])

# PowerShell 写入的文件有 BOM，读取用 utf-8-sig
with open(path, "r", encoding="utf-8-sig") as f:
    json.load(f)
```

### 7.2 CLI 命令模式

每个命令模块遵循统一模式：

```python
"""devflow <name> 命令 — 一句话说明。"""
from __future__ import annotations
import argparse
from pathlib import Path
from devflow.protocols.beads_adapter import BeadsAdapter

def run_<name>(args: argparse.Namespace):
    project_path = Path(args.path) if args.path else Path.cwd()
    adapter = BeadsAdapter(project_path)
    # ... 实现逻辑
```

### 7.3 测试

位于 `tests/` 目录：
- `test_state_machine.py` — 状态机单元测试
- `test_gates.py` — 门禁单元测试
- `test_escalation.py` — 升级机制单元测试
- `test_integration.py` — 集成测试（用 subprocess 调用 CLI）

集成测试**不能**直接调用 `main()`，必须通过 `subprocess.run` 避免 stdout 污染。

### 7.4 Python 版本要求

- Python >= 3.10（使用了 `from __future__ import annotations` + `str \| None` 联合类型）
- 安装方式: `pip install -e .`

---

## 八、四层防御链

| 层级 | 位置 | 触发时机 | 作用 |
|---|---|---|---|
| Layer 0 | `~/.claude/settings.json` (SessionStart hook) | 全局会话启动 | 检测新项目，提示初始化 |
| Layer 1 | `SKILL.md` 顶部 NEW PROJECT DETECTION | agent 启动 | 自动运行 setup.sh |
| Layer 2 | `CLAUDE.md` 最高指示 | 全会话 | 强制先读 state，禁止跳步骤 |
| Layer 3 | 项目 hooks (UserPromptSubmit + PreToolUse) | 每条消息 / 每次编辑 | 注入状态提醒 + 拦截违规操作 |

---

## 九、与 SKILL.md 的关系

devflow CLI 是 SKILL.md 的升级替代。早期 devflow 完全依赖 SKILL.md 的 prompt 编排，
后来将核心逻辑（状态机、门禁、适配器）抽取为 Python CLI，SKILL.md 变为轻量 facade：

```
SKILL.md 现负责:
  - 新项目检测 → 自动 setup
  - 告诉 agent "运行 devflow state" 而不是手工检查
  - 5 条关键规则（不是完整流程）

devflow CLI 负责:
  - 状态管理 (state/transition)
  - 门禁检查 (gate)
  - 工具编排 (sync)
  - 需求梳理 (ideate)
  - 任务管理 (task/dev)
```

---

## 十、常见问题

### Q: beads 不可用时会发生什么？

所有功能降级到本地文件（`.devflow/*.json`）。`get_current_phase()` 从 `state.json` 读取，
`check_condition()` 中依赖 beads 的条件（如 `EPIC_EXISTS`）返回 `False`。

### Q: gitnexus 在 Windows 上 crash 怎么办？

Docker 模式自动接管。无需手动干预。`_run()` 方法检测到 exit code 139 或 SIGSEGV 后自动切换到 Docker。

### Q: 如何添加一个新的 phase 条件？

1. 在 `devflow/data/phases.json` 对应 phase 的 `conditions` 数组添加 `{"id": "NEW_CONDITION", ...}`
2. 在 `BeadsAdapter.check_condition()` 添加 `elif condition_id == "NEW_CONDITION":` 分支
3. 实现检测方法（如 `_check_new_condition()`）

### Q: 如何添加一个新的 CLI 命令？

1. 在 `devflow/cli/` 创建 `xxx_cmd.py`，实现 `run_xxx(args)` 函数
2. 在 `devflow/cli/main.py` 的 `main()` 函数中添加 argparse 子命令
3. 在 `main.py` 顶部添加 import
