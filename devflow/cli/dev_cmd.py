"""devflow dev 命令 — 开发循环自动化。

核心管道（Phase 4）调用 superpowers 技能链:

  devflow dev brainstorm <task_id>
    → superpowers-brainstorming (Design → HARD GATE approval)
    → using-git-worktrees (isolated workspace)
    → bead create sub-tasks

  devflow dev execute <plan_file>
    → superpowers-writing-plans (implementation plan)
    → superpowers-subagent-driven-development (per-task loop)
    → gate run-impact-analysis (per task, via gitnexus)
    → gate run-verification (per task, via autoresearch)
    → superpowers-finishing-a-development-branch (wrap up)

  devflow dev start / finish / next / status
    → 单个 task 生命周期管理（原有）
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Optional

from devflow.protocols.beads_adapter import BeadsAdapter
from devflow.utils import detect_test_commands


# ── Superpowers skill 相关助手 ──────────────────────────────

def _get_additional_dirs() -> list[str]:
    """从 settings.json 读取 additionalDirectories（superpowers skill 路径）。"""
    import json
    for path in [
        Path.cwd() / ".claude" / "settings.json",
        Path.home() / ".claude" / "settings.json",
        Path.cwd() / ".claude" / "settings.local.json",
    ]:
        if path.exists():
            try:
                data = json.loads(path.read_text(encoding="utf-8"))
                dirs = data.get("permissions", {}).get("additionalDirectories", [])
                if dirs:
                    return dirs
            except (json.JSONDecodeError, IOError):
                pass
    return []


def _ensure_superpowers_in_settings():
    """确保 settings.json 里配好了 superpowers 的 additionalDirectories。

    devflow 需要以下 superpowers skill：
      - superpowers-brainstorming
      - superpowers-writing-plans
      - superpowers-using-git-worktrees
      - superpowers-subagent-driven-development
      - superpowers-requesting-code-review
      - superpowers-finishing-a-development-branch
      - superpowers-test-driven-development

    如果缺失，打印修复指引而非自动写入（避免改坏用户配置）。
    """
    required = [
        "superpowers-brainstorming",
        "superpowers-writing-plans",
        "superpowers-using-git-worktrees",
        "superpowers-subagent-driven-development",
        "superpowers-requesting-code-review",
        "superpowers-finishing-a-development-branch",
        "superpowers-test-driven-development",
    ]
    home = Path.home()
    skill_base = home / ".claude" / "skills"

    existing = _get_additional_dirs()
    normalized_existing = {p.replace("\\", "/").lower() for p in existing}

    missing = []
    for name in required:
        skill_dir = str(skill_base / name)
        norm = skill_dir.replace("\\", "/").lower()
        if norm not in normalized_existing:
            missing.append(name)

    if missing:
        print(f"  ⚠️  additionalDirectories 缺失 {len(missing)} 个 superpowers skill:")
        for name in missing:
            print(f"     - {name}")
        print(f"  运行 `devflow doctor --fix` 自动修复\n")


# ── 入口 ────────────────────────────────────────────────────


def run_dev(args: argparse.Namespace):
    """开发循环入口。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)

    action = args.action

    if action == "start":
        _start_task(bead_adapter, args.task_id, project_path)
    elif action == "finish":
        _finish_task(bead_adapter, args.task_id, project_path)
    elif action == "next":
        _next_task(bead_adapter, project_path)
    elif action == "status":
        _dev_status(bead_adapter, project_path)
    elif action == "brainstorm":
        _brainstorm(bead_adapter, args.task_id, project_path)
    elif action == "execute":
        _execute(bead_adapter, args.task_id, project_path)
    else:
        print(f"❌ 未知操作: {action}")
        sys.exit(1)


# ── brainstorm: superpowers-brainstorming 入口 ──────────────


def _brainstorm(adapter: BeadsAdapter, task_id: str, project_path: Path):
    """启动 superpowers-brainstorming 设计流程。

    这是 Phase 4 的入口管道。devflow 做三件事：
      1. 预取上下文（CONTEXT.md、ADR、gitnexus impact）
      2. 创建 beads epic
      3. 打印 Skill 委托指令，让 agent 执行 brainstorming

    真正的设计探索由 superpowers-brainstorming SKILL.md 驱动。
    """
    print(f"\n  {'='*50}")
    print(f"  🧠 Phase 4 → superpowers-brainstorming")
    print(f"  {'='*50}\n")

    _ensure_superpowers_in_settings()

    task = adapter.get_task(task_id) if task_id else None
    feature_name = task.title if task else task_id or "未命名功能"

    # 1. 创建 beads epic（如果未创建）
    from datetime import datetime
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    epic_id = None
    if adapter.is_available():
        code, out, err = adapter.run_bd([
            "create", "--type=epic",
            f"--title={feature_name}",
            f"--description=Brainstorming: {feature_name} ({ts})",
        ])
        if code == 0:
            # 提取 epic ID（beads 输出格式: created <id>）
            for line in out.split("\n"):
                line = line.strip()
                if line and not line.startswith("created"):
                    epic_id = line.split()[-1] if line else None
                    break
            if not epic_id:
                epic_id = out.strip().split()[-1] if out.strip() else None
        print(f"  📌 beads epic: {epic_id or '未创建'}")
    else:
        print(f"  ⚠️  beads 不可用，跳过 epic 创建")

    # 2. 检查 CONTEXT.md + ADR
    context_doc = project_path / "docs" / "CONTEXT.md"
    adr_dir = project_path / "docs" / "adr"
    has_context = context_doc.exists()
    has_adr = adr_dir.exists()
    print(f"  📄 CONTEXT.md: {'✅' if has_context else '⚠️ 未找到（建议创建）'}")
    print(f"  📄 ADR: {'✅' if has_adr else '⚠️ 未找到（建议创建）'}")

    # 3. 尝试 gitnexus context
    from devflow.protocols.gitnexus_adapter import GitNexusAdapter
    gitnexus = GitNexusAdapter(project_path)
    gnx_available, gnx_mode = gitnexus.check_available()
    if gnx_available:
        print(f"  🔍 gitnexus: 可用 (模式: {gnx_mode})")
        status = gitnexus.status()
        if status is None or not status.get("indexed", False):
            print(f"  📦 索引代码库...")
            gitnexus.analyze()
            print(f"  ✅ 索引完成")
    else:
        print(f"  ⚠️  gitnexus: 不可用")

    # 4. 检测前端需求 → 自动注入 UI 设计流程
    from devflow.protocols.ui_design_adapter import UIDesignAdapter
    task_title = task.title if task else task_id or ""
    task_desc = task.description if task else ""
    needs_ui = UIDesignAdapter.has_frontend_needs(task_title, task_desc)

    if needs_ui:
        ui = UIDesignAdapter(project_path)
        print(f"\n  🎨 检测到前端需求，自动触发 UI 设计流程\n")

        if not ui.has_existing_design(feature_name):
            # 执行完整 4 阶段 UI 设计（静默模式，只输出摘要）
            prd_text = ""
            prd_dir = project_path / "docs" / "prd"
            if prd_dir.exists():
                prd_files = sorted(prd_dir.glob("*.md"), reverse=True)
                if prd_files:
                    try:
                        prd_text = prd_files[0].read_text(encoding="utf-8")
                    except IOError:
                        pass

            reqs = ui.extract_ui_requirements(feature_name, prd_text)
            arch = ui.generate_architecture(feature_name, reqs.get("project_type", "landing"))
            plan = ui.plan_scaffold(feature_name, arch)
            result = ui.document_design(feature_name, reqs, arch, plan)

            if result.status == "completed":
                print(f"     ✅ Stage 1/4: UI 需求提取")
                print(f"     ✅ Stage 2/4: 架构蓝图 — {arch['framework']} + {arch['ui_lib']}")
                print(f"     ✅ Stage 3/4: 前端代码方案 — Claude Direct")
                print(f"     ✅ Stage 4/4: 设计文档化 — {result.docs_path}")
                print(f"     📄 设计决策: {len(result.decisions)} 条")
        else:
            print(f"     📂 已有 UI 设计记录 (docs/ux/{feature_name}/)")

    # 5. 查找已有设计文档 → 自动计算下一步
    existing_specs = sorted((project_path / "docs/superpowers/specs").glob("*.md"), reverse=True)
    design_doc_path = None
    for spec in existing_specs:
        content = spec.read_text(encoding="utf-8", errors="replace")
        if feature_name.lower() in content.lower() or (task_id and task_id.lower() in content.lower()):
            design_doc_path = spec
            break

    # 6. 输出 Skill 调用指令（带智能默认路径）
    print(f"\n  {'─'*50}")
    if design_doc_path:
        print(f"  📄 检测到已有设计文档: {design_doc_path.relative_to(project_path)}")
        print(f"  如需重新设计，请运行 /brainstorming 后告知变更\n")
        print(f"  ✅ 可直接进入实施阶段:\n")
        print(f"     devflow dev execute {design_doc_path.relative_to(project_path)}\n")
    else:
        print(f"  下一步：调用 superpowers-brainstorming 技能\n")
        print(f"  1. 在对话中输入:")
        print(f"     /brainstorming")
        print(f"     目标: {feature_name}")
        if epic_id:
            print(f"     beads epic: {epic_id}")
        if needs_ui:
            print(f"     UI 设计产物: docs/ux/{feature_name}/")
        print(f"\n  2. HARD GATE: 设计必须经你批准才能写代码")
        print(f"\n  3. 设计批准后运行:")
        print(f"     devflow dev execute docs/superpowers/specs/<your-design>.md")
    print(f"  {'─'*50}\n")


# ── execute: writing-plans → subagent-driven-development 入口 ─


def _execute(adapter: BeadsAdapter, plan_file: Optional[str], project_path: Path):
    """执行实施管道。

    管道链:
      1. superpowers-writing-plans → 生成实施计划
      2. superpowers-subagent-driven-development → 每个 task 执行
      3. 每个 task 自动触发 gate run-impact-analysis + run-verification
      4. 全部完成 → superpowers-finishing-a-development-branch

    Args:
        plan_file: 设计文档路径（可用 brainstorm 生成，或 auto-discover）
    """
    print(f"\n  {'='*50}")
    print(f"  ⚡ Phase 4 → superpowers 执行管道")
    print(f"  {'='*50}\n")

    _ensure_superpowers_in_settings()

    # 1. 定位设计文档：优先指定路径，否则 auto-discover 最新 spec
    spec_path = None
    if plan_file:
        spec_path = Path(plan_file)
        if not spec_path.is_absolute():
            spec_path = project_path / spec_path
        if not spec_path.exists():
            print(f"  ⚠️  找不到指定设计文档: {spec_path}")
            spec_path = None

    if not spec_path:
        specs_dir = project_path / "docs" / "superpowers" / "specs"
        if specs_dir.exists():
            specs = sorted(specs_dir.glob("*.md"), reverse=True)
            if specs:
                spec_path = specs[0]
                print(f"  📄 自动发现设计文档: {spec_path.relative_to(project_path)}")
            else:
                print(f"  📄 docs/superpowers/specs/ 为空，需要先 brainstorm")
        else:
            print(f"  📄 docs/superpowers/specs/ 不存在，需要先 brainstorm")

    # 2. 检查 gitnexus
    from devflow.protocols.gitnexus_adapter import GitNexusAdapter
    gitnexus = GitNexusAdapter(project_path)
    gnx_available, gnx_mode = gitnexus.check_available()
    if gnx_available:
        print(f"  🔍 gitnexus: 可用 (模式: {gnx_mode})")
    else:
        print(f"  ⚠️  gitnexus: 不可用（影响分析会跳过）")

    # 3. 检查测试框架
    test_commands = detect_test_commands(project_path)
    if test_commands:
        print(f"  🧪 测试框架: {test_commands[0]}")
    else:
        print(f"  ⚠️  未检测到测试框架（验证会跳过）")

    # 4. 输出执行指令（紧凑版）
    print(f"\n  {'─'*50}")
    print(f"  执行管道（依次调用 3 个 superpowers 技能）\n")

    rel = spec_path.relative_to(project_path) if spec_path and spec_path.exists() else None
    if rel:
        print(f"  设计文档: {rel}")
        print(f"\n  ├─ 1/3  /writing-plans")
        print(f"  │    设计文档: {rel}")
    else:
        print(f"  ├─ 1/3  /brainstorming   (先完成设计)")
        print(f"  │     或 /writing-plans   (已有设计文档)")

    print(f"  ├─ 2/3  /subagent-driven-development")
    print(f"  │    在每步自动执行:")
    print(f"  │      devflow gate run-impact-analysis <task-id>")
    print(f"  │      devflow gate run-verification <task-id>")
    print(f"  └─ 3/3  /finishing-a-development-branch")
    print(f"        执行前运行:")
    print(f"          devflow gate run-security <task-id>")
    print(f"  {'─'*50}\n")
    print(f"  {'─'*50}\n")


def _finish_task(adapter: BeadsAdapter, task_id: str, project_path: Path):
    """结束一个 task：验证 + gate close。"""
    print(f"\n  ⏹ 结束 task: {task_id}\n")

    task = adapter.get_task(task_id)
    if not task:
        print(f"  ❌ task {task_id} 未找到")
        sys.exit(1)

    # 运行影响分析
    print(f"  🔍 运行影响分析...")
    from devflow.protocols.gitnexus_adapter import GitNexusAdapter
    gitnexus = GitNexusAdapter(project_path)
    available, mode = gitnexus.check_available()
    if available:
        changes = gitnexus.detect_changes()
        if changes:
            adapter.update_task_field(task_id, "gitnexus_impact_checked", True)
            print(f"  ✅ gitnexus_impact_checked = true\n")

    # 运行验证（如果可用）
    from devflow.protocols.autoresearch_adapter import AutoresearchAdapter
    auto = AutoresearchAdapter(project_path)
    if auto.is_available():
        print(f"  🔍 运行验证...")
        commands = detect_test_commands(project_path)
        if commands:
            result = auto.run_verification(commands[0])
            if result.get("success") and result.get("passed"):
                adapter.update_task_field(task_id, "verification_evidence", True)
                print(f"  ✅ verification_evidence = true\n")

    # 从 beads 读取真实条件状态，不再硬编码
    from devflow.engine.gates import get_task_conditions, can_close_task
    conditions = get_task_conditions(adapter, task_id)
    task_dict = {
        "design_approved": conditions.get("design_approved", False),
        "gitnexus_impact_checked": conditions.get("gitnexus_impact_checked", False),
        "verification_evidence": conditions.get("verification_evidence", False),
        "security_checked": conditions.get("security_checked", False),
    }
    can_close, results = can_close_task(task_dict, adapter)
    if can_close:
        print(f"  ✅ 所有条件满足，task 可以关闭\n")
        print(f"  运行: devflow gate close {task_id}\n")
    else:
        print(f"  ⚠️  部分条件未满足:\n")
        for cond_name, passed in results.items():
            icon = "✅" if passed else "❌"
            print(f"     {icon} {cond_name}")
        print(f"\n  运行: devflow gate check {task_id}\n")


def _next_task(adapter: BeadsAdapter, project_path: Path):
    """查看下一个 ready task。"""
    tasks = adapter.get_tasks(status="ready")
    if tasks:
        t = tasks[0]
        print(f"\n  ▶ 下一个 task: {t.id} — {t.title}\n")
        print(f"  运行: devflow dev start {t.id}\n")
    else:
        # 检查是否有 in_progress 或 open 的
        in_progress = adapter.get_tasks(status="in_progress")
        if in_progress:
            t = in_progress[0]
            print(f"\n  ▶ 进行中的 task: {t.id} — {t.title}\n")
            print(f"  运行: devflow dev finish {t.id}\n")
        else:
            open_tasks = adapter.get_tasks(status="open")
            if open_tasks:
                t = open_tasks[0]
                print(f"\n  📋 待办 task: {t.id} — {t.title}\n")
                print(f"  运行: devflow dev start {t.id}\n")
            else:
                print(f"\n  ✅ 没有待办的 task\n")


def _dev_status(adapter: BeadsAdapter, project_path: Path):
    """显示开发循环概览。"""
    ready = adapter.get_tasks(status="ready")
    in_progress = adapter.get_tasks(status="in_progress")
    open_tasks = adapter.get_tasks(status="open")

    # 读取 devflow state 判断当前 pipeline 步骤
    state_file = project_path / ".devflow" / "state"
    if state_file.exists():
        try:
            import json
            state = json.loads(state_file.read_text(encoding="utf-8"))
            phase = state.get("phase", "")
            step = state.get("step", "")
            if phase == "4":
                step_labels = {
                    "brainstorm": "🧠 brainstorm（设计探索）",
                    "writing-plans": "📝 writing-plans（计划生成）",
                    "subagent-dev": "⚡ subagent-dev（开发实施）",
                    "code-review": "👀 code-review（代码审查）",
                    "security": "🔒 security（安全审计）",
                    "finish": "🏁 finish（收尾）",
                }
                label = step_labels.get(step, step)
                print(f"  📍 当前步骤: {label}")
        except (json.JSONDecodeError, IOError):
            pass

    print(f"\n  📊 开发状态\n")
    print(f"  ▶ 进行中: {len(in_progress)}")
    for t in in_progress:
        print(f"    {t.id}: {t.title}")
    print(f"  📋 待办: {len(open_tasks)}")
    for t in open_tasks[:5]:
        print(f"    {t.id}: {t.title}")
    if len(open_tasks) > 5:
        print(f"    ... 还有 {len(open_tasks) - 5} 个")
    print(f"  🎯 就绪: {len(ready)}")
    for t in ready[:3]:
        print(f"    {t.id}: {t.title}")
    print()




