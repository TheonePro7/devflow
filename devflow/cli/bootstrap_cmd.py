"""devflow bootstrap 命令 — 新项目快速开始。"""

from __future__ import annotations

import argparse
from pathlib import Path

from devflow.cli.init_cmd import run_init
from devflow.cli.transition_cmd import run_transition
from devflow.cli.doctor_cmd import run_doctor
from devflow.protocols.beads_adapter import BeadsAdapter


def run_bootstrap(args: argparse.Namespace):
    """新项目快速开始 — init → doctor → transition phase-1/start。"""
    project_path = Path(args.path) if args.path else Path.cwd()

    print(f"\n{'=' * 56}")
    print(f"  devflow bootstrap — 新项目快速开始")
    print(f"{'=' * 56}\n")

    # Step 1: init
    print(f"  [1/4] 初始化项目环境...")
    init_args = argparse.Namespace(
        path=str(project_path),
        force=False,
        skip_beads=False,
        func=lambda x: None,
    )
    run_init(init_args)

    # Step 2: doctor
    print(f"  [2/4] 环境诊断...")
    doctor_args = argparse.Namespace(
        path=str(project_path),
        fix=False,
        func=lambda x: None,
    )
    run_doctor(doctor_args)

    # Step 3: 创建 CONTEXT.md
    print(f"  [3/4] 生成 CONTEXT.md...")
    _ensure_context_md(project_path)

    # Step 4: transition to phase-1（自动触发 ideate）
    print(f"  [4/4] 进入需求梳理阶段...\n")
    trans_args = argparse.Namespace(
        path=str(project_path),
        target="phase-1/start",
        dry_run=False,
        func=lambda x: None,
    )
    run_transition(trans_args)

    # 如果 transition 成功了（没退出），显示摘要
    print(f"\n  {'=' * 56}")
    print(f"  ✅ 项目初始化完成！")
    print(f"  {'=' * 56}\n")
    print(f"  下一步: 按提示完成 Phase 1 需求梳理\n")
    print(f"  其他命令:")
    print(f"    devflow guide       查看完整工作流")
    print(f"    devflow state       查看当前阶段")
    print(f"    devflow prd         生成 PRD markdown\n")


def _ensure_context_md(project_path: Path):
    """确保 CONTEXT.md 存在。"""
    context_file = project_path / "CONTEXT.md"
    if context_file.exists():
        print(f"    ✅ CONTEXT.md 已存在\n")
        return

    content = f"""# {project_path.name} — Project Context

> 由 devflow bootstrap 自动生成

## 项目概述

（在此描述项目目标）

## 技术栈

- （在此列出技术栈）

## 开发环境

- （在此描述开发环境要求）

## 相关文档

- [PRD](docs/prd/)
- [设计文档](docs/superpowers/specs/)
"""
    context_file.write_text(content, encoding="utf-8")
    print(f"    ✅ CONTEXT.md 已创建\n")
