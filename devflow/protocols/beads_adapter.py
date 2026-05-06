"""beads 适配器 — 通过 CLI 子进程与 beads 交互，不可用时降级到本地文件。"""

from __future__ import annotations

import json
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Optional


@dataclass
class BeadsIssue:
    """beads issue 的轻量表示。"""
    id: str = ""
    title: str = ""
    type: str = ""
    status: str = ""
    description: str = ""
    acceptance: str = ""
    design: str = ""
    notes: str = ""
    parent: str = ""
    fields: dict = field(default_factory=dict)

    def get(self, key: str, default=None):
        if hasattr(self, key) and key != "fields":
            return getattr(self, key, default)
        return self.fields.get(key, default)


class BeadsAdapter:
    """beads 工具封装。可降级到本地文件。"""

    def __init__(self, project_path: Optional[Path] = None):
        self.project_path = project_path or Path.cwd()
        self._state_file = self.project_path / ".devflow" / "state.json"
        self._bd_cmd = self._find_bd()
        self._available = self._check_available()

    def _find_bd(self) -> str:
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
        return "bd"

    def _check_available(self) -> bool:
        """检查 beads CLI 是否可用。"""
        try:
            result = subprocess.run(
                [self._bd_cmd, "list", "--limit=1"],
                capture_output=True, text=True, timeout=5,
                cwd=self.project_path,
            )
            return result.returncode == 0
        except Exception:
            return False

    def is_available(self) -> bool:
        return self._available

    # ========== 本地降级存储（当 beads 不可用时） ==========

    def _read_local_state(self) -> dict:
        """从本地文件读取状态。"""
        if self._state_file.exists():
            try:
                with open(self._state_file, "r", encoding="utf-8") as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError):
                pass
        return {"phase": "phase-0", "updated_at": ""}

    def _write_local_state(self, phase: str):
        """写入状态到本地文件。"""
        self._state_file.parent.mkdir(parents=True, exist_ok=True)
        data = {
            "phase": phase,
            "updated_at": datetime.now().isoformat(),
        }
        with open(self._state_file, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    def _append_local_log(self, phase: str, transitions: str):
        """追加状态记录到本地日志。"""
        log_file = self.project_path / ".devflow" / "state.log"
        entry = {
            "phase": phase,
            "transitions": transitions,
            "timestamp": datetime.now().isoformat(),
        }
        try:
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(entry, ensure_ascii=False) + "\n")
        except IOError:
            pass

    # ========== 运行 bd 命令 ==========

    def _run_bd(self, args: list[str], timeout: int = 15) -> tuple[int, str, str]:
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
            return -1, "", "bd not found"
        except Exception as e:
            return -1, "", str(e)

    # ========== Phase / State ==========

    def get_current_phase(self) -> Optional[str]:
        """获取当前 phase。优先 beads，不可用时读本地文件。"""
        if self._available:
            code, out, err = self._run_bd(["search", "--json", "state:phase"])
            if code == 0 and out.strip():
                try:
                    results = json.loads(out)
                    if isinstance(results, list) and len(results) > 0:
                        return results[0].get("phase")
                except (json.JSONDecodeError, KeyError):
                    pass
        local = self._read_local_state()
        return local.get("phase", "phase-0")

    def check_condition(self, condition_id: str) -> bool:
        """检查一个条件是否满足。

        降级策略：
        - beads 可用时查 beads
        - beads 不可用时查本地 state 文件是否有手动标记
        """
        if self._available:
            pass  # 阶段二实现真实查询
        return False

    def create_state_record(self, phase: str, transitions: str):
        """创建状态转移记录。"""
        if self._available:
            title = f"state:{phase}"
            self._run_bd([
                "create", "--type=chore",
                f"--title={title}",
                f"--notes={transitions}",
            ], timeout=10)
        self._write_local_state(phase)
        self._append_local_log(phase, transitions)

    # ========== Tasks ==========

    def get_tasks(self, status: str = "open") -> list[BeadsIssue]:
        if not self._available:
            return self._get_local_tasks(status)
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

    def _get_local_tasks(self, status: str) -> list[BeadsIssue]:
        """从本地文件获取 task 列表。"""
        tasks_file = self.project_path / ".devflow" / "tasks.json"
        if not tasks_file.exists():
            return []
        try:
            with open(tasks_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            if isinstance(data, list):
                return [BeadsIssue(**d) if isinstance(d, dict) else d for d in data
                        if isinstance(d, dict) and (status == "all" or d.get("status") == status)]
        except (json.JSONDecodeError, IOError):
            pass
        return []

    def get_task(self, task_id: str) -> Optional[BeadsIssue]:
        if not self._available:
            return None
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
        val_str = "true" if value else "false"
        self._run_bd(["update", task_id, f"--{field}={val_str}"], timeout=10)

    # ========== Epics ==========

    def get_epics(self) -> list[BeadsIssue]:
        if not self._available:
            return []
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
        if not self._available:
            return []
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
