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
                capture_output=True, text=True, timeout=5,
                encoding="utf-8", errors="replace",
            )
            if result.returncode == 0:
                candidates = result.stdout.strip().split("\n")
                # Windows: 优先选 .cmd (npm, 无 CGO 问题), 其次 .exe (Go), 避免无扩展名的 npm shim
                if sys.platform == "win32":
                    for ext in (".cmd", ".exe"):
                        for c in candidates:
                            if c.strip().lower().endswith(ext):
                                return c.strip()
                cmd = candidates[0].strip()
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
                encoding="utf-8", errors="replace",
            )
            return result.returncode == 0
        except Exception:
            return False

    def is_available(self) -> bool:
        return self._available

    # ========== 本地降级存储（当 beads 不可用时） ==========

    def _read_local_state(self) -> dict:
        """从本地文件读取状态。

        优先读 .devflow/state.json（CLI 标准），
        不存在时读 .devflow/state（hooks 标准）。
        """
        candidates = [
            self._state_file,  # .devflow/state.json
            self.project_path / ".devflow" / "state",  # .devflow/state (hooks)
        ]
        for path in candidates:
            if path.exists():
                try:
                    with open(path, "r", encoding="utf-8-sig") as f:
                        data = json.load(f)
                    # 标准化 phase 字段：数字→字符串，如 5 → "phase-5"
                    phase = data.get("phase", "phase-0")
                    if isinstance(phase, int):
                        phase = f"phase-{phase}"
                    elif isinstance(phase, str) and not phase.startswith("phase-"):
                        phase = f"phase-{phase}"
                    return {"phase": phase, "updated_at": data.get("updatedAt", data.get("updated_at", ""))}
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
            f.write("\n")

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
                encoding="utf-8", errors="replace",
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
                        title = results[0].get("title", "")
                        # title 格式: "state:phase-3" → 提取 phase-3
                        if title.startswith("state:"):
                            return title[len("state:"):]
                except (json.JSONDecodeError, KeyError):
                    pass
        local = self._read_local_state()
        return local.get("phase", "phase-0")

    def check_condition(self, condition_id: str) -> bool:
        """检查一个条件是否满足。

        实现所有 Phase 间转移条件的真实检测逻辑。
        """
        if condition_id == "EPIC_EXISTS":
            return self._check_epic_exists()
        elif condition_id == "EPIC_HAS_ACCEPTANCE":
            return self._check_epic_has_field("acceptance")
        elif condition_id == "EPIC_HAS_DESCRIPTION":
            return self._check_epic_has_field("description")
        elif condition_id == "DECISION_EXISTS":
            return self._check_decision_exists()
        elif condition_id == "TASKS_CREATED":
            return self._check_tasks_ready()
        elif condition_id == "SETUP_SCRIPTS_RUN":
            return (self.project_path / ".devflow").exists()
        elif condition_id == "ALL_TASKS_CLOSED":
            return self._check_all_tasks_closed()
        elif condition_id == "GIT_PUSHED":
            return self._check_git_pushed()
        return False

    def _check_epic_exists(self) -> bool:
        """至少有一个 open 状态的 epic。"""
        if self._available:
            code, out, err = self._run_bd(["list", "--type=epic", "--status=open", "--json"])
            if code == 0 and out.strip():
                try:
                    data = json.loads(out)
                    return isinstance(data, list) and len(data) > 0
                except (json.JSONDecodeError, TypeError):
                    pass
        return False

    def _check_epic_has_field(self, field: str) -> bool:
        """检查 epic 是否有指定非空字段。

        beads 使用 acceptance_criteria 作为字段名，devflow 使用 acceptance。
        同时检查两种命名。
        """
        alt_names = {field}
        if field == "acceptance":
            alt_names.add("acceptance_criteria")
        if not self._available:
            return False
        code, out, err = self._run_bd(["list", "--type=epic", "--status=open", "--json"])
        if code != 0 or not out.strip():
            return False
        try:
            data = json.loads(out)
            if isinstance(data, list):
                for epic in data:
                    for name in alt_names:
                        val = epic.get(name, "")
                        if val and val.strip():
                            return True
        except (json.JSONDecodeError, TypeError):
            pass
        return False

    def _check_decision_exists(self) -> bool:
        """检查是否有设计决策记录。降级到本地文件。"""
        decisions_file = self.project_path / ".devflow" / "decisions.json"
        return decisions_file.exists()

    def _check_tasks_ready(self) -> bool:
        """至少有一个 open/in_progress 状态的 task。"""
        if self._available:
            code, out, err = self._run_bd(["list", "--type=task", "--status=open", "--json"])
            if code == 0 and out.strip():
                try:
                    data = json.loads(out)
                    if isinstance(data, list) and len(data) > 0:
                        return True
                except (json.JSONDecodeError, TypeError):
                    pass
        return False

    def _check_all_tasks_closed(self) -> bool:
        """所有 task 都已关闭（没有 open 或 in_progress 状态的 task）。"""
        if not self._available:
            return False
        for status in ("open", "in_progress"):
            code, out, err = self._run_bd(["list", "--type=task", f"--status={status}", "--json"])
            if code == 0 and out.strip():
                try:
                    data = json.loads(out)
                    if isinstance(data, list) and len(data) > 0:
                        return False
                except (json.JSONDecodeError, TypeError):
                    pass
        return True

    def _check_git_pushed(self) -> bool:
        """检查 git 是否已推送（比较本地和远程，无 upstream 时视为已推送）。"""
        import subprocess as _sp
        try:
            # 先检查有没有 upstream
            result = _sp.run(
                ["git", "rev-parse", "--abbrev-ref", "@{u}"],
                capture_output=True, text=True, timeout=5,
                cwd=self.project_path,
                encoding="utf-8", errors="replace",
            )
            if result.returncode != 0:
                # 没有 upstream（新分支），视为已推送
                return True
            # 检查未推送的 commit
            result = _sp.run(
                ["git", "log", "--oneline", "@{u}..HEAD"],
                capture_output=True, text=True, timeout=5,
                cwd=self.project_path,
                encoding="utf-8", errors="replace",
            )
            return result.returncode == 0 and not result.stdout.strip()
        except Exception:
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
