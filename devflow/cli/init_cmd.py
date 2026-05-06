"""devflow init 命令 — 初始化 devflow 项目，自动安装缺少的工具。"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from devflow.protocols.beads_adapter import BeadsAdapter


def run_init(args: argparse.Namespace):
    """初始化 devflow 项目。

    自动检测并安装缺少的工具：
    1. beads — 通过 go install
    2. gitnexus — 通过 npx（Docker 降级）
    3. autoresearch — 通过 npx skills add
    4. hooks 注册
    """
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)
    force = getattr(args, "force", False)

    print(f"\n  {'=' * 48}")
    print(f"   devflow init — 环境初始化")
    print(f"  {'=' * 48}\n")

    # ======== Step 1: beads ========
    print(f"  [1/4] beads...")
    beads_ok = _ensure_beads(project_path, force)
    print(f"    {'✅' if beads_ok else '❌'} beads")

    # ======== Step 2: gitnexus ========
    print(f"  [2/4] gitnexus...")
    git_ok = _ensure_gitnexus(project_path, force)
    print(f"    {'✅' if git_ok else '⚠️'} gitnexus")

    # ======== Step 3: autoresearch ========
    print(f"  [3/4] autoresearch...")
    auto_ok = _ensure_autoresearch(project_path, force)
    print(f"    {'✅' if auto_ok else '⚠️'} autoresearch")

    # ======== Step 4: .devflow 目录 + 状态记录 ========
    print(f"  [4/4] 项目配置...")
    devflow_dir = project_path / ".devflow"
    devflow_dir.mkdir(exist_ok=True)

    # 更新 beads 适配器（因为可能刚装上）
    bead_adapter = BeadsAdapter(project_path)
    bead_adapter.create_state_record("phase-0", "init: devflow initialized")
    print(f"    ✅ .devflow/ 已创建")

    print(f"\n  {'=' * 48}")
    print(f"   ✅ devflow 环境就绪！")
    print(f"  {'=' * 48}\n")
    print(f"  运行 devflow state 查看当前状态\n")

    # 概要
    status = []
    status.append(f"beads:  {'可用' if beads_ok else '失败'}")
    status.append(f"gitnexus: {'可用' if git_ok else '不可用'}")
    status.append(f"autoresearch: {'可用' if auto_ok else '不可用'}")
    print(f"  状态: {' | '.join(status)}\n")


def _ensure_beads(project_path: Path, force: bool) -> bool:
    """确保 beads 已安装并初始化。"""
    # 检查是否已安装
    try:
        result = subprocess.run(
            ["bd", "--help"],
            capture_output=True, text=True, timeout=10,
            encoding="utf-8", errors="replace",
        )
        if result.returncode == 0:
            # 尝试初始化
            init_result = subprocess.run(
                ["bd", "init", "--quiet"],
                capture_output=True, text=True, timeout=15,
                cwd=project_path,
                encoding="utf-8", errors="replace",
            )
            if init_result.returncode == 0 or "already initialized" in init_result.stderr.lower():
                return True
            print(f"    ⚠️  beads init: {init_result.stderr.strip()[:100]}")
            return True
    except FileNotFoundError:
        pass
    except Exception as e:
        print(f"    ⚠️  beads 检查异常: {e}")

    # beads 未安装，自动安装
    print(f"    📦 beads 未安装，正在通过 go install 安装...")
    try:
        result = subprocess.run(
            ["go", "install", "github.com/steveyegge/beads/cmd/bd@latest"],
            capture_output=True, text=True, timeout=300,
            encoding="utf-8", errors="replace",
        )
        if result.returncode == 0:
            print(f"    ✅ beads 安装成功")
            # 初始化
            subprocess.run(
                ["bd", "init", "--quiet"],
                capture_output=True, text=True, timeout=15,
                cwd=project_path,
            )
            return True
        else:
            print(f"    ❌ go install 失败: {result.stderr.strip()[:200]}")
            print(f"    → 手动安装: go install github.com/steveyegge/beads/cmd/bd@latest")
            return False
    except FileNotFoundError:
        print(f"    ❌ go 未安装，无法安装 beads")
        print(f"    → 请先安装 Go: https://go.dev/dl/")
        return False
    except Exception as e:
        print(f"    ❌ 安装失败: {e}")
        return False


def _ensure_gitnexus(project_path: Path, force: bool) -> bool:
    """确保 gitnexus 可用。"""
    # 尝试原生
    try:
        result = subprocess.run(
            ["npx", "--yes", "gitnexus", "--help"],
            capture_output=True, text=True, timeout=30,
            cwd=project_path,
            shell=sys.platform == "win32",
            encoding="utf-8", errors="replace",
        )
        if result.returncode == 0:
            return True
    except Exception:
        pass

    # 尝试 Docker
    try:
        result = subprocess.run(
            ["docker", "run", "--rm",
             "ghcr.io/abhigyanpatwari/gitnexus:latest",
             "npx", "--yes", "gitnexus", "--help"],
            capture_output=True, text=True, timeout=60,
            encoding="utf-8", errors="replace",
        )
        if result.returncode == 0:
            print(f"    ✅ Docker gitnexus 可用")
            return True
    except Exception:
        pass

    print(f"    ⚠️  gitnexus 不可用（原生和 Docker 都不行）")
    return False


def _ensure_autoresearch(project_path: Path, force: bool) -> bool:
    """确保 autoresearch 已安装。"""
    # 检查是否已安装
    try:
        result = subprocess.run(
            ["npx", "--yes", "skills", "run", "autoresearch", "--help"],
            capture_output=True, text=True, timeout=30,
            cwd=project_path,
            encoding="utf-8", errors="replace",
        )
        if result.returncode == 0:
            return True
    except Exception:
        pass

    # 安装
    print(f"    📦 autoresearch 未安装，正在安装...")
    try:
        # 在 Windows 上需要 npx.cmd，且 --yes 必须紧跟在 install 模式之后
        npx_cmd = "npx.cmd" if sys.platform == "win32" else "npx"
        result = subprocess.run(
            [npx_cmd, "skills", "add", "uditgoenka/autoresearch", "-y"],
            capture_output=True, text=True, timeout=120,
            cwd=project_path,
            shell=sys.platform == "win32",
            encoding="utf-8", errors="replace",
        )
        if result.returncode == 0:
            # 检查是否已安装
            for d in [
                Path.home() / ".claude" / "skills",
                Path.home() / ".agents" / "skills",
                project_path / ".agents" / "skills",
                project_path / ".claude" / "skills",
            ]:
                if (d / "autoresearch").exists():
                    print(f"    ✅ 安装成功（{d}）")
                    return True
            print(f"    ✅ npx 返回成功（自动检测目录未找到但可能可用）")
            return True
        else:
            print(f"    ⚠️  autoresearch 安装输出: {result.stderr.strip()[:200]}")
            return False
    except Exception as e:
        print(f"    ⚠️  autoresearch 安装异常: {e}")
        return False
