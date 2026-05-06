"""devflow task 命令 — 任务管理。"""

from __future__ import annotations

import argparse
import sys
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
        _create_task(bead_adapter, args)
    else:
        print(f"❌ 未知操作: {args.action}")
        sys.exit(1)


def _list_tasks(adapter: BeadsAdapter):
    """列出所有 task。"""
    open_tasks = adapter.get_tasks(status="open")
    in_progress = adapter.get_tasks(status="in_progress")
    ready_tasks = adapter.get_tasks(status="ready")

    print(f"\n  Task 列表:\n")

    if in_progress:
        print(f"  ▶ 进行中:")
        for t in in_progress:
            print(f"    {t.id}: {t.title}")
        print()

    if ready_tasks:
        print(f"  ▶ 就绪 ({len(ready_tasks)}):")
        for t in ready_tasks:
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
        sys.exit(1)

    task = adapter.get_task(task_id)
    if not task:
        print(f"❌ task {task_id} 未找到")
        sys.exit(1)

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


def _create_task(adapter: BeadsAdapter, args: argparse.Namespace):
    """创建 task。"""
    epic_id = args.id_or_epic
    title = args.title or ""
    description = args.description or ""
    task_type = args.type or "task"

    if epic_id:
        # 绑定到 epic
        full_title = title
        if not full_title:
            print("❌ --title 不能为空")
            sys.exit(1)
        adapter._run_bd([
            "create", "--type=task",
            f"--title={full_title}",
            f"--description={description}",
            f"--parent={epic_id}",
        ], timeout=10)
        print(f"  ✅ task 已创建: {full_title}")
        print(f"     父级: {epic_id}")
    else:
        # 自由创建
        if not title:
            print("❌ 需要指定 epic ID 或 --title")
            print("  用法:")
            print("    devflow task create <epic-id> --title=\"...\"")
            print("    devflow task create --title=\"...\"")
            sys.exit(1)

        full_title = f"[{task_type}] {title}" if task_type != "task" else title
        adapter._run_bd([
            "create", f"--type={task_type}",
            f"--title={full_title}",
            f"--description={description}",
        ], timeout=10)
        print(f"  ✅ {task_type} 已创建: {full_title}")
