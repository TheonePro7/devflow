"""devflow task 命令 — 任务管理。"""

from __future__ import annotations

import argparse
from pathlib import Path

from devflow.protocols.beads_adapter import BeadsAdapter


def run_task(args: argparse.Namespace):
    """管理 beads 任务。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)

    if args.action == "list":
        _list_tasks(bead_adapter)
    elif args.action == "show":
        _show_task(bead_adapter, args.id_or_epic)
    elif args.action == "create":
        _create_task(bead_adapter, args.id_or_epic)
    else:
        print(f"❌ 未知操作: {args.action}")


def _list_tasks(adapter: BeadsAdapter):
    """列出所有 task。"""
    open_tasks = adapter.get_tasks(status="open")
    in_progress = adapter.get_tasks(status="in_progress")

    print(f"\n  Task 列表:\n")

    if in_progress:
        print(f"  ▶ 进行中:")
        for t in in_progress:
            print(f"    {t.id}: {t.title}")
        print()

    if open_tasks:
        print(f"  📋 待办 ({len(open_tasks)}):")
        for t in open_tasks:
            print(f"    {t.id}: {t.title}")
        print()
    else:
        print(f"  📋 没有待办 task\n")


def _show_task(adapter: BeadsAdapter, task_id: str):
    """显示 task 详情。"""
    if not task_id:
        print("❌ 需要指定 task ID")
        return

    task = adapter.get_task(task_id)
    if not task:
        print(f"❌ task {task_id} 未找到")
        return

    print(f"\n  Task: {task.id} — {task.title}")
    print(f"  状态: {task.status}")
    if task.parent:
        print(f"  父级: {task.parent}")
    if task.description:
        print(f"\n  描述: {task.description}")
    if task.acceptance:
        print(f"\n  验收标准: {task.acceptance}")
    if task.design:
        print(f"\n  设计: {task.design}")
    print()


def _create_task(adapter: BeadsAdapter, epic_id: str):
    """创建 task。"""
    if not epic_id:
        print("❌ 需要指定 epic ID")
        return
    print(f"  ⚠️  创建 task 功能需要通过 beads CLI 手动操作:")
    print(f"    bd create --type=task --parent={epic_id} --title=\"...\"")
    print()
