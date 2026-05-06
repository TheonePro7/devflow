"""门禁系统测试。"""

from __future__ import annotations

from devflow.engine.gates import (
    GateCondition,
    GateResult,
    TASK_CLOSE_CONDITIONS,
    check_task_close_conditions,
    get_failed_conditions,
    can_close_task,
    record_gate_failure,
    get_escalation_key,
)


class TestGateCondition:
    def test_fields(self):
        c = GateCondition(
            id="test",
            field="test_field",
            expected=True,
            hint="Run test",
        )
        assert c.id == "test"
        assert c.field == "test_field"
        assert c.expected is True
        assert c.phase == 4
        assert c.optional is False
        assert c.auto_fix is None

    def test_optional_condition(self):
        c = GateCondition(id="opt", field="opt", expected=True, hint="", optional=True)
        assert c.optional is True


class TestTaskCloseConditions:
    def test_conditions_defined(self):
        assert len(TASK_CLOSE_CONDITIONS) == 4
        ids = [c.id for c in TASK_CLOSE_CONDITIONS]
        assert "gitnexus_impact_checked" in ids
        assert "verification_evidence" in ids
        assert "design_approved" in ids
        assert "security_checked" in ids

    def test_security_is_optional(self):
        sc = [c for c in TASK_CLOSE_CONDITIONS if c.id == "security_checked"]
        assert len(sc) == 1
        assert sc[0].optional is True

    def test_gitnexus_has_auto_fix(self):
        gc = [c for c in TASK_CLOSE_CONDITIONS if c.id == "gitnexus_impact_checked"]
        assert len(gc) == 1
        assert gc[0].auto_fix is not None


class TestCheckTaskCloseConditions:
    def test_all_pass(self):
        task = {
            "gitnexus_impact_checked": True,
            "verification_evidence": True,
            "design_approved": True,
            "security_checked": True,
        }
        results = check_task_close_conditions(task, None)
        assert all(r.passed for r in results)
        assert len(results) == 4

    def test_some_fail(self):
        task = {
            "gitnexus_impact_checked": False,
            "verification_evidence": True,
            "design_approved": True,
            "security_checked": False,
        }
        results = check_task_close_conditions(task, None)
        failed = get_failed_conditions(results)
        assert len(failed) == 1  # only gitnexus (security is optional)
        assert failed[0].condition.id == "gitnexus_impact_checked"

    def test_all_required_fail(self):
        task = {
            "gitnexus_impact_checked": False,
            "verification_evidence": False,
            "design_approved": False,
            "security_checked": False,
        }
        results = check_task_close_conditions(task, None)
        failed = get_failed_conditions(results)
        assert len(failed) == 3  # security excluded

    def test_missing_field_defaults_false(self):
        task = {}
        results = check_task_close_conditions(task, None)
        failed = get_failed_conditions(results)
        assert len(failed) == 3


class TestCanCloseTask:
    def test_can_close(self):
        task = {
            "gitnexus_impact_checked": True,
            "verification_evidence": True,
            "design_approved": True,
            "security_checked": True,
        }
        can, results = can_close_task(task, None)
        assert can is True

    def test_cannot_close(self):
        task = {
            "gitnexus_impact_checked": False,
            "verification_evidence": True,
            "design_approved": True,
            "security_checked": True,
        }
        can, results = can_close_task(task, None)
        assert can is False

    def test_all_optional_fail_still_closes(self):
        task = {
            "gitnexus_impact_checked": True,
            "verification_evidence": True,
            "design_approved": True,
            "security_checked": False,
        }
        can, results = can_close_task(task, None)
        assert can is True


class TestEscalation:
    def test_record_and_retries(self):
        state = record_gate_failure("test_gate", "task-1")
        assert state.retries == 1
        state = record_gate_failure("test_gate", "task-1")
        assert state.retries == 2

    def test_key_uniqueness(self):
        k1 = get_escalation_key("gate_a", "task-1")
        k2 = get_escalation_key("gate_b", "task-1")
        k3 = get_escalation_key("gate_a", "task-2")
        assert k1 != k2
        assert k1 != k3
