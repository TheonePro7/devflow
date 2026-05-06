"""状态机引擎测试。"""

from __future__ import annotations

import json
import os
import tempfile
from pathlib import Path

import pytest

from devflow.engine.state_machine import StateMachine, Phase, ConditionResult


SAMPLE_PHASES = {
    "phases": {
        "phase-0": {
            "name": "未初始化",
            "next": "phase-1",
            "conditions": [],
            "description": "Starting point.",
        },
        "phase-1": {
            "name": "Ideate",
            "next": "phase-2",
            "conditions": [
                {"id": "EPIC_EXISTS", "description": "Has an epic", "hint": "Create an epic"},
            ],
            "description": "Planning.",
        },
        "phase-4": {
            "name": "Develop",
            "next": "phase-5",
            "conditions": [],
            "loop": True,
            "description": "Coding loop.",
        },
        "phase-5": {
            "name": "Finish",
            "next": None,
            "conditions": [],
            "description": "Done.",
        },
    },
    "flow": {
        "entry": "phase-0",
        "terminal": "phase-5",
        "phases_order": ["phase-0", "phase-1", "phase-2", "phase-4", "phase-5"],
    },
}


@pytest.fixture
def phases_file():
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", encoding="utf-8", delete=False) as f:
        json.dump(SAMPLE_PHASES, f, ensure_ascii=False)
        f.flush()
        yield Path(f.name)
    os.unlink(f.name)


@pytest.fixture
def sm(phases_file):
    return StateMachine(phases_path=phases_file)


class MockBeadsAdapter:
    """测试用 mock beads 适配器。"""

    def __init__(self, condition_results: dict[str, bool] | None = None):
        self._results = condition_results or {}

    def get_current_phase(self) -> str | None:
        return None

    def check_condition(self, condition_id: str) -> bool:
        return self._results.get(condition_id, False)


class TestPhase:
    def test_from_dict(self):
        data = {"name": "Test", "next": "phase-2", "conditions": [], "description": "Test phase."}
        phase = Phase.from_dict("phase-1", data)
        assert phase.id == "phase-1"
        assert phase.name == "Test"
        assert phase.next == "phase-2"
        assert phase.description == "Test phase."
        assert phase.loop is False

    def test_loop_default_false(self):
        data = {"name": "Loop", "next": None}
        phase = Phase.from_dict("phase-x", data)
        assert phase.loop is False

    def test_check_conditions_all_pass(self):
        data = {"name": "Test", "next": None, "conditions": [
            {"id": "C1", "description": "Condition 1", "hint": "Do it"},
        ]}
        phase = Phase.from_dict("phase-t", data)
        results = phase.check_conditions(MockBeadsAdapter({"C1": True}))
        assert len(results) == 1
        assert results[0].met is True

    def test_check_conditions_fail(self):
        data = {"name": "Test", "next": None, "conditions": [
            {"id": "C1", "description": "Condition 1", "hint": "Do it"},
        ]}
        phase = Phase.from_dict("phase-t", data)
        results = phase.check_conditions(MockBeadsAdapter({"C1": False}))
        assert len(results) == 1
        assert results[0].met is False


class TestStateMachine:
    def test_load_phases(self, sm):
        assert "phase-0" in sm.phases
        assert len(sm.phases) == 4

    def test_entry_and_terminal(self, sm):
        assert sm.entry == "phase-0"
        assert sm.terminal == "phase-5"

    def test_get_phase(self, sm):
        phase = sm.get_phase("phase-0")
        assert phase is not None
        assert phase.name == "未初始化"

    def test_get_phase_unknown(self, sm):
        assert sm.get_phase("nonexistent") is None

    def test_get_next_phase_id(self, sm):
        assert sm.get_next_phase_id("phase-0") == "phase-1"
        assert sm.get_next_phase_id("phase-5") is None

    def test_get_next_phase_id_unknown(self, sm):
        assert sm.get_next_phase_id("nonexistent") is None

    def test_can_transition_no_conditions(self, sm):
        can, failed = sm.can_transition("phase-0", MockBeadsAdapter())
        assert can is True
        assert len(failed) == 0

    def test_can_transition_loop_skips_conditions(self, sm):
        can, failed = sm.can_transition("phase-4", MockBeadsAdapter())
        assert can is True
        assert len(failed) == 0

    def test_can_transition_condition_fails(self, sm):
        can, failed = sm.can_transition("phase-1", MockBeadsAdapter({"EPIC_EXISTS": False}))
        assert can is False
        assert len(failed) == 1
        assert failed[0].id == "EPIC_EXISTS"

    def test_can_transition_condition_passes(self, sm):
        can, failed = sm.can_transition("phase-1", MockBeadsAdapter({"EPIC_EXISTS": True}))
        assert can is True
        assert len(failed) == 0

    def test_can_transition_unknown_phase(self, sm):
        can, failed = sm.can_transition("unknown", MockBeadsAdapter())
        assert can is False
        assert len(failed) == 0

    def test_get_available_transitions(self, sm):
        ts = sm.get_available_transitions("phase-0")
        assert len(ts) == 1
        assert ts[0]["to"] == "phase-1"
        assert ts[0]["label"] == "phase-1/start"

    def test_get_available_transitions_terminal(self, sm):
        ts = sm.get_available_transitions("phase-5")
        assert len(ts) == 0

    def test_get_available_transitions_unknown(self, sm):
        ts = sm.get_available_transitions("unknown")
        assert len(ts) == 0

    def test_get_state(self, sm):
        state = sm.get_state(MockBeadsAdapter())
        assert state["phase"] == "phase-0"
        assert state["phase_name"] == "未初始化"
        assert "error" not in state

    def test_get_state_loop_phase(self, sm):
        state = sm.get_state(MockBeadsAdapter())
        # 手动用 phase-4
        class MockPhase4Adapter:
            def get_current_phase(self):
                return "phase-4"
            def check_condition(self, cid: str) -> bool:
                return False

        state = sm.get_state(MockPhase4Adapter())
        assert state["phase"] == "phase-4"
        assert state["loop"] is True
        assert state["can_transition"] is True  # loop 总是可转移
