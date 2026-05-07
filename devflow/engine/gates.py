"""门禁系统 — Task close 的前置条件检查和执行。"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class GateCondition:
    """单个 task 关闭条件定义。"""
    id: str
    field: str
    expected: bool
    hint: str
    phase: int = 4
    auto_fix: Optional[str] = None
    optional: bool = False


@dataclass
class GateResult:
    """门禁检查结果。"""
    condition: GateCondition
    actual: bool
    passed: bool

    def to_dict(self) -> dict:
        return {
            "id": self.condition.id,
            "field": self.condition.field,
            "expected": self.condition.expected,
            "actual": self.actual,
            "passed": self.passed,
            "hint": self.condition.hint,
            "auto_fix": self.condition.auto_fix,
            "optional": self.condition.optional,
        }


# Task 关闭必须满足的条件（硬编码，引擎核心规则）
TASK_CLOSE_CONDITIONS = [
    GateCondition(
        id="gitnexus_impact_checked",
        field="gitnexus_impact_checked",
        expected=True,
        hint="执行 devflow gate run-impact-analysis <task_id>",
        auto_fix="devflow gate run-impact-analysis",
    ),
    GateCondition(
        id="verification_evidence",
        field="verification_evidence",
        expected=True,
        hint="执行 devflow gate run-verification <task_id>",
        auto_fix="devflow gate run-verification",
    ),
    GateCondition(
        id="design_approved",
        field="design_approved",
        expected=True,
        hint="设计未批准，需要先完成 brainstorming 阶段的设计审批",
        auto_fix=None,
    ),
    GateCondition(
        id="security_checked",
        field="security_checked",
        expected=True,
        hint="执行 devflow gate run-security <task_id>",
        auto_fix="devflow gate run-security",
        optional=True,
    ),
]


from devflow.engine.escalation import record_failure as _record_escalation_failure


def record_gate_failure(gate_id: str, task_id: str):
    """记录一次 gate 失败委托给 escalation 模块。返回兼容对象。"""
    record = _record_escalation_failure(task_id, gate_id)
    # 返回兼容 duck-type 对象（有 .retries 属性）
    return record


def check_task_close_conditions(task: dict, bead_adapter) -> list[GateResult]:
    """检查一个 task 是否满足所有关闭条件。

    Args:
        task: beads task 的数据字典
        bead_adapter: beads 适配器实例

    Returns:
        list[GateResult]: 所有条件的检查结果
    """
    results = []
    for condition in TASK_CLOSE_CONDITIONS:
        actual = task.get(condition.field, False)
        results.append(GateResult(
            condition=condition,
            actual=actual,
            passed=(actual == condition.expected),
        ))
    return results


def get_failed_conditions(gate_results: list[GateResult]) -> list[GateResult]:
    """获取所有未通过且非可选的条件的检查结果。"""
    return [r for r in gate_results if not r.passed and not r.condition.optional]


def can_close_task(task: dict, bead_adapter) -> tuple[bool, list[GateResult]]:
    """判断 task 是否能关闭。

    Returns:
        (can_close, all_results)
    """
    results = check_task_close_conditions(task, bead_adapter)
    failed = get_failed_conditions(results)
    return len(failed) == 0, results
