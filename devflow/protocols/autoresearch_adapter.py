"""autoresearch 适配器 — 质量验证、安全审计、优化循环。"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path
from typing import Optional


class AutoresearchAdapter:
    """autoresearch 工具封装。通过 npx skills run 调用。"""

    def __init__(self, project_path: Optional[Path] = None):
        self.project_path = project_path or Path.cwd()

    # ========== 可用性 ==========

    def is_available(self) -> bool:
        """检查 autoresearch 是否可用。"""
        ok, _ = self._run_skill("autoresearch", "--help")
        return ok

    def check_available(self) -> tuple[bool, str]:
        """检查可用性并返回模式说明。"""
        ok, out = self._run_skill("autoresearch", "--help")
        if ok:
            return True, "skill"
        return False, out.strip()[:200] if out else "不可用"

    # ========== 门禁功能 ==========

    def probe(self, context: Optional[str] = None) -> dict:
        """对抗人格约束发现。

        用 8 个人格（安全专家、最终用户、QA 工程师等）审视需求。
        """
        args = ["autoresearch:probe"]
        ok, out, err = self._run(args, timeout=120)
        return {
            "success": ok,
            "output": out.strip(),
            "error": err.strip(),
            "type": "probe",
        }

    def security(self, diff_mode: bool = True) -> dict:
        """运行 STRIDE + OWASP 安全审计。

        Args:
            diff_mode: 只审计 diff 变更（更快）
        """
        cmd = "autoresearch:security"
        if diff_mode:
            cmd += " --diff"
        ok, out, err = self._run_skill_cmd(cmd, timeout=180)
        return {
            "success": ok,
            "output": out.strip(),
            "error": err.strip(),
            "type": "security",
        }

    def optimize(self, goal: str, n_iterations: int = 5) -> dict:
        """运行完整优化循环。

        Args:
            goal: 优化目标（如 "提高测试覆盖率到 80%"）
            n_iterations: 迭代次数
        """
        ok, out, err = self._run_skill_cmd(
            f"autoresearch --goal={goal} --iterations={n_iterations}",
            timeout=600,
        )
        return {
            "success": ok,
            "output": out.strip(),
            "error": err.strip(),
            "type": "optimize",
        }

    def fix(self) -> dict:
        """迭代修复错误直到零错误。"""
        ok, out, err = self._run_skill_cmd("autoresearch:fix", timeout=300)
        return {
            "success": ok,
            "output": out.strip(),
            "error": err.strip(),
            "type": "fix",
        }

    def debug(self, symptom: str) -> dict:
        """自主 bug 追查。"""
        ok, out, err = self._run_skill_cmd(
            f"autoresearch:debug --symptom={symptom}",
            timeout=300,
        )
        return {
            "success": ok,
            "output": out.strip(),
            "error": err.strip(),
            "type": "debug",
        }

    # ========== 验证执行 ==========

    def run_verification(self, command: str, timeout: int = 300) -> dict:
        """运行验证命令并返回结果。"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=self.project_path,
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

    # ========== 执行引擎 ==========

    def _run(self, args: list[str], timeout: int = 60) -> tuple[bool, str, str]:
        """运行 autoresearch skill。"""
        return self._run_skill_cmd(" ".join(args), timeout)

    def _run_skill_cmd(self, cmd: str, timeout: int = 60) -> tuple[bool, str, str]:
        """通过 npx skills run 调用 skill 命令。"""
        try:
            result = subprocess.run(
                ["npx", "skills", "run", cmd],
                capture_output=True, text=True, timeout=timeout,
                cwd=self.project_path,
            )
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return False, "", "timeout"
        except FileNotFoundError:
            return False, "", "npx not found"
        except Exception as e:
            return False, "", str(e)

    def _run_skill(self, cmd: str, *extra_args: str) -> tuple[bool, str]:
        """简化版调用（向后兼容）。"""
        full_cmd = f"{cmd} {' '.join(extra_args)}" if extra_args else cmd
        ok, out, err = self._run_skill_cmd(full_cmd)
        return ok, out
