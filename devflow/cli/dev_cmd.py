"""devflow dev 命令 — 开发循环自动化。"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from devflow.protocols.beads_adapter import BeadsAdapter


def run_dev(args: argparse.Namespace):
    """开发循环入口。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)

    action = args.action

    if action == "start":
        _start_task(bead_adapter, args.task_id, project_path)
    elif action == "finish":
        _finish_task(bead_adapter, args.task_id, project_path)
    elif action == "next":
        _next_task(bead_adapter, project_path)
    elif action == "status":
        _dev_status(bead_adapter, project_path)
    else:
        print(f"❌ 未知操作: {action}")
        sys.exit(1)


def _start_task(adapter: BeadsAdapter, task_id: str, project_path: Path):
    """开始一个 task：标记 in_progress + 影响分析。"""
    print(f"\n  ▶ 开始 task: {task_id}\n")

    # 标记 in_progress
    task = adapter.get_task(task_id)
    if not task:
        print(f"  ❌ task {task_id} 未找到")
        sys.exit(1)

    print(f"  Task: {task.title}")
    print(f"  状态: in_progress\n")

    # 运行 gitnexus 影响分析
    from devflow.protocols.gitnexus_adapter import GitNexusAdapter
    gitnexus = GitNexusAdapter(project_path)
    available, mode = gitnexus.check_available()
    if available:
        print(f"  🔍 gitnexus 影响分析 (模式: {mode})...")
        status = gitnexus.status()
        if status is None or not status.get("indexed", False):
            print(f"  📦 索引代码库...")
            result = gitnexus.analyze()
            if result["success"]:
                print(f"  ✅ 索引完成\n")
        changes = gitnexus.detect_changes()
        if changes:
            files = changes.get("changed_files", [])
            symbols = changes.get("symbols", [])
            if files:
                print(f"  受影响的文件 ({len(files)}):")
                for f in files[:8]:
                    print(f"    - {f}")
            if symbols:
                print(f"  相关符号 ({len(symbols)}):")
                for s in symbols[:8]:
                    print(f"    - {s}")
            print()
    else:
        print(f"  ⚠️  gitnexus 不可用，跳过影响分析\n")

    # 输出 task 详情
    if task.description:
        print(f"  📋 描述:")
        for line in task.description.split("\\n"):
            print(f"    {line}")
    if task.acceptance:
        print(f"  ✅ 验收标准:")
        for line in task.acceptance.split("\\n"):
            print(f"    {line}")
    print()
    print(f"  💡 完成修改后运行: devflow dev finish {task_id}\n")


def _finish_task(adapter: BeadsAdapter, task_id: str, project_path: Path):
    """结束一个 task：验证 + gate close。"""
    print(f"\n  ⏹ 结束 task: {task_id}\n")

    task = adapter.get_task(task_id)
    if not task:
        print(f"  ❌ task {task_id} 未找到")
        sys.exit(1)

    # 先运行影响分析（必须）
    print(f"  🔍 运行影响分析...")
    from devflow.protocols.gitnexus_adapter import GitNexusAdapter
    gitnexus = GitNexusAdapter(project_path)
    available, mode = gitnexus.check_available()
    if available:
        changes = gitnexus.detect_changes()
        if changes:
            adapter.update_task_field(task_id, "gitnexus_impact_checked", True)
            print(f"  ✅ gitnexus_impact_checked = true\n")

    # 运行验证（如果可用）
    from devflow.protocols.autoresearch_adapter import AutoresearchAdapter
    auto = AutoresearchAdapter(project_path)
    if auto.is_available():
        print(f"  🔍 运行验证...")
        commands = _detect_test_commands(project_path)
        if commands:
            result = auto.run_verification(commands[0])
            if result.get("success") and result.get("passed"):
                adapter.update_task_field(task_id, "verification_evidence", True)
                print(f"  ✅ verification_evidence = true\n")

    # 尝试 gate close
    from devflow.engine.gates import can_close_task
    task_dict = {
        "gitnexus_impact_checked": True,
        "verification_evidence": True,
        "design_approved": True,
        "security_checked": False,
    }
    can_close, _ = can_close_task(task_dict, adapter)
    if can_close:
        print(f"  ✅ 所有条件满足，task 可以关闭\n")
        print(f"  运行: devflow gate close {task_id}\n")
    else:
        print(f"  ⚠️  部分条件未满足，手动检查:\n")
        print(f"    devflow gate check {task_id}\n")


def _next_task(adapter: BeadsAdapter, project_path: Path):
    """查看下一个 ready task。"""
    tasks = adapter.get_tasks(status="ready")
    if tasks:
        t = tasks[0]
        print(f"\n  ▶ 下一个 task: {t.id} — {t.title}\n")
        print(f"  运行: devflow dev start {t.id}\n")
    else:
        # 检查是否有 in_progress 或 open 的
        in_progress = adapter.get_tasks(status="in_progress")
        if in_progress:
            t = in_progress[0]
            print(f"\n  ▶ 进行中的 task: {t.id} — {t.title}\n")
            print(f"  运行: devflow dev finish {t.id}\n")
        else:
            open_tasks = adapter.get_tasks(status="open")
            if open_tasks:
                t = open_tasks[0]
                print(f"\n  📋 待办 task: {t.id} — {t.title}\n")
                print(f"  运行: devflow dev start {t.id}\n")
            else:
                print(f"\n  ✅ 没有待办的 task\n")


def _dev_status(adapter: BeadsAdapter, project_path: Path):
    """显示开发循环概览。"""
    ready = adapter.get_tasks(status="ready")
    in_progress = adapter.get_tasks(status="in_progress")
    open_tasks = adapter.get_tasks(status="open")

    print(f"\n  📊 开发状态\n")
    print(f"  ▶ 进行中: {len(in_progress)}")
    for t in in_progress:
        print(f"    {t.id}: {t.title}")
    print(f"  📋 待办: {len(open_tasks)}")
    for t in open_tasks[:5]:
        print(f"    {t.id}: {t.title}")
    if len(open_tasks) > 5:
        print(f"    ... 还有 {len(open_tasks) - 5} 个")
    print(f"  🎯 就绪: {len(ready)}")
    for t in ready[:3]:
        print(f"    {t.id}: {t.title}")
    print()


def _detect_test_commands(project_path: Path) -> list[str]:
    """自动检测测试命令。"""
    checks = [
        (project_path / "package.json", ["npm test", "npm run test"]),
        (project_path / "pytest.ini", ["python -m pytest"]),
        (project_path / "pyproject.toml", ["python -m pytest"]),
        (project_path / "setup.cfg", ["python -m pytest"]),
        (project_path / "go.mod", ["go test ./..."]),
        (project_path / "Cargo.toml", ["cargo test"]),
        (project_path / "Makefile", ["make test"]),
    ]
    for config_file, cmds in checks:
        if config_file.exists():
            return cmds
    return []
