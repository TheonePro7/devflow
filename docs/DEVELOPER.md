# devflow 开发者指南

> 如何理解、扩展和维护 devflow Python CLI 引擎。

---

## 一、开发环境

```bash
# 克隆
git clone https://github.com/TheonePro7/devflow.git
cd devflow

# 安装为可编辑包（推荐）
pip install -e .

# 验证
devflow --version  # → devflow 1.0.0
devflow state      # → 当前阶段
```

### 运行测试

```bash
pytest tests/ -v                # 全部测试
pytest tests/test_state_machine.py -v  # 状态机
pytest tests/test_gates.py -v         # 门禁
pytest tests/test_escalation.py -v    # 升级
pytest tests/test_integration.py -v   # 集成测试
```

### 代码规范

- Python 3.10+（使用 `from __future__ import annotations`）
- 类型标注全覆盖
- argparse CLI 框架（零外部依赖）
- pytest 测试

---

## 二、项目结构速览

```
devflow/
├── __init__.py              # 空
├── utils.py                 # 工具函数
├── data/
│   └── phases.json          # 配置: 5 phase + 条件 + 流转
├── engine/
│   ├── state_machine.py     # StateMachine 类
│   ├── gates.py             # Gate 条件定义 + 检查
│   └── escalation.py        # 3 次重试升级
├── cli/
│   ├── main.py              # 入口: argparse 路由
│   ├── state_cmd.py         # devflow state
│   ├── transition_cmd.py    # devflow transition
│   ├── gate_cmd.py          # devflow gate
│   ├── task_cmd.py          # devflow task
│   ├── dev_cmd.py           # devflow dev
│   ├── init_cmd.py          # devflow init
│   ├── ideate_cmd.py        # devflow ideate
│   ├── prd_cmd.py           # devflow prd
│   ├── doctor_cmd.py        # devflow doctor
│   ├── sync_cmd.py          # devflow sync
│   ├── log_cmd.py           # devflow log
│   ├── bootstrap_cmd.py     # devflow bootstrap
│   └── help_cmd.py          # devflow guide
└── protocols/
    ├── beads_adapter.py     # beads 适配器 + 本地降级
    ├── gitnexus_adapter.py  # gitnexus 适配器 + Docker 降级
    └── autoresearch_adapter.py  # autoresearch 适配器
tests/
├── test_state_machine.py
├── test_gates.py
├── test_escalation.py
└── test_integration.py
```

---

## 三、核心模式：3 层架构

### CLI Layer（命令层）

**模式**：每个文件一个命令，只有一个导出函数 `run_xxx(args: argparse.Namespace)`。

```python
"""devflow xxx 命令 — 一句话说明功能。"""
from __future__ import annotations
import argparse
from pathlib import Path
from devflow.protocols.beads_adapter import BeadsAdapter

def run_xxx(args: argparse.Namespace):
    project_path = Path(args.path) if args.path else Path.cwd()
    adapter = BeadsAdapter(project_path)
    # 实现逻辑...
```

**注册新命令**：在 `devflow/cli/main.py` 的 `main()` 函数中添加：

```python
p_xxx = subparsers.add_parser("xxx", help="XXX 功能")
p_xxx.add_argument("--flag", ...)
p_xxx.set_defaults(func=run_xxx)
```

并在文件顶部 import：`from devflow.cli.xxx_cmd import run_xxx`

### Engine Layer（引擎层）

两层引擎：**状态机** + **门禁系统**。

#### StateMachine（状态机）

- 从 `phases.json` 加载所有 phase 定义
- `get_state(adapter)` → 当前 phase + 条件 + 可用转移
- `can_transition(phase_id, adapter)` → 检查所有出口条件
- 条件检测委托给 `BeadsAdapter.check_condition()`

#### Gates（门禁）

- 4 个硬编码条件（`gates.py:TASK_CLOSE_CONDITIONS`）
- `can_close_task(task_dict, adapter)` → bool + 详细结果
- `record_gate_failure()` + `should_escalate()` → 3 次失败升级

### Protocols Layer（适配器层）

每个适配器封装外部工具，提供统一接口。

**关键约束**：

1. **所有 subprocess.run 必须带编码**：`encoding="utf-8", errors="replace"`
2. **所有 npx 调用必须带 --yes**：避免交互弹窗挂起
3. **fail-fast vs fail-soft**: beads 不可用降级到文件；gitnexus 不可用跳过；autoresearch 不可用跳过

---

## 四、初始化流程

```
用户运行 `devflow init` 或 `devflow bootstrap`
    │
    ├── [1/4] beads
    │   ├── 检查 `where bd` (Windows) / `which bd` (Linux)
    │   ├── 已安装 → `bd init --quiet`
    │   └── 未安装 → `go install github.com/steveyegge/beads/cmd/bd@latest`
    │
    ├── [2/4] gitnexus
    │   ├── `npx --yes gitnexus --help` (原生)
    │   └── `docker run ... gitnexus --help` (Docker 降级)
    │
    ├── [3/4] autoresearch
    │   └── `npx --yes skills add uditgoenka/autoresearch`
    │
    └── [4/4] .devflow/ 目录 + 状态记录
        └── beads create_state_record("phase-0", "init: devflow initialized")
```

`bootstrap` 是 `init → doctor → transition phase-1/start` 的快捷方式。

---

## 五、常见扩展场景

### 场景 1：添加新的 Phase 出口条件

**例子**：要求在 Phase 2 出口时必须有 UX 设计稿。

1. **phases.json** 的 `"phase-2"` conditions 添加 `"UX_DESIGN_EXISTS"`
2. **beads_adapter.py** 的 `check_condition()` 添加分支：

```python
elif condition_id == "UX_DESIGN_EXISTS":
    return (project_path / "docs/ux").exists() and any(
        (project_path / "docs/ux").iterdir()
    )
```

3. **测试**：添加 `test_condition_ux_design()` 到 `test_state_machine.py`

### 场景 2：添加新的 Gate 条件

**例子**：要求 task close 前必须通过 lint。

1. **gates.py** 的 `TASK_CLOSE_CONDITIONS` 添加：

```python
GateCondition(
    id="lint_passed",
    field="lint_passed",
    expected=True,
    hint="运行 linter: flake8 ...",
    auto_fix="devflow gate run-lint",
)
```

2. **gate_cmd.py** 添加 `_run_lint(adapter, task_id, project_path)` 方法

3. **注册到 `run_gate()`**：添加 `"run-lint"` 到 action choices

### 场景 3：添加新的 CLI 命令

1. 创建 `devflow/cli/xxx_cmd.py`
2. 实现 `run_xxx(args)` 函数
3. 在 `main.py` 注册子命令 + import
4. 添加测试到 `tests/`

### 场景 4：添加新的工具适配器

1. 创建 `devflow/protocols/xxx_adapter.py`
2. 实现 `is_available()` + `check_available()` 方法
3. 实现核心功能方法
4. 确保所有 subprocess.run 有编码设置
5. 在 `doctor_cmd.py` 和 `sync_cmd.py` 注册检查

---

## 六、Windows 兼容性清单

devflow 同时支持 Windows 和 Linux/macOS。以下是在 Windows 上的特殊处理：

| 问题 | 解决方案 | 涉及文件 |
|---|---|---|
| `subprocess.run` GBK 崩溃 | `encoding="utf-8", errors="replace"` | 所有含 subprocess 的文件 |
| npx 交互弹窗 | `--yes` 标志 | 所有 npx 调用 |
| PowerShell Set-Content BOM | `encoding="utf-8-sig"` | `beads_adapter.py` |
| 路径分隔符 | `Path` 对象（不用字符串拼接） | 所有文件 |
| CGO_ENABLED=0 bd.exe | 优先 `.cmd` 而非 `.exe` | `beads_adapter.py` |
| gitnexus SIGSEGV | Docker 降级 | `gitnexus_adapter.py` |

---

## 七、测试指南

### 状态机测试（`test_state_machine.py`）

测试 phase 定义加载、条件检查、转移逻辑。不依赖外部工具——只测 StateMachine 类本身。

### 门禁测试（`test_gates.py`）

测试条件检查逻辑、failed 条件筛选、升级阈值。不依赖外部工具。

### 升级测试（`test_escalation.py`）

测试 3 次失败升级、resolved 重置、消息生成。

### 集成测试（`test_integration.py`）

通过 `subprocess.run` 调用 CLI 测试完整流程。注意：
- 不使用 `main()` 直接调用（避免 stdout 污染）
- 使用 `TemporaryDirectory` 隔离状态文件
- 测试 state/transition/gate 等关键路径

---

## 八、发布

```bash
# 更新版本号
# 提交 + 打 tag
git tag v0.1.1
git push --tags

# pip 包发布（如果需要）
python -m build
python -m twine upload dist/*
```
