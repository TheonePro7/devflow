"""gitnexus 适配器 — 代码知识图谱查询和影响分析。

支持 Docker 降级（Windows tree-sitter SIGSEGV 已知问题）。
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Optional


class GitNexusAdapter:
    """gitnexus 工具封装，支持原生和 Docker 两种运行模式。"""

    def __init__(self, project_path: Optional[Path] = None):
        self.project_path = project_path or Path.cwd()
        self._native_available: Optional[bool] = None

    # ========== 可用性检查 ==========

    def check_available(self) -> tuple[bool, str]:
        """检查 gitnexus 是否可用。返回 (可用, 模式说明)。"""
        # 尝试原生
        ok, out, err = self._run_native(["--help"])
        if ok:
            self._native_available = True
            return True, "native"

        # 尝试 Docker（短超时，只检查可用性）
        ok, out, err = self._run_docker(["--help"], timeout=30)
        if ok:
            self._native_available = False
            return True, "docker"

        # 两种都不行
        detail = (out.strip() or err.strip() or "未知")[:200]
        return False, f"不可用: {detail}"

    def is_available(self) -> bool:
        ok, _ = self.check_available()
        return ok

    # ========== 核心功能 ==========

    def analyze(self, force: bool = False) -> dict:
        """索引当前仓库。

        Args:
            force: 是否强制完全重索引

        Returns:
            {"success": bool, "output": str, "error": str}
        """
        args = ["analyze", "."]
        if force:
            args.append("--force")
        ok, out, err = self._run(args, timeout=300)
        return {"success": ok, "output": out.strip(), "error": err.strip()}

    def context(self, symbol: str, file_path: Optional[str] = None) -> Optional[dict]:
        """获取符号 360 度视图。

        Returns:
            {"symbol": str, "callers": [...], "callees": [...], "processes": [...]}
            或 None（失败时）
        """
        args = ["context", symbol, "--json"]
        if file_path:
            args.extend(["-f", file_path])
        ok, out, err = self._run(args)
        if not ok or not out.strip():
            return None
        try:
            data = json.loads(out)
            return {
                "symbol": symbol,
                "callers": data.get("callers", []),
                "callees": data.get("callees", []),
                "processes": data.get("processes", []),
            }
        except (json.JSONDecodeError, KeyError):
            return {"symbol": symbol, "raw": out.strip()}

    def impact(self, target: str, depth: int = 2, include_tests: bool = False) -> Optional[dict]:
        """获取影响范围分析。

        Returns:
            {"target": str, "depth": int, "upstream": [...], "downstream": [...]}
            或 None（失败时）
        """
        args = ["impact", target, "--depth", str(depth), "--json"]
        if include_tests:
            args.append("--include-tests")
        ok, out, err = self._run(args)
        if not ok or not out.strip():
            return None
        try:
            data = json.loads(out)
            return {
                "target": target,
                "depth": depth,
                "upstream": data.get("upstream", []),
                "downstream": data.get("downstream", []),
            }
        except (json.JSONDecodeError, KeyError):
            return {"target": target, "raw": out.strip()}

    def detect_changes(self, scope: str = "unstaged") -> Optional[dict]:
        """检测当前未暂存的变更影响。

        Args:
            scope: unstaged, staged, all, compare

        Returns:
            影响分析结果或 None
        """
        args = ["detect-changes", "--scope", scope, "--json"]
        ok, out, err = self._run(args, timeout=120)
        if not ok or not out.strip():
            return None
        try:
            data = json.loads(out)
            return {
                "scope": scope,
                "symbols": data.get("symbols", []),
                "affected_processes": data.get("affected_processes", []),
                "changed_files": data.get("changed_files", []),
            }
        except (json.JSONDecodeError, KeyError):
            return {"scope": scope, "raw": out.strip()}

    def status(self) -> Optional[dict]:
        """检查索引状态。"""
        ok, out, err = self._run(["status", "--json"])
        if not ok or not out.strip():
            return None
        try:
            data = json.loads(out)
            return {
                "indexed": data.get("indexed", False),
                "files": data.get("files", 0),
                "symbols": data.get("symbols", 0),
                "age": data.get("age", ""),
            }
        except (json.JSONDecodeError, KeyError):
            return {"raw": out.strip()}

    # ========== 执行引擎 ==========

    def _run(self, args: list[str], timeout: int = 60) -> tuple[bool, str, str]:
        """自动选择原生或 Docker 运行。"""
        if self._native_available is None:
            self.check_available()

        if self._native_available is not False:
            ok, out, err = self._run_native(args, timeout)
            if ok:
                return True, out, err
            # 原生失败且可能是 SIGSEGV，切 Docker
            if "139" in err or "SIGSEGV" in err or "crash" in err.lower():
                self._native_available = False
                return self._run_docker(args, timeout)
            return False, out, err

        return self._run_docker(args, timeout)

    def _run_native(self, args: list[str], timeout: int = 60) -> tuple[bool, str, str]:
        """通过 npx gitnexus 运行。"""
        try:
            result = subprocess.run(
                ["npx", "gitnexus"] + args,
                capture_output=True, text=True, timeout=timeout,
                cwd=self.project_path,
                shell=sys.platform == "win32",
                encoding="utf-8", errors="replace",
            )
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return False, "", "timeout"
        except Exception as e:
            return False, "", str(e)

    def _run_docker(self, args: list[str], timeout: int = 120) -> tuple[bool, str, str]:
        """通过 Docker 容器运行 gitnexus。

        Docker 容器内入口为 npx gitnexus，挂载项目到 /repo。
        Windows 下需要转换路径格式。
        """
        host_path = str(self.project_path)
        # Docker 容器内工作目录设为 /repo
        docker_args = [
            "docker", "run", "--rm",
            "-v", f"{host_path}:/repo",
            "-w", "/repo",
            "ghcr.io/abhigyanpatwari/gitnexus:latest",
            "npx", "gitnexus",
        ] + args
        try:
            result = subprocess.run(
                docker_args,
                capture_output=True, text=True, timeout=timeout,
                encoding="utf-8", errors="replace",
            )
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return False, "", "docker timeout"
        except FileNotFoundError:
            return False, "", "docker not found"
        except Exception as e:
            return False, "", str(e)

    # ========== 便捷方法 ==========

    def format_impact_summary(self, impact_result: dict) -> str:
        """将影响分析结果格式化为可读文本。"""
        lines = []
        if "upstream" in impact_result:
            upstream = impact_result["upstream"]
            if upstream:
                lines.append(f"  上游（依赖此符号的代码）:")
                for item in upstream[:10]:
                    lines.append(f"    - {item}")
                if len(upstream) > 10:
                    lines.append(f"    ...还有 {len(upstream) - 10} 个")
            else:
                lines.append(f"  上游: 无依赖此符号的代码")

        if "downstream" in impact_result:
            downstream = impact_result["downstream"]
            if downstream:
                lines.append(f"  下游（此符号依赖的代码）:")
                for item in downstream[:10]:
                    lines.append(f"    - {item}")
                if len(downstream) > 10:
                    lines.append(f"    ...还有 {len(downstream) - 10} 个")
            else:
                lines.append(f"  下游: 无此符号依赖的代码")

        if "raw" in impact_result:
            lines.append(f"  {impact_result['raw']}")

        return "\n".join(lines)

    def format_context_summary(self, context_result: dict) -> str:
        """将符号上下文格式化为可读文本。"""
        lines = [f"  符号: {context_result.get('symbol', '?')}"]
        if "callers" in context_result:
            callers = context_result["callers"]
            lines.append(f"  调用者 ({len(callers)}):")
            for c in callers[:10]:
                lines.append(f"    - {c}")
        if "callees" in context_result:
            callees = context_result["callees"]
            lines.append(f"  被调用者 ({len(callees)}):")
            for c in callees[:10]:
                lines.append(f"    - {c}")
        if "raw" in context_result:
            lines.append(f"  {context_result['raw']}")
        return "\n".join(lines)
