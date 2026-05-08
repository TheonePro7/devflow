"""升级机制 — 连续失败自动暂停，升级到人。

存储持久化到 .devflow/escalation.json，进程重启后不丢失。
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Optional


@dataclass
class EscalationRecord:
    """单次升级记录。"""
    task_id: str
    gate_id: str
    retries: int
    timestamp: str
    resolved: bool = False

    def to_dict(self) -> dict:
        return {
            "task_id": self.task_id,
            "gate_id": self.gate_id,
            "retries": self.retries,
            "timestamp": self.timestamp,
            "resolved": self.resolved,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "EscalationRecord":
        return cls(
            task_id=data["task_id"],
            gate_id=data["gate_id"],
            retries=data.get("retries", 0),
            timestamp=data.get("timestamp", ""),
            resolved=data.get("resolved", False),
        )


MAX_RETRIES = 3


class EscalationStore:
    """升级追踪存储 — 持久化到 JSON 文件。

    用法（保持模块级单例兼容）:
        store = EscalationStore(project_path)
        store.record_failure("task-1", "gate-a")
    """

    def __init__(self, project_path: Optional[Path] = None):
        self.project_path = project_path
        self._escalations: dict[str, EscalationRecord] = {}
        self._dirty = False
        if project_path is not None:
            self._load()

    # ========== 持久化 ==========

    def _store_path(self) -> Path:
        if self.project_path is None:
            raise RuntimeError("没有设置 project_path，无法持久化")
        return self.project_path / ".devflow" / "escalation.json"

    def _load(self):
        """从本地文件加载升级记录。"""
        path = self._store_path()
        if path.exists():
            try:
                with open(path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                if isinstance(data, dict):
                    for k, v in data.items():
                        try:
                            self._escalations[k] = EscalationRecord.from_dict(v)
                        except KeyError:
                            # 跳过损坏的单条记录，不清空全部
                            continue
            except json.JSONDecodeError:
                self._escalations = {}

    def save(self):
        """持久化到本地文件。"""
        if self.project_path is None:
            return
        if not self._dirty:
            return
        path = self._store_path()
        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            with open(path, "w", encoding="utf-8") as f:
                json.dump(
                    {k: v.to_dict() for k, v in self._escalations.items()},
                    f, indent=2, ensure_ascii=False,
                )
            self._dirty = False
        except OSError:
            print(f"  ⚠️  escalation 持久化失败: {path}")

    # ========== 核心操作 ==========

    def _key(self, task_id: str, gate_id: str) -> str:
        return f"{task_id}:{gate_id}"

    def record_failure(self, task_id: str, gate_id: str) -> EscalationRecord:
        """记录一次 gate 失败。返回升级记录。"""
        k = self._key(task_id, gate_id)
        if k not in self._escalations:
            self._escalations[k] = EscalationRecord(
                task_id=task_id,
                gate_id=gate_id,
                retries=0,
                timestamp=datetime.now().isoformat(),
            )
        record = self._escalations[k]
        record.retries += 1
        record.timestamp = datetime.now().isoformat()
        self._dirty = True
        self.save()
        return record

    def should_escalate(self, task_id: str, gate_id: str) -> bool:
        """判断是否需要升级到人。"""
        k = self._key(task_id, gate_id)
        if k not in self._escalations:
            return False
        record = self._escalations[k]
        return record.retries >= MAX_RETRIES and not record.resolved

    def mark_resolved(self, task_id: str, gate_id: str):
        """标记升级已解决。"""
        k = self._key(task_id, gate_id)
        if k in self._escalations:
            self._escalations[k].resolved = True
            self._dirty = True
            self.save()

    def get_escalation_message(self, task_id: str, gate_id: str) -> Optional[str]:
        """获取升级消息。"""
        if not self.should_escalate(task_id, gate_id):
            return None
        record = self._escalations[self._key(task_id, gate_id)]
        return (
            f"⚠️ 已检测到连续 {record.retries} 次 {gate_id} 未通过\n"
            "→ 需要你介入看一下\n"
            "→ 入口: 直接告诉我你的想法"
        )


# ========== 模块级单例（向后兼容） ==========

_default_store: Optional[EscalationStore] = None


def _get_store(project_path: Optional[Path] = None) -> EscalationStore:
    """获取模块级默认 store。"""
    global _default_store
    if _default_store is None or project_path is not None:
        _default_store = EscalationStore(project_path)
    return _default_store


def record_failure(task_id: str, gate_id: str) -> EscalationRecord:
    """记录一次 gate 失败（使用默认 store）。"""
    return _get_store().record_failure(task_id, gate_id)


def should_escalate(task_id: str, gate_id: str) -> bool:
    """判断是否需要升级到人。"""
    return _get_store().should_escalate(task_id, gate_id)


def mark_resolved(task_id: str, gate_id: str):
    """标记升级已解决。"""
    _get_store().mark_resolved(task_id, gate_id)


def get_escalation_message(task_id: str, gate_id: str) -> Optional[str]:
    """获取升级消息。"""
    return _get_store().get_escalation_message(task_id, gate_id)
