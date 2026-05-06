"""devflow sync 命令 — 同步各工具状态到 beads。"""

from __future__ import annotations

import argparse
from pathlib import Path

from devflow.engine.state_machine import StateMachine
from devflow.protocols.beads_adapter import BeadsAdapter
from devflow.protocols.gitnexus_adapter import GitNexusAdapter
from devflow.protocols.autoresearch_adapter import AutoresearchAdapter


def run_sync(args: argparse.Namespace):
    """同步各工具状态到 beads。

    检查每个工具的可用性、索引状态、版本，并记录到 beads。
    """
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)

    print(f"\n  🔄 同步工具状态...\n")

    results = {}

    # 1. beads 自身
    print(f"  [1/4] beads...")
    beads_ok = bead_adapter.is_available()
    results["beads"] = {"available": beads_ok}
    print(f"    {'✅' if beads_ok else '❌'} {'可用' if beads_ok else '不可用（降级到本地文件）'}")

    # 2. gitnexus
    print(f"  [2/4] gitnexus...")
    gitnexus = GitNexusAdapter(project_path)
    git_ok, git_mode = gitnexus.check_available()
    results["gitnexus"] = {"available": git_ok, "mode": git_mode}
    if git_ok:
        status = gitnexus.status()
        if status:
            results["gitnexus"]["status"] = status
            print(f"    ✅ 可用 (模式: {git_mode})")
            print(f"       索引: {'已索引' if status.get('indexed') else '未索引'}, "
                  f"文件: {status.get('files', '?')}, "
                  f"符号: {status.get('symbols', '?')}")
        else:
            print(f"    ✅ 可用 (模式: {git_mode})")
            print(f"       未索引（运行 devflow gate run-impact-analysis 时自动索引）")
    else:
        print(f"    ⚠️  不可用 ({git_mode})")

    # 3. autoresearch
    print(f"  [3/4] autoresearch...")
    auto = AutoresearchAdapter(project_path)
    auto_ok, auto_mode = auto.check_available()
    results["autoresearch"] = {"available": auto_ok, "mode": auto_mode}
    print(f"    {'✅' if auto_ok else '⚠️'} {'可用' if auto_ok else '不可用'}")

    # 4. superpowers
    print(f"  [4/4] superpowers...")
    sp_available = _check_superpowers()
    results["superpowers"] = {"available": sp_available}
    print(f"    {'✅' if sp_available else '⚠️'} {'已安装' if sp_available else '未检测到'}")

    # 写入 beads
    if bead_adapter.is_available():
        summary = (
            f"beads={'ok' if results['beads']['available'] else 'local'}, "
            f"gitnexus={'ok' if results['gitnexus']['available'] else 'no'}, "
            f"autoresearch={'ok' if results['autoresearch']['available'] else 'no'}, "
            f"superpowers={'ok' if results['superpowers']['available'] else 'no'}"
        )
        bead_adapter.create_state_record("sync", f"tools: {summary}")

    print(f"\n  ✅ 同步完成\n")


def _check_superpowers() -> bool:
    """检查 superpowers 是否可用。"""
    from shutil import which
    skills_dir = Path.home() / ".claude" / "skills"
    if not skills_dir.exists():
        return False
    # 检查是否有 superpowers 开头的 skill
    for d in skills_dir.iterdir():
        if d.is_dir() and d.name.startswith("superpowers-"):
            return True
    return False
