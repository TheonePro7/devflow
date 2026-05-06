"""状态机引擎 — Phase 定义、状态转移、条件检查。"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


@dataclass
class ConditionResult:
    """单个条件的检查结果。"""
    id: str
    description: str
    met: bool
    hint: str

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "description": self.description,
            "met": self.met,
            "hint": self.hint,
        }


@dataclass
class Phase:
    """单个 Phase 的定义。"""
    id: str
    name: str
    next: Optional[str]
    conditions: list[dict] = field(default_factory=list)
    loop: bool = False
    auto_transition: bool = False
    description: str = ""

    @classmethod
    def from_dict(cls, phase_id: str, data: dict) -> "Phase":
        return cls(
            id=phase_id,
            name=data.get("name", phase_id),
            next=data.get("next"),
            conditions=data.get("conditions", []),
            loop=data.get("loop", False),
            auto_transition=data.get("auto_transition", False),
            description=data.get("description", ""),
        )

    def check_conditions(self, bead_adapter) -> list[ConditionResult]:
        """检查当前 phase 的所有出口条件。"""
        results = []
        for cond in self.conditions:
            met = bead_adapter.check_condition(cond["id"])
            results.append(ConditionResult(
                id=cond["id"],
                description=cond["description"],
                met=met,
                hint=cond.get("hint", ""),
            ))
        return results


class StateMachine:
    """状态机 — 管理 Phase 生命周期和状态转移。"""

    def __init__(self, phases_path: Optional[Path] = None):
        self.phases_path = phases_path or Path(__file__).parent.parent / "data" / "phases.json"
        self.phases: dict[str, Phase] = {}
        self._load_phases()

    def _load_phases(self):
        """从 phases.json 加载所有 phase 定义。"""
        if not self.phases_path.exists():
            raise FileNotFoundError(f"Phase 定义文件不存在: {self.phases_path}")
        with open(self.phases_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        for phase_id, phase_data in data["phases"].items():
            self.phases[phase_id] = Phase.from_dict(phase_id, phase_data)
        self.entry = data["flow"]["entry"]
        self.terminal = data["flow"]["terminal"]

    def get_phase(self, phase_id: str) -> Optional[Phase]:
        return self.phases.get(phase_id)

    def get_next_phase_id(self, current_id: str) -> Optional[str]:
        phase = self.get_phase(current_id)
        if phase:
            return phase.next
        return None

    def can_transition(self, current_id: str, bead_adapter) -> tuple[bool, list[ConditionResult]]:
        """检查是否能从当前 phase 转移到下一个。

        Returns:
            (can_transition, failed_conditions)
        """
        phase = self.get_phase(current_id)
        if not phase:
            return False, []

        if phase.loop:
            # loop phase 没有固定出口条件，由外部逻辑控制
            return True, []

        results = phase.check_conditions(bead_adapter)
        failed = [r for r in results if not r.met]
        return len(failed) == 0, failed

    def get_available_transitions(self, current_id: str) -> list[dict]:
        """获取从当前 phase 可用的转移路径。"""
        phase = self.get_phase(current_id)
        if not phase:
            return []

        transitions = []
        if phase.next:
            next_phase = self.get_phase(phase.next)
            transitions.append({
                "from": current_id,
                "to": phase.next,
                "to_name": next_phase.name if next_phase else phase.next,
                "label": f"{phase.next}/start",
            })
        return transitions

    def get_state(self, bead_adapter) -> dict:
        """获取当前完整状态。"""
        current_id = bead_adapter.get_current_phase() or self.entry
        phase = self.get_phase(current_id)

        if not phase:
            return {"error": f"未知 phase: {current_id}"}

        can_transition, failed_conditions = self.can_transition(current_id, bead_adapter)
        available = self.get_available_transitions(current_id)

        return {
            "phase": current_id,
            "phase_name": phase.name,
            "description": phase.description,
            "can_transition": can_transition,
            "loop": phase.loop,
            "can_auto_transition": phase.auto_transition,
            "conditions": [c.to_dict() for c in failed_conditions],
            "available_transitions": available,
            "next_phase": phase.next,
        }
