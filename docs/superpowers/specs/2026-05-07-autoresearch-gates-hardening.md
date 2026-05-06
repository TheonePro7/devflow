# Autoresearch Gates Hardening Design

> **将 4 道自动门禁从文档变为不可跳过的强制执行机制**

**Goal:** Phase 4 的 4 个 autoresearch 门禁（probe/scenario/fix/security）当前只在 SKILL.md 中被记录为"建议"，没有任何强制力。本设计将其改造为：通过 `.devflow/state` 追踪 + Hook 硬拦截 + SKILL.md 流程强化的 3 层机制，使门禁无法被跳过。

**Architecture:** 3 层加固:
1. **状态层** — `.devflow/state` 增加 `gate_probe/gate_scenario/gate_fix/gate_security` 字段
2. **拦截层** — `devflow-phase-check` hooks 在 PreToolUse(Edit|Write) 时检查 gate 状态并硬拦截
3. **流程层** — SKILL.md 中每个 gate 从"建议 ★ AUTO"改为"强制执行步骤"，agent 必须更新 state 才能继续

**Tech Stack:** PowerShell 5.1, Bash, JSON state file, Claude Code PreToolUse hooks

---

## State Schema

```json
{
  "phase": 4,
  "step": "grill",           // 当前 Phase 4 子步骤
  "gate_probe": "pending",   // pending | done | skipped
  "gate_scenario": "pending",
  "gate_fix": "pending",
  "gate_security": "pending"
}
```

`skipped` 允许用户明确 opt-out（如 "skip security audit"）。

## Hook 拦截规则

在 `devflow-phase-check` 的 Phase 4 分支中：

| 当前 step | gate 检查 | 拦截条件 | 拦截消息 |
|-----------|-----------|----------|----------|
| `plans` | `gate_probe` | != done | "⛔ 必须先运行 /autoresearch:probe 才能进入 writing-plans 阶段。运行后请设置 state: gate_probe=done" |
| `impl` | `gate_scenario` | != done | "⛔ 必须先运行 /autoresearch:scenario 才能开始实现。运行后请设置 state: gate_scenario=done" |
| `finish` | `gate_security` | != done | "⛔ 必须先运行 /autoresearch:security --diff 才能 finish-branch。运行后请设置 state: gate_security=done" |

> `gate_fix` 是 per-task 质量门禁，由 SKILL.md 流程强制（每个 task 完成后必须走 fix），Hook 不做 per-task 追踪。

## 文件变更

| 文件 | 变更说明 |
|------|----------|
| `.devflow/state` | 增加 4 个 gate 字段，默认 `pending` |
| `SKILL.md` Phase 4 各 gate 描述 | 从"★ AUTO"改为"★ 强制执行"，加入 state 更新指令 |
| `setup.ps1` Step 5.5 | state 初始化模板增加 gate 字段 |
| `setup.sh` Step 5.5 | state 初始化模板增加 gate 字段 |
| `devflow-phase-check.ps1` Phase 4 分支 | 增加 gate 状态检查和硬拦截逻辑 |
| `devflow-phase-check.sh` Phase 4 分支 | 增加 gate 状态检查和硬拦截逻辑 |
