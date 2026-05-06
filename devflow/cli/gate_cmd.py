"""devflow gate 命令 — 门禁管理。"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from devflow.engine.gates import (
    check_task_close_conditions,
    get_failed_conditions,
    record_gate_failure,
)
from devflow.engine.escalation import (
    should_escalate,
    get_escalation_message,
)
from devflow.engine.escalation import mark_resolved
from devflow.protocols.beads_adapter import BeadsAdapter


def run_gate(args: argparse.Namespace):
    """门禁操作入口。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)

    task_id = args.task_id
    action = args.action

    if action == "check":
        _check_gate(bead_adapter, task_id)
    elif action in ("run-impact-analysis", "run-verification", "run-security"):
        _run_gate(bead_adapter, task_id, action)
    elif action == "close":
        _close_task(bead_adapter, task_id)
    else:
        print(f"❌ 未知门禁操作: {action}")
        sys.exit(1)


def _check_gate(adapter: BeadsAdapter, task_id: str):
    """检查 task 的门禁条件。"""
    task = adapter.get_task(task_id)
    if not task:
        print(f"❌ task {task_id} 未找到")
        sys.exit(1)

    task_dict = {
        "gitnexus_impact_checked": task.get("gitnexus_impact_checked", False),
        "verification_evidence": task.get("verification_evidence", False),
        "design_approved": task.get("design_approved", False),
        "security_checked": task.get("security_checked", False),
    }

    results = check_task_close_conditions(task_dict, adapter)
    failed = get_failed_conditions(results)

    print(f"\n  🚪 门禁检查 — {task_id}\n")

    for r in results:
        status = "✅" if r.passed else ("⬜" if r.condition.optional else "❌")
        optional_tag = " (可选)" if r.condition.optional else ""
        print(f"  {status} {r.condition.id}{optional_tag}")

    if failed:
        print(f"\n  ⚠️  不满足的条件:")
        for f in failed:
            print(f"    ❌ {f.condition.id}")
            print(f"       → {f.condition.hint}")
            if f.condition.auto_fix:
                print(f"       修复: {f.condition.auto_fix} {task_id}")
        print()
        sys.exit(1)
    else:
        print(f"\n  ✅ 所有条件满足！可以关闭 task。\n")
        print(f"  运行: devflow gate close {task_id}\n")


def _run_gate(adapter: BeadsAdapter, task_id: str, action: str):
    """运行具体的门禁操作。"""
    if action == "run-impact-analysis":
        print(f"\n  🔍 运行 gitnexus 影响分析...")
        from devflow.protocols.gitnexus_adapter import GitNexusAdapter
        gitnexus = GitNexusAdapter()
        result = gitnexus.detect_changes()

        if result:
            print(f"  ✅ 影响分析完成")
            print(f"     {result.get('result', '')[:500]}")
            adapter.update_task_field(task_id, "gitnexus_impact_checked", True)
            print(f"  ✅ gitnexus_impact_checked = true\n")
        else:
            state = record_gate_failure(task_id, "gitnexus_impact_checked")
            print(f"  ❌ 影响分析失败 (第 {state.retries} 次)")
            if should_escalate(task_id, "gitnexus_impact_checked"):
                print(f"\n  {get_escalation_message(task_id, 'gitnexus_impact_checked')}\n")
            sys.exit(1)

    elif action == "run-verification":
        print(f"\n  🔍 运行验证...")
        print(f"  ⚠️  暂未实现自动验证。需要手动指定验证命令。")
        print(f"  你可以运行测试后手动更新:")
        print(f"    bd update {task_id} --verification_evidence=true\n")

    elif action == "run-security":
        print(f"\n  🔍 运行安全审计...")
        print(f"  ⚠️  暂未实现自动安全审计。")
        print(f"  跳过或手动运行后更新:\n")
        print(f"    bd update {task_id} --security_checked=true")
        print(f"    或: devflow gate run-security {task_id} 将在阶段二实现\n")


def _close_task(adapter: BeadsAdapter, task_id: str):
    """关闭 task（检查所有门禁条件后）。"""
    task = adapter.get_task(task_id)
    if not task:
        print(f"❌ task {task_id} 未找到")
        sys.exit(1)

    task_dict = {
        "gitnexus_impact_checked": task.get("gitnexus_impact_checked", False),
        "verification_evidence": task.get("verification_evidence", False),
        "design_approved": task.get("design_approved", False),
        "security_checked": task.get("security_checked", False),
    }

    results = check_task_close_conditions(task_dict, adapter)
    failed = get_failed_conditions(results)

    if failed:
        print(f"\n  ❌ task {task_id} 不满足关闭条件\n")
        for f in failed:
            print(f"    ❌ {f.condition.id} → false")
            print(f"       → {f.condition.hint}")
            if f.condition.auto_fix:
                print(f"       修复: {f.condition.auto_fix} {task_id}")
        print()
        sys.exit(1)

    # 全部条件满足，关闭
    adapter._run_bd(["close", task_id, "--reason=All gates passed"])
    mark_resolved(task_id, "close")
    print(f"\n  ✅ task {task_id} 关闭成功\n")
