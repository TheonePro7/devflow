"""devflow init 命令 — 初始化 devflow 项目。"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from devflow.protocols.beads_adapter import BeadsAdapter


def run_init(args: argparse.Namespace):
    """初始化 devflow 项目。

    1. 检查 beads 是否可用
    2. 初始化 beads（if not already）
    3. 创建 .devflow/ 目录
    4. 注册必要的 hooks
    """
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)

    print("\n  devflow init — 初始化项目中...\n")

    # Step 1: 检查 beads
    print(f"  [1/4] 检查 beads...")
    if not bead_adapter.is_available():
        print(f"    ❌ beads 未安装。请先安装 beads: https://gastownhall.github.io/beads/")
        print(f"    或跳过: devflow init --skip-beads")
        if not getattr(args, "skip_beads", False):
            sys.exit(1)
    else:
        print(f"    ✅ beads 可用")

    # Step 2: 初始化 beads
    if not getattr(args, "skip_beads", False):
        print(f"  [2/4] 初始化 beads...")
        code, out, err = bead_adapter._run_bd(["init"])
        if code == 0:
            print(f"    ✅ beads 已初始化")
        elif "already initialized" in err.lower() or "already" in err.lower():
            print(f"    ✅ beads 已经初始化")
        else:
            print(f"    ⚠️  beads init 返回非零: {err.strip()[:200]}")
    else:
        print(f"  [2/4] 跳过 beads 初始化")

    # Step 3: 创建 .devflow 目录
    print(f"  [3/4] 创建 .devflow/ 目录...")
    devflow_dir = project_path / ".devflow"
    devflow_dir.mkdir(exist_ok=True)
    print(f"    ✅ {devflow_dir}")

    # Step 4: 创建状态记录
    print(f"  [4/4] 创建初始状态记录...")
    bead_adapter.create_state_record("phase-0", "init: devflow initialized")
    print(f"    ✅ 初始状态记录已创建")

    print(f"\n  ✅ devflow 初始化完成！\n")
    print(f"  运行 devflow state 查看当前状态")
    print(f"  运行 devflow transition phase-1/start 开始需求梳理\n")
