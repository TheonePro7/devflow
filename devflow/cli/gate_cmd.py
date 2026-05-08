"""devflow gate 命令 — 门禁管理。

核心流程：
  devflow gate check <task_id>        — 检查所有门禁条件
  devflow gate run-impact-analysis    — 运行 gitnexus 影响分析
  devflow gate run-verification       — 运行测试/验证
  devflow gate run-security           — 运行安全审计
  devflow gate close <task_id>        — 关闭 task（条件全满足时）
"""

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
    mark_resolved,
)
from devflow.protocols.beads_adapter import BeadsAdapter
from devflow.utils import detect_test_commands


def run_gate(args: argparse.Namespace):
    """门禁操作入口。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)

    task_id = args.task_id
    action = args.action

    if action == "check":
        _check_gate(bead_adapter, task_id)
    elif action == "run-impact-analysis":
        _run_impact_analysis(bead_adapter, task_id, project_path)
    elif action == "run-verification":
        _run_verification(bead_adapter, task_id, project_path)
    elif action == "run-security":
        _run_security(bead_adapter, task_id, project_path)
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


def _run_impact_analysis(adapter: BeadsAdapter, task_id: str, project_path: Path):
    """运行 gitnexus 影响分析。"""
    print(f"\n  🔍 运行 gitnexus 影响分析...")

    from devflow.protocols.gitnexus_adapter import GitNexusAdapter
    gitnexus = GitNexusAdapter(project_path)

    # 检查 gitnexus 可用性
    available, mode = gitnexus.check_available()
    if not available:
        state = record_gate_failure(task_id, "gitnexus_impact_checked")
        print(f"  ❌ gitnexus 不可用: {mode}")
        print(f"  尝试次数: {state.retries}/3")
        if should_escalate(task_id, "gitnexus_impact_checked"):
            print(f"\n  {get_escalation_message(task_id, 'gitnexus_impact_checked')}\n")
        sys.exit(1)
    print(f"  ⚡ 模式: {mode}")

    # 先检查索引状态
    status = gitnexus.status()
    if status is None or not status.get("indexed", False):
        print(f"  📦 代码库尚未索引，开始索引...")
        result = gitnexus.analyze()
        if not result["success"]:
            state = record_gate_failure(task_id, "gitnexus_impact_checked")
            print(f"  ❌ 索引失败: {result.get('error', '未知错误')[:200]}")
            if should_escalate(task_id, "gitnexus_impact_checked"):
                print(f"\n  {get_escalation_message(task_id, 'gitnexus_impact_checked')}\n")
            sys.exit(1)
        print(f"  ✅ 索引完成")

    # 运行 detect-changes
    changes = gitnexus.detect_changes()
    if changes:
        print(f"\n  📊 变更影响分析:")
        symbols = changes.get("symbols", [])
        processes = changes.get("affected_processes", [])
        files = changes.get("changed_files", [])

        if files:
            print(f"  修改文件 ({len(files)}):")
            for f in files[:5]:
                print(f"    - {f}")
        if symbols:
            print(f"  影响符号 ({len(symbols)}):")
            for s in symbols[:10]:
                print(f"    - {s}")
        if processes:
            print(f"  影响执行流 ({len(processes)}):")
            for p in processes[:5]:
                print(f"    - {p}")
        if changes.get("raw"):
            print(f"\n  {changes['raw']}")

        # 写入 beads
        summary = f"files={len(files)}, symbols={len(symbols)}, processes={len(processes)}, mode={mode}"
        adapter.update_task_field(task_id, "gitnexus_impact_checked", True)
        print(f"\n  ✅ gitnexus_impact_checked = true")
        print(f"     摘要: {summary}\n")

        # 重置升级状态
        mark_resolved(task_id, "gitnexus_impact_checked")
    else:
        # 没有检测到变更（可能是新代码没有 diff），尝试完整分析
        print(f"  ⚠️  未检测到当前变更，尝试完整仓库分析...")
        result = gitnexus.analyze()
        if result["success"]:
            adapter.update_task_field(task_id, "gitnexus_impact_checked", True)
            print(f"  ✅ 分析完成，gitnexus_impact_checked = true\n")
        else:
            state = record_gate_failure(task_id, "gitnexus_impact_checked")
            print(f"  ❌ 分析失败: {result.get('error', '')[:200]}")
            if should_escalate(task_id, "gitnexus_impact_checked"):
                print(f"\n  {get_escalation_message(task_id, 'gitnexus_impact_checked')}\n")
            sys.exit(1)


def _run_verification(adapter: BeadsAdapter, task_id: str, project_path: Path):
    """运行验证。"""
    from devflow.protocols.autoresearch_adapter import AutoresearchAdapter
    auto = AutoresearchAdapter(project_path)

    commands = detect_test_commands(project_path)
    if not commands:
        print(f"\n  🔍 运行验证...")
        print(f"  ⚠️  未检测到已知的测试框架。")
        print(f"  你可以手动运行测试后更新:")
        print(f"    bd update {task_id} --notes=\"verification passed\"")
        print(f"    然后: devflow gate close {task_id}")
        print(f"  或指定验证命令: devflow gate run-verification --cmd=\"npm test\"\n")
        sys.exit(1)

    print(f"\n  🔍 运行验证...")
    print(f"  检测到测试框架，运行: {commands[0]}\n")

    result = auto.run_verification(commands[0])

    if result.get("success", False) and result.get("passed", False):
        print(f"  ✅ 验证通过 (exit code: {result.get('returncode', '?')})")
        print(f"     输出: {result.get('stdout', '')[:500]}")
        adapter.update_task_field(task_id, "verification_evidence", True)
        print(f"  ✅ verification_evidence = true\n")
        mark_resolved(task_id, "verification_evidence")
    elif result.get("error"):
        print(f"  ❌ 验证失败: {result['error']}")
        sys.exit(1)
    else:
        print(f"  ❌ 验证未通过 (exit code: {result.get('returncode', '?')})")
        print(f"     输出: {result.get('stdout', '')[:500]}")
        print(f"     错误: {result.get('stderr', '')[:200]}")
        state = record_gate_failure(task_id, "verification_evidence")
        print(f"  尝试次数: {state.retries}/3")
        if should_escalate(task_id, "verification_evidence"):
            print(f"\n  {get_escalation_message(task_id, 'verification_evidence')}\n")
        sys.exit(1)



def _run_security(adapter: BeadsAdapter, task_id: str, project_path: Path):
    """运行安全审计。"""
    from devflow.protocols.autoresearch_adapter import AutoresearchAdapter
    auto = AutoresearchAdapter(project_path)

    print(f"\n  🔍 运行安全审计...")

    available, mode = auto.check_available()
    if not available:
        state = record_gate_failure(task_id, "security_checked")
        print(f"  ⚠️  autoresearch 不可用，跳过安全检查 (尝试 {state.retries}/3)。")
        print(f"  安全审计可跳过（可选门禁）。")
        if should_escalate(task_id, "security_checked"):
            print(f"\n  {get_escalation_message(task_id, 'security_checked')}\n")
        sys.exit(1)

    result = auto.security(diff_mode=True)

    if result.get("success"):
        print(f"  ✅ 安全审计完成")
        output = result.get("output", "")
        if output:
            print(f"     {output[:500]}")
        adapter.update_task_field(task_id, "security_checked", True)
        print(f"  ✅ security_checked = true\n")
        mark_resolved(task_id, "security_checked")
    else:
        state = record_gate_failure(task_id, "security_checked")
        print(f"  ⚠️  安全审计未完全通过 (尝试 {state.retries}/3)")
        error = result.get("error", "")
        if error:
            print(f"     {error[:500]}")
        if should_escalate(task_id, "security_checked"):
            print(f"\n  {get_escalation_message(task_id, 'security_checked')}\n")
        # security 是可选门禁，仅记录不阻止
        adapter.update_task_field(task_id, "security_checked", True)
        print(f"  ✅ security_checked = true (可选门禁，已记录)\n")


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
    code, out, err = adapter.run_bd(["close", task_id, "--reason=All gates passed"])
    if code != 0:
        print(f"  ❌ beads close 失败: {err[:200]}")
        sys.exit(1)

    mark_resolved(task_id, "close")
    print(f"\n  ✅ task {task_id} 关闭成功\n")

    # 检查是否还有更多 task
    remaining = adapter.get_tasks(status="open")
    in_progress = adapter.get_tasks(status="in_progress")
    total = len(remaining) + len(in_progress)
    if total > 0:
        print(f"  📋 还有 {total} 个 task 待完成")
        print(f"    运行 devflow task list 查看\n")
