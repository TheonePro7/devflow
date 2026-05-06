"""devflow state 命令 — 显示当前工程状态。"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from devflow.engine.state_machine import StateMachine
from devflow.protocols.beads_adapter import BeadsAdapter


def run_state(args: argparse.Namespace):
    """显示当前阶段、可用操作和条件状态。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)
    sm = StateMachine()

    state = sm.get_state(bead_adapter)

    if "error" in state:
        print(f"❌ {state['error']}")
        sys.exit(1)

    # Header
    phase_label = f"{state['phase']} — {state['phase_name']}"
    print(f"\n{'=' * 56}")
    print(f"  当前阶段: {phase_label}")
    print(f"{'=' * 56}\n")

    if state["description"]:
        print(f"  {state['description']}\n")

    # 条件状态
    conditions = state.get("conditions", [])
    if conditions:
        print(f"  ⚠️  出口条件未满足 ({len(conditions)}):")
        for c in conditions:
            print(f"    ❌ {c['id']}: {c['description']}")
            if c.get("hint"):
                print(f"       → {c['hint']}")
        print()

    # 可用转移
    transitions = state.get("available_transitions", [])
    if transitions:
        print(f"  可用操作:")
        for t in transitions:
            print(f"    devflow transition {t['label']}  — 进入 {t['to_name']}")
        print()

    # 如果 phase 是循环的且已满足条件
    if state.get("loop"):
        print(f"  当前是开发循环阶段。")
        print(f"    运行 devflow task list 查看待办 task")
        print(f"    运行 devflow gate check <task_id> 检查 task 状态")
        print()

    if state.get("phase") == "phase-0":
        print(f"  项目未初始化。运行 devflow init 开始。\n")
