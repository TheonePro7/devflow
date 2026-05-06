"""升级机制 — 连续失败自动暂停，升级到人。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class EscalationRecord:
    """单次升级记录。"""
    task_id: str
    gate_id: str
    retries: int
    timestamp: str
    resolved: bool = False


# 升级追踪存储（进程级，后期可迁移到 beads）
_escalations: dict[str, EscalationRecord] = {}

MAX_RETRIES = 3


def _key(task_id: str, gate_id: str) -> str:
    return f"{task_id}:{gate_id}"


def record_failure(task_id: str, gate_id: str) -> EscalationRecord:
    """记录一次 gate 失败。返回升级记录。"""
    k = _key(task_id, gate_id)
    if k not in _escalations:
        _escalations[k] = EscalationRecord(
            task_id=task_id,
            gate_id=gate_id,
            retries=0,
            timestamp=__import__("datetime").datetime.now().isoformat(),
        )
    record = _escalations[k]
    record.retries += 1
    record.timestamp = __import__("datetime").datetime.now().isoformat()
    return record


def should_escalate(task_id: str, gate_id: str) -> bool:
    """判断是否需要升级到人。"""
    k = _key(task_id, gate_id)
    if k not in _escalations:
        return False
    record = _escalations[k]
    return record.retries >= MAX_RETRIES and not record.resolved


def mark_resolved(task_id: str, gate_id: str):
    """标记升级已解决。"""
    k = _key(task_id, gate_id)
    if k in _escalations:
        _escalations[k].resolved = True


def get_escalation_message(task_id: str, gate_id: str) -> Optional[str]:
    """获取升级消息。"""
    if not should_escalate(task_id, gate_id):
        return None
    record = _escalations[_key(task_id, gate_id)]
    return (
        f"⚠️ 已检测到连续 {record.retries} 次 {gate_id} 未通过\n"
        "→ 需要你介入看一下\n"
        "→ 入口: 直接告诉我你的想法"
    )
