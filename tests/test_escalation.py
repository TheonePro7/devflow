"""升级机制测试。"""

from __future__ import annotations

import json
import tempfile
from pathlib import Path

from devflow.engine.escalation import (
    MAX_RETRIES,
    EscalationStore,
)


class TestEscalation:
    def test_no_failure_no_escalation(self):
        store = EscalationStore()
        assert store.should_escalate("task-x", "gate-y") is False

    def test_one_failure_no_escalation(self):
        store = EscalationStore()
        store.record_failure("task-1", "gate-a")
        assert store.should_escalate("task-1", "gate-a") is False

    def test_max_retries_triggers_escalation(self):
        store = EscalationStore()
        for _ in range(MAX_RETRIES):
            store.record_failure("task-2", "gate-b")
        assert store.should_escalate("task-2", "gate-b") is True

    def test_resolved_stops_escalation(self):
        store = EscalationStore()
        for _ in range(MAX_RETRIES):
            store.record_failure("task-3", "gate-c")
        assert store.should_escalate("task-3", "gate-c") is True
        store.mark_resolved("task-3", "gate-c")
        assert store.should_escalate("task-3", "gate-c") is False

    def test_different_gates_independent(self):
        store = EscalationStore()
        for _ in range(MAX_RETRIES):
            store.record_failure("task-4", "gate-d")
        store.record_failure("task-4", "gate-e")  # only 1 for gate-e
        assert store.should_escalate("task-4", "gate-d") is True
        assert store.should_escalate("task-4", "gate-e") is False

    def test_different_tasks_independent(self):
        store = EscalationStore()
        for _ in range(MAX_RETRIES):
            store.record_failure("task-5", "gate-f")
        store.record_failure("task-6", "gate-f")  # only 1 for different task
        assert store.should_escalate("task-5", "gate-f") is True
        assert store.should_escalate("task-6", "gate-f") is False

    def test_get_escalation_message_when_not_escalated(self):
        store = EscalationStore()
        msg = store.get_escalation_message("task-7", "gate-g")
        assert msg is None

    def test_get_escalation_message_when_escalated(self):
        store = EscalationStore()
        for _ in range(MAX_RETRIES):
            store.record_failure("task-8", "gate-h")
        msg = store.get_escalation_message("task-8", "gate-h")
        assert msg is not None
        assert "连续" in msg

    def test_get_escalation_message_after_resolved(self):
        store = EscalationStore()
        for _ in range(MAX_RETRIES):
            store.record_failure("task-9", "gate-i")
        store.mark_resolved("task-9", "gate-i")
        msg = store.get_escalation_message("task-9", "gate-i")
        assert msg is None

    # ========== 持久化测试 ==========

    def test_persistence_writes_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            store = EscalationStore(path)
            for _ in range(MAX_RETRIES):
                store.record_failure("task-p1", "gate-p1")

            escalation_file = path / ".devflow" / "escalation.json"
            assert escalation_file.exists()
            data = json.loads(escalation_file.read_text(encoding="utf-8"))
            assert "task-p1:gate-p1" in data
            assert data["task-p1:gate-p1"]["retries"] == MAX_RETRIES

    def test_persistence_survives_restart(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            # 第一次：记录失败
            store1 = EscalationStore(path)
            for _ in range(MAX_RETRIES):
                store1.record_failure("task-p2", "gate-p2")

            # 模拟进程重启：新建 store 实例
            store2 = EscalationStore(path)
            assert store2.should_escalate("task-p2", "gate-p2") is True
            store2.mark_resolved("task-p2", "gate-p2")
            assert store2.should_escalate("task-p2", "gate-p2") is False

    def test_persistence_empty_no_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)
            store = EscalationStore(path)
            assert store.should_escalate("anything", "anything") is False
            escalation_file = path / ".devflow" / "escalation.json"
            assert not escalation_file.exists()  # 没有失败记录就不写文件
