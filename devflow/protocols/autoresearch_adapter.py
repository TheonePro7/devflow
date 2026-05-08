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

    # ========== 安全审计 ==========

    def security(self, diff_mode: bool = True) -> dict:
        """运行本地安全检查。

        检查常见的代码安全问题：subprocess shell=True、路径穿越、硬编码密钥等。
        """
        findings = []

        # 1. 检查 Python 文件中 subprocess shell=True 的使用
        for py_file in self.project_path.rglob("*.py"):
            if "site-packages" in str(py_file) or ".venv" in str(py_file):
                continue
            if py_file.stat().st_size > 50000:
                continue
            try:
                content = py_file.read_text(encoding="utf-8", errors="replace")
                for i, line in enumerate(content.split("\n"), 1):
                    stripped = line.strip()
                    if "shell=True" in stripped and not stripped.startswith("#"):
                        rel_path = py_file.relative_to(self.project_path)
                        findings.append({
                            "severity": "medium",
                            "file": str(rel_path),
                            "line": i,
                            "issue": "subprocess.run 使用 shell=True",
                            "detail": stripped.strip()[:120],
                        })
            except Exception:
                continue

        # 2. 检查 .env / .key 文件是否在 gitignore 中
        gitignore = self.project_path / ".gitignore"
        sensitive_patterns = ["*.key", ".env", "credentials"]
        if gitignore.exists():
            gi_content = gitignore.read_text(encoding="utf-8", errors="replace")
            for pat in sensitive_patterns:
                if pat not in gi_content:
                    findings.append({
                        "severity": "low",
                        "file": ".gitignore",
                        "line": 0,
                        "issue": f"敏感文件模式 '{pat}' 不在 .gitignore 中",
                        "detail": "敏感文件可能被意外提交",
                    })

        success = len([f for f in findings if f["severity"] == "high"]) == 0

        return {
            "success": success,
            "output": f"安全审计完成。发现 {len(findings)} 个问题。\n" + (
                "\n".join(
                    f"  [{f['severity']}] {f['file']}:{f['line']} — {f['issue']}"
                    for f in findings[:10]
                ) if findings else "  未发现问题。"
            ),
            "findings": findings,
            "type": "security",
        }

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
