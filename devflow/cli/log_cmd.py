"""devflow log 命令 — 时间线查看。"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def run_log(args: argparse.Namespace):
    """显示状态转移时间线。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    log_file = project_path / ".devflow" / "state.log"

    if not log_file.exists():
        print(f"  📭 暂无日志记录\n")
        return

    entries = []
    with open(log_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    pass

    if args.json:
        print(json.dumps(entries, ensure_ascii=False, indent=2))
        return

    tail = args.tail or len(entries)
    show = entries[-tail:] if tail < len(entries) else entries

    print(f"\n  📜 devflow 状态时间线{' (最近 ' + str(tail) + ' 条)' if tail < len(entries) else ''}\n")
    print(f"  {'=' * 56}\n")

    for entry in show:
        ts = entry.get("timestamp", "")[:19]  # 只保留到秒
        phase = entry.get("phase", "?")
        trans = entry.get("transitions", "")
        print(f"  [{ts}] {phase}")
        if trans:
            print(f"           {trans[:80]}")
        print()
