"""devflow doctor 命令 — 一键环境诊断。"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path


def run_doctor(args: argparse.Namespace):
    """运行全套环境诊断。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    fix = args.fix

    print(f"\n{'=' * 56}")
    print(f"  devflow doctor — 环境诊断")
    print(f"{'=' * 56}\n")

    checks = [
        ("Python 版本", _check_python_version()),
        (".devflow/ 目录", _check_devflow_dir(project_path)),
        ("beads CLI", _check_beads()),
        ("gitnexus", _check_gitnexus(project_path)),
        ("autoresearch", _check_autoresearch()),
        ("superpowers", _check_superpowers()),
        ("Git 远程", _check_git_remote(project_path)),
        ("Docker（可选）", _check_docker()),
    ]

    all_ok = True
    for name, (ok, msg) in checks:
        status = "✅" if ok else "❌"
        print(f"  {status} {name}")
        if msg:
            print(f"      {msg}")
        if not ok:
            all_ok = False

    print(f"\n{'=' * 56}")
    if all_ok:
        print(f"  ✅ 一切正常")
    else:
        n_fail = sum(1 for _, (ok, _) in checks if not ok)
        print(f"  ⚠️  发现 {n_fail} 个问题")
        if fix:
            print(f"  --fix 模式将在后续版本实现\n")
        else:
            print(f"  运行 devflow doctor --fix 尝试自动修复\n")

    # 概要
    print(f"  devflow v0.1.0 | {project_path}\n")


def _check_python_version() -> tuple[bool, str]:
    v = sys.version_info
    ok = v.major >= 3 and v.minor >= 10
    msg = f"{v.major}.{v.minor}.{v.micro}" if ok else f"{v.major}.{v.minor}.{v.micro}（需要 >=3.10）"
    return ok, msg


def _check_devflow_dir(path: Path) -> tuple[bool, str]:
    d = path / ".devflow"
    if d.exists():
        return True, f"{d}"
    return False, ".devflow/ 不存在（运行 devflow init）"


def _check_beads() -> tuple[bool, str]:
    try:
        r = subprocess.run(
            ["where", "bd"] if sys.platform == "win32" else ["which", "bd"],
            capture_output=True, text=True, timeout=5,
            encoding="utf-8", errors="replace",
        )
        if r.returncode == 0:
            candidates = r.stdout.strip().split("\n")
            for ext in (".cmd", ".exe"):
                for c in candidates:
                    if c.strip().lower().endswith(ext):
                        return True, f"{c.strip()}"
            return True, f"{candidates[0].strip()}"
        return False, "未安装（beads 不是必需，会降级到本地文件）"
    except Exception:
        pass
    return False, "未找到（降级模式可用）"


def _check_gitnexus(path: Path) -> tuple[bool, str]:
    try:
        r = subprocess.run(
            ["npx", "--yes", "gitnexus", "--help"],
            capture_output=True, text=True, timeout=30,
            cwd=path, shell=sys.platform == "win32",
            encoding="utf-8", errors="replace",
        )
        if r.returncode == 0:
            return True, "原生模式可用"
    except Exception:
        pass
    # 尝试 Docker
    try:
        r = subprocess.run(
            ["docker", "run", "--rm",
             "ghcr.io/abhigyanpatwari/gitnexus:latest",
             "npx", "--yes", "gitnexus", "--help"],
            capture_output=True, text=True, timeout=30,
            encoding="utf-8", errors="replace",
        )
        if r.returncode == 0:
            return True, "Docker 模式可用"
    except Exception:
        pass
    return False, "不可用（影响分析会跳过）"


def _check_autoresearch() -> tuple[bool, str]:
    # 检查多个安装路径
    home = Path.home()
    check_paths = [
        home / ".claude" / "skills" / "autoresearch" / "SKILL.md",
        home / ".agents" / "skills" / "autoresearch" / "SKILL.md",
        Path.cwd() / ".agents" / "skills" / "autoresearch" / "SKILL.md",
        Path.cwd() / ".claude" / "skills" / "autoresearch" / "SKILL.md",
    ]
    for p in check_paths:
        if p.exists():
            return True, f"已安装 ({p.parent.name}/skills/autoresearch)"
    # 后备尝试 npx
    try:
        r = subprocess.run(
            ["npx", "--yes", "skills", "run", "autoresearch", "--help"],
            capture_output=True, text=True, timeout=15,
            encoding="utf-8", errors="replace",
        )
        if r.returncode == 0:
            return True, "已安装"
    except Exception:
        pass
    return False, "未安装（安全审计会跳过）"


def _check_superpowers() -> tuple[bool, str]:
    skills_dir = Path.home() / ".claude" / "skills"
    if not skills_dir.exists():
        return False, ".claude/skills/ 不存在"
    count = sum(1 for d in skills_dir.iterdir() if d.is_dir() and d.name.startswith("superpowers-"))
    if count > 0:
        return True, f"已安装 {count} 个 skill"
    return False, "未检测到 superpowers skill"


def _check_git_remote(path: Path) -> tuple[bool, str]:
    try:
        r = subprocess.run(
            ["git", "remote", "-v"],
            capture_output=True, text=True, timeout=5,
            encoding="utf-8", errors="replace", cwd=path,
        )
        if r.returncode == 0 and r.stdout.strip():
            lines = r.stdout.strip().split("\n")
            return True, lines[0].split()[1] if lines else "配置了远程"
        return False, "没有 Git 远程"
    except Exception:
        return False, "不是 Git 仓库"


def _check_docker() -> tuple[bool, str]:
    try:
        r = subprocess.run(
            ["docker", "--version"],
            capture_output=True, text=True, timeout=5,
            encoding="utf-8", errors="replace",
        )
        if r.returncode == 0:
            return True, r.stdout.strip()
    except Exception:
        pass
    return True, "未安装（非必需）"
