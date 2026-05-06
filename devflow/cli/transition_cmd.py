"""devflow transition 命令 — 状态转移。"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime
from pathlib import Path

from devflow.engine.state_machine import StateMachine
from devflow.protocols.beads_adapter import BeadsAdapter


def run_transition(args: argparse.Namespace):
    """执行状态转移。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)
    sm = StateMachine()

    current_id = bead_adapter.get_current_phase() or sm.entry

    if not args.target:
        # 无目标参数时显示可用转移
        state = sm.get_state(bead_adapter)
        transitions = state.get("available_transitions", [])

        print(f"\n  当前: {state['phase']} — {state['phase_name']}\n")
        if transitions:
            print(f"  可用转移:")
            for t in transitions:
                print(f"    devflow transition {t['label']}")
        else:
            print(f"  没有可用转移（终止状态或条件未满足）")
        print()
        return

    # 解析目标
    if args.target == f"{current_id}/complete":
        target_phase = sm.get_next_phase_id(current_id)
        if not target_phase:
            print(f"  ❌ {current_id} 没有后续阶段（终止状态）")
            sys.exit(1)
    elif args.target.endswith("/start"):
        target_id = args.target.split("/start")[0]
        if target_id not in sm.phases:
            print(f"  ❌ 未知目标阶段: {target_id}")
            sys.exit(1)
        if not current_id or sm.get_next_phase_id(current_id) != target_id:
            print(f"  ❌ 不能从 {current_id} 跳转到 {target_id}（只能进入下一个阶段）")
            sys.exit(1)
        target_phase = target_id
    else:
        print(f"  ❌ 无效的目标格式: {args.target}")
        print(f"    格式: phase-N/start 或 phase-N/complete")
        sys.exit(1)

    # 检查条件
    if not args.dry_run:
        can, failed = sm.can_transition(current_id, bead_adapter)
    else:
        can, failed = True, []
        _ = sm.get_state(bead_adapter)  # 只是验证阶段存在

    if not can:
        print(f"\n  ❌ 无法从 {current_id} 转移到 {target_phase}\n")
        print(f"  不满足的条件:")
        for f in failed:
            print(f"    ❌ {f.id}: {f.description}")
            if f.hint:
                print(f"       → {f.hint}")
        print()
        sys.exit(1)

    # 执行转移
    target_name = sm.get_phase(target_phase).name if sm.get_phase(target_phase) else target_phase

    print(f"\n  ✅ 状态转移: {current_id} → {target_phase}")
    print(f"     进入: {target_name}\n")

    # 记录到 beads
    if not args.dry_run:
        bead_adapter.create_state_record(
            target_phase,
            f"transition: {current_id} → {target_phase} at {datetime.now().isoformat()}"
        )
        print(f"  💾 状态记录已保存到 beads\n")

    # 阶段特定提示 + 自动触发
    tips = {
        "phase-1": "  开始需求梳理。\n",
        "phase-2": "  出技术设计方案。记录设计决策到 beads。\n",
        "phase-3": "  项目初始化中。运行 devflow init 确保环境就绪。\n",
        "phase-4": "  开发循环开始。运行 devflow task list 查看待办任务。\n",
        "phase-5": "  收尾阶段。完成后运行 git push。\n",
    }
    tip = tips.get(target_phase, "")
    if tip:
        print(tip)

    # 进入 phase-1 时自动启动 ideate
    if target_phase == "phase-1" and not args.dry_run:
        try:
            from devflow.cli.ideate_cmd import run_ideate
            _ideate_args = argparse.Namespace(
                path=str(project_path),
                resume=False,
                force=False,
                func=lambda x: None,
            )
            run_ideate(_ideate_args)
        except Exception as e:
            print(f"  ⚠️  ideate 启动失败: {e}")
