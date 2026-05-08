"""autoresearch 适配器 — 质量验证、安全审计。

autoresearch 本身是一个 SKILL.md 定义（prompt 集合），不是可执行的 CLI 程序。
因此这个适配器不依赖 npx skills run，而是直接内置核心功能：
  - security: 本地安全审计扫描
  - run_verification: 运行测试/验证命令
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Optional


class AutoresearchAdapter:
    """autoresearch 工具封装。"""

    def __init__(self, project_path: Optional[Path] = None):
        self.project_path = project_path or Path.cwd()

    # ========== 可用性 ==========

    def is_available(self) -> bool:
        """检查 autoresearch 是否可用。"""
        ok, _ = self._check_files()
        return ok

    def check_available(self) -> tuple[bool, str]:
        """检查可用性并返回模式说明。"""
        ok, mode = self._check_files()
        if ok:
            return True, mode
        return False, "未安装"

    @staticmethod
    def _check_files() -> tuple[bool, str]:
        """检查 autoresearch 安装文件路径。"""
        home = Path.home()
        cwd = Path.cwd()
        check_paths = [
            (home / ".claude" / "skills" / "autoresearch" / "SKILL.md", ".claude/skills"),
            (home / ".agents" / "skills" / "autoresearch" / "SKILL.md", ".agents/skills"),
            (cwd / ".agents" / "skills" / "autoresearch" / "SKILL.md", "project/.agents/skills"),
            (cwd / ".claude" / "skills" / "autoresearch" / "SKILL.md", "project/.claude/skills"),
        ]
        for p, label in check_paths:
            if p.exists():
                return True, label
        return False, ""

    # ========== 验证执行 ==========

    def run_verification(self, command: str, timeout: int = 300) -> dict:
        """运行验证命令并返回结果。

        注意: command 参数来自 detect_test_commands() 等可信来源，
             不应用作接收任意用户输入的接口（避免 shell=True 注入风险）。
        """
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=self.project_path,
                encoding="utf-8", errors="replace",
            )
            stdout = result.stdout
            stderr = result.stderr
            # 截断过长的输出
            if len(stdout) > 3000:
                stdout = stdout[:3000] + "\n... (输出截断)"
            if len(stderr) > 1000:
                stderr = stderr[:1000] + "\n... (输出截断)"

            passed = result.returncode == 0
            return {
                "success": True,
                "passed": passed,
                "returncode": result.returncode,
                "stdout": stdout,
                "stderr": stderr,
                "type": "verification",
            }
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "passed": False,
                "error": f"验证超时 ({timeout}s)",
                "type": "verification",
            }
        except Exception as e:
            return {
                "success": False,
                "passed": False,
                "error": str(e),
                "type": "verification",
            }
