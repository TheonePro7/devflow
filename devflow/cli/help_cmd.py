"""devflow help 命令 — 场景化工作流引导。"""

from __future__ import annotations

import argparse


HELP_TEXT = """
╔══════════════════════════════════════════════════════════════╗
║                    devflow — 工作流地图                      ║
║         从模糊创意到可交付产品的 AI 工作流编排器             ║
╚══════════════════════════════════════════════════════════════╝

┌─ 5 阶段流程 ───────────────────────────────────────────────┐
│                                                              │
│  Phase 1  Ideate（需求梳理）                                 │
│    devflow ideate         4 阶段结构化提问引导               │
│    devflow transition     状态转移（phase-1/start）          │
│                                                              │
│  Phase 2  Design（设计）                                     │
│    transition phase-2/start  进入设计阶段                    │
│                                                              │
│  Phase 3  Setup（初始化）                                    │
│    devflow init              初始化项目环境                  │
│    devflow doctor            一键诊断环境                    │
│                                                              │
│  Phase 4  Develop（开发循环）                                │
│    devflow dev start <id>    开始开发一个 task               │
│    devflow dev finish <id>   完成 task（验证+关闭）          │
│    devflow dev next          查看下一个 task                 │
│    devflow dev status        开发面板概览                    │
│    devflow task list         查看所有 task                   │
│    devflow gate check <id>   检查关闭条件                   │
│                                                              │
│  Phase 5  Finish（收尾）                                     │
│    devflow state             查看当前阶段和状态              │
│    devflow log               查看时间线                      │
│    devflow sync              同步工具状态                    │
│                                                              │
├─ 跨阶段命令 ────────────────────────────────────────────────┤
│                                                              │
│    devflow transition        查看可用转移                    │
│    devflow gate close <id>   关闭 task（条件满足时）         │
│    devflow task create       创建 task                       │
│    devflow --version         版本号                          │
│                                                              │
└──────────────────────────────────────────────────────────────┘

快速开始:
  devflow doctor            检查环境
  devflow ideate            开始需求梳理
  devflow dev next          查看下一个要做的
"""


def run_help(args: argparse.Namespace):
    """显示场景化 help。"""
    print(HELP_TEXT)
