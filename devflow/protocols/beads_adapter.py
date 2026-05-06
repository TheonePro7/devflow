"""beads 适配器 — 通过 CLI 子进程与 beads 交互。"""

from __future__ import annotations

import json
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


@dataclass
class BeadsIssue:
    """beads issue 的轻量表示。"""
    id: str
    title: str
    type: str = ""
    status: str = ""
    description: str = ""
    acceptance: str = ""
    design: str = ""
    notes: str = ""
    parent: str = ""
    fields: dict = field(default_factory=dict)

    def get(self, key: str, default=None):
        """获取字段值，支持从 fields 字典查找。"""
        if hasattr(self, key):
            return getattr(self, key, default)
        return self.fields.get(key, default)


class BeadsAdapter:
    """beads 工具封装。通过子进程调用 bd CLI。"""

    def __init__(self, project_path: Optional[Path] = None):
        self.project_path = project_path or Path.cwd()
        self._bd_cmd = self._find_bd()

    def _find_bd(self) -> str:
        """查找 bd 命令路径。"""
        try:
            result = subprocess.run(
                ["where", "bd"] if sys.platform == "win32" else ["which", "bd"],
                capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0:
                cmd = result.stdout.strip().split("\n")[0].strip()
                if cmd:
                    return cmd
        except Exception:
            pass
        # 尝试常见位置
        for p in [
            Path.home() / ".local" / "bin" / "bd",
            Path.home() / "AppData" / "Local" / "bd" / "bd.exe",
        ]:
            if p.exists():
                return str(p)
        return "bd"

    def _run_bd(self, args: list[str], timeout: int = 15) -> tuple[int, str, str]:
        """运行 bd 命令。"""
        try:
            result = subprocess.run(
                [self._bd_cmd] + args,
                capture_output=True, text=True, timeout=timeout,
                cwd=self.project_path,
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "timeout"
        except FileNotFoundError:
            return -1, "", f"bd 命令未找到: {self._bd_cmd}"
        except Exception as e:
            return -1, "", str(e)

    # ========== Phase / State ==========

    def get_current_phase(self) -> Optional[str]:
        """从 beads 获取当前 phase。"""
        code, out, err = self._run_bd(["search", "--json", "state:phase"])
        if code != 0 or not out.strip():
            return None
        try:
            results = json.loads(out)
            if isinstance(results, list) and len(results) > 0:
                return results[0].get("phase")
        except (json.JSONDecodeError, KeyError):
            pass
        return None

    def check_condition(self, condition_id: str) -> bool:
        """检查一个条件是否满足。

        由 state_machine 调用。条件检查逻辑随需求增长。
        目前默认返回 False（条件未满足），等待真实 beads 数据。
        """
        _ = condition_id
        return False

    # ========== Tasks ==========

    def get_tasks(self, status: str = "open") -> list[BeadsIssue]:
        """获取指定状态的 task 列表。"""
        code, out, err = self._run_bd(["list", "--type=task", f"--status={status}", "--json"])
        if code != 0 or not out.strip():
            return []
        try:
            data = json.loads(out)
            if isinstance(data, list):
                return [BeadsIssue(**item) if isinstance(item, dict) else item for item in data]
        except (json.JSONDecodeError, TypeError):
            pass
        return []

    def get_task(self, task_id: str) -> Optional[BeadsIssue]:
        """获取单个 task 详情。"""
        code, out, err = self._run_bd(["show", "--json", task_id])
        if code != 0 or not out.strip():
            return None
        try:
            data = json.loads(out)
            if isinstance(data, dict):
                return BeadsIssue(**data)
        except (json.JSONDecodeError, TypeError):
            pass
        return None

    def update_task_field(self, task_id: str, field: str, value: bool):
        """更新 task 的字段值（用于门禁检查)。"""
        val_str = "true" if value else "false"
        self._run_bd(["update", task_id, f"--{field}={val_str}"], timeout=10)

    def create_state_record(self, phase: str, transitions: str):
        """创建状态转移记录。"""
        title = f"state:{phase}"
        self._run_bd([
            "create", "--type=chore",
            f"--title={title}",
            f"--notes={transitions}",
        ], timeout=10)

    # ========== Epics ==========

    def get_epics(self) -> list[BeadsIssue]:
        """获取所有 epic。"""
        code, out, err = self._run_bd(["list", "--type=epic", "--json"])
        if code != 0 or not out.strip():
            return []
        try:
            data = json.loads(out)
            if isinstance(data, list):
                return [BeadsIssue(**item) if isinstance(item, dict) else item for item in data]
        except (json.JSONDecodeError, TypeError):
            pass
        return []

    # ========== Search ==========

    def search(self, query: str) -> list[BeadsIssue]:
        """搜索 beads issue。"""
        code, out, err = self._run_bd(["search", "--json", query])
        if code != 0 or not out.strip():
            return []
        try:
            data = json.loads(out)
            if isinstance(data, list):
                return [BeadsIssue(**item) if isinstance(item, dict) else item for item in data]
        except (json.JSONDecodeError, TypeError):
            pass
        return []

    # ========== Health ==========

    def is_available(self) -> bool:
        """检查 beads 是否可用。"""
        code, _, _ = self._run_bd(["list", "--limit=1"])
        return code == 0
