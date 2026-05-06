"""autoresearch 适配器 — 质量验证和安全检查。

暂为桩实现，阶段二开发完整适配。"""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Optional


class AutoresearchAdapter:
    """autoresearch 工具封装。"""

    def __init__(self, project_path: Optional[Path] = None):
        self.project_path = project_path or Path.cwd()

    def probe(self) -> Optional[dict]:
        """对抗人格约束发现。"""
        ok, out = self._run_skill("autoresearch:probe")
        if ok and out:
            return {"result": out.strip()}
        return None

    def security(self, diff_mode: bool = True) -> Optional[dict]:
        """运行安全检查。"""
        cmd = "autoresearch:security"
        if diff_mode:
            cmd += " --diff"
        ok, out = self._run_skill(cmd)
        if ok and out:
            return {"result": out.strip()}
        return None

    def verify(self, command: str) -> Optional[dict]:
        """运行验证命令。"""
        try:
            result = subprocess.run(
                command, shell=True, capture_output=True, text=True, timeout=300,
                cwd=self.project_path,
            )
            return {
                "returncode": result.returncode,
                "stdout": result.stdout[-2000:] if len(result.stdout) > 2000 else result.stdout,
                "stderr": result.stderr[-500:] if len(result.stderr) > 500 else result.stderr,
            }
        except Exception as e:
            return {"error": str(e)}

    def is_available(self) -> bool:
        """检查 autoresearch 是否可用。"""
        ok, _ = self._run_skill("autoresearch --help")
        return ok

    def _run_skill(self, cmd: str) -> tuple[bool, str]:
        try:
            result = subprocess.run(
                ["npx", "skills", "run", cmd],
                capture_output=True, text=True, timeout=60,
                cwd=self.project_path,
            )
            return result.returncode == 0, result.stdout
        except Exception:
            return False, ""
