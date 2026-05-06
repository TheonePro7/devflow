"""升级机制测试。"""

from __future__ import annotations

from devflow.engine.escalation import (
    record_failure,
    should_escalate,
    mark_resolved,
    get_escalation_message,
    MAX_RETRIES,
)


class TestEscalation:
    def test_no_failure_no_escalation(self):
        assert should_escalate("task-x", "gate-y") is False

    def test_one_failure_no_escalation(self):
        record_failure("task-1", "gate-a")
        assert should_escalate("task-1", "gate-a") is False

    def test_max_retries_triggers_escalation(self):
        for _ in range(MAX_RETRIES):
            record_failure("task-2", "gate-b")
        assert should_escalate("task-2", "gate-b") is True

    def test_resolved_stops_escalation(self):
        for _ in range(MAX_RETRIES):
            record_failure("task-3", "gate-c")
        assert should_escalate("task-3", "gate-c") is True
        mark_resolved("task-3", "gate-c")
        assert should_escalate("task-3", "gate-c") is False

    def test_different_gates_independent(self):
        for _ in range(MAX_RETRIES):
            record_failure("task-4", "gate-d")
        record_failure("task-4", "gate-e")  # only 1 for gate-e
        assert should_escalate("task-4", "gate-d") is True
        assert should_escalate("task-4", "gate-e") is False

    def test_different_tasks_independent(self):
        for _ in range(MAX_RETRIES):
            record_failure("task-5", "gate-f")
        record_failure("task-6", "gate-f")  # only 1 for different task
        assert should_escalate("task-5", "gate-f") is True
        assert should_escalate("task-6", "gate-f") is False

    def test_get_escalation_message_when_not_escalated(self):
        msg = get_escalation_message("task-7", "gate-g")
        assert msg is None

    def test_get_escalation_message_when_escalated(self):
        for _ in range(MAX_RETRIES):
            record_failure("task-8", "gate-h")
        msg = get_escalation_message("task-8", "gate-h")
        assert msg is not None
        assert "连续" in msg

    def test_get_escalation_message_after_resolved(self):
        for _ in range(MAX_RETRIES):
            record_failure("task-9", "gate-i")
        mark_resolved("task-9", "gate-i")
        msg = get_escalation_message("task-9", "gate-i")
        assert msg is None
