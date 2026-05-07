"""devflow CLI 入口 — 所有命令的路由。"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from devflow.cli.state_cmd import run_state
from devflow.cli.transition_cmd import run_transition
from devflow.cli.gate_cmd import run_gate
from devflow.cli.task_cmd import run_task
from devflow.cli.init_cmd import run_init
from devflow.cli.sync_cmd import run_sync
from devflow.cli.ideate_cmd import run_ideate
from devflow.cli.log_cmd import run_log
from devflow.cli.dev_cmd import run_dev
from devflow.cli.doctor_cmd import run_doctor
from devflow.cli.help_cmd import run_help
from devflow.cli.prd_cmd import run_prd
from devflow.cli.bootstrap_cmd import run_bootstrap


def _setup_encoding():
    """Windows 终端编码修复。"""
    if sys.platform == "win32":
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")


def main(argv: list[str] | None = None):
    """CLI 主入口。"""
    _setup_encoding()
    parser = argparse.ArgumentParser(
        prog="devflow",
        description="自主工程引擎 — 从模糊创意到可交付产品的 AI 工作流编排器",
    )
    parser.add_argument("--version", action="version", version="devflow 1.0.0")

    subparsers = parser.add_subparsers(dest="command", help="可用命令")

    # state
    p_state = subparsers.add_parser("state", help="显示当前状态")
    p_state.add_argument("--path", help="项目路径（默认当前目录）")
    p_state.set_defaults(func=run_state)

    # init
    p_init = subparsers.add_parser("init", help="初始化 devflow 项目")
    p_init.add_argument("--path", help="项目路径（默认当前目录）")
    p_init.add_argument("--force", action="store_true", help="强制重新初始化")
    p_init.add_argument("--skip-beads", action="store_true", help="跳过 beads 初始化")
    p_init.set_defaults(func=run_init)

    # transition
    p_trans = subparsers.add_parser("transition", help="状态转移")
    p_trans.add_argument("--path", help="项目路径（默认当前目录）")
    p_trans.add_argument("target", nargs="?", help="目标状态（如 phase-1/start）")
    p_trans.add_argument("--dry-run", action="store_true", help="预览不执行")
    p_trans.set_defaults(func=run_transition)

    # gate
    p_gate = subparsers.add_parser("gate", help="门禁管理")
    p_gate.add_argument("--path", help="项目路径（默认当前目录）")
    p_gate.add_argument("action", choices=["check", "run-impact-analysis", "run-verification", "run-security", "close"],
                        help="门禁操作")
    p_gate.add_argument("task_id", help="beads task ID")
    p_gate.set_defaults(func=run_gate)

    # sync
    p_sync = subparsers.add_parser("sync", help="同步各工具状态到 beads")
    p_sync.add_argument("--path", help="项目路径（默认当前目录）")
    p_sync.set_defaults(func=run_sync)

    # ideate
    p_ideate = subparsers.add_parser("ideate", help="4 阶段需求梳理引导")
    p_ideate.add_argument("--path", help="项目路径（默认当前目录）")
    p_ideate.add_argument("--resume", action="store_true", help="从草稿继续")
    p_ideate.add_argument("--force", action="store_true", help="强制重新回答")
    p_ideate.set_defaults(func=run_ideate)

    # log
    p_log = subparsers.add_parser("log", help="显示状态转移时间线")
    p_log.add_argument("--path", help="项目路径（默认当前目录）")
    p_log.add_argument("--tail", type=int, default=0, help="只看最近 N 条")
    p_log.add_argument("--json", action="store_true", help="JSON 格式输出")
    p_log.set_defaults(func=run_log)

    # bootstrap
    p_bootstrap = subparsers.add_parser("bootstrap", help="新项目快速开始")
    p_bootstrap.add_argument("--path", help="项目路径（默认当前目录）")
    p_bootstrap.set_defaults(func=run_bootstrap)

    # prd
    p_prd = subparsers.add_parser("prd", help="从 ideate 生成 PRD markdown")
    p_prd.add_argument("--path", help="项目路径（默认当前目录）")
    p_prd.add_argument("--title", help="PRD 标题（默认从回答自动提取）")
    p_prd.add_argument("--force", action="store_true", help="覆盖已有文件")
    p_prd.set_defaults(func=run_prd)

    # guide
    p_guide = subparsers.add_parser("guide", help="工作流地图引导")
    p_guide.set_defaults(func=run_help)

    # doctor
    p_doctor = subparsers.add_parser("doctor", help="一键环境诊断")
    p_doctor.add_argument("--path", help="项目路径（默认当前目录）")
    p_doctor.add_argument("--fix", action="store_true", help="尝试自动修复")
    p_doctor.set_defaults(func=run_doctor)

    # dev
    p_dev = subparsers.add_parser("dev", help="开发循环（start/finish/next/status）")
    p_dev.add_argument("--path", help="项目路径（默认当前目录）")
    p_dev.add_argument("action", choices=["start", "finish", "next", "status"],
                       help="操作: start=<task-id> 开始开发, finish=<task-id> 完成, next 下一个, status 概览")
    p_dev.add_argument("task_id", nargs="?", help="task ID（start/finish 时需要）")
    p_dev.set_defaults(func=run_dev)

    # task
    p_task = subparsers.add_parser("task", help="任务管理")
    p_task.add_argument("--path", help="项目路径（默认当前目录）")
    p_task.add_argument("action", choices=["create", "list", "show"])
    p_task.add_argument("id_or_epic", nargs="?", help="create: epic ID | show: task ID")
    p_task.add_argument("--title", help="创建 task 时的标题")
    p_task.add_argument("--description", help="创建 task 时的描述")
    p_task.add_argument("--type", default="task", choices=["task", "bug", "feature", "chore"],
                        help="创建 task 的类型（默认 task）")
    p_task.set_defaults(func=run_task)

    args = parser.parse_args(argv)

    if not args.command:
        parser.print_help()
        sys.exit(1)

    try:
        args.func(args)
    except SystemExit:
        raise
    except KeyboardInterrupt:
        raise
    except Exception as e:
        print(f"❌ 错误: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
