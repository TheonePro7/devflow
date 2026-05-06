"""gitnexus 适配器 — 代码知识图谱查询和影响分析。

暂为桩实现，阶段二开发完整适配。"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from typing import Optional


class GitNexusAdapter:
    """gitnexus 工具封装。"""

    def __init__(self, project_path: Optional[Path] = None):
        self.project_path = project_path or Path.cwd()

    def analyze(self) -> bool:
        """索引当前仓库。"""
        return self._run(["analyze", "."])

    def context(self, symbol: str, file_path: Optional[str] = None) -> Optional[dict]:
        """获取符号 360 度视图。"""
        args = ["context", symbol]
        if file_path:
            args.extend(["-f", file_path])
        ok, out = self._run_with_output(args)
        if ok and out:
            return {"symbol": symbol, "result": out.strip()}
        return None

    def impact(self, target: str, depth: int = 2) -> Optional[dict]:
        """获取影响范围分析。"""
        ok, out = self._run_with_output(["impact", target, "--depth", str(depth)])
        if ok and out:
            return {"target": target, "depth": depth, "result": out.strip()}
        return None

    def detect_changes(self, scope: str = "unstaged") -> Optional[dict]:
        """检测当前变更影响。"""
        ok, out = self._run_with_output(["detect-changes", "--scope", scope])
        if ok and out:
            return {"scope": scope, "result": out.strip()}
        return None

    def status(self) -> Optional[dict]:
        """检查索引状态。"""
        ok, out = self._run_with_output(["status"])
        if ok and out:
            return {"status": out.strip()}
        return None

    def is_available(self) -> bool:
        """检查 gitnexus 是否可用。"""
        ok, _ = self._run_with_output(["--help"])
        return ok

    def _run(self, args: list[str]) -> bool:
        try:
            result = subprocess.run(
                ["npx", "gitnexus"] + args,
                capture_output=True, text=True, timeout=120,
                cwd=self.project_path,
            )
            return result.returncode == 0
        except Exception:
            return False

    def _run_with_output(self, args: list[str], timeout: int = 60) -> tuple[bool, str]:
        try:
            result = subprocess.run(
                ["npx", "gitnexus"] + args,
                capture_output=True, text=True, timeout=timeout,
                cwd=self.project_path,
            )
            return result.returncode == 0, result.stdout
        except Exception as e:
            return False, str(e)
