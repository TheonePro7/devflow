"""devflow ideate 命令 — 4 阶段需求梳理引导。"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

from devflow.protocols.beads_adapter import BeadsAdapter


STAGES = [
    {
        "id": "users",
        "title": "目标用户",
        "prompt": (
            "这个产品的目标用户是谁？\n"
            "  • 他们的角色 / 身份\n"
            "  • 技术背景（工程师？设计师？普通用户？）\n"
            "  • 使用频率（每天？每周？偶尔？）"
        ),
        "key": "target_users",
        "label": "目标用户分析",
    },
    {
        "id": "scenario",
        "title": "场景与痛点",
        "prompt": (
            "用户在什么场景下使用这个产品？\n"
            "  • 核心使用场景是什么？\n"
            "  • 目前用什么方式解决？\n"
            "  • 现有方案有什么痛点？"
        ),
        "key": "scenario_pain",
        "label": "场景与痛点分析",
    },
    {
        "id": "alternatives",
        "title": "现有方案",
        "prompt": (
            "市面上有哪些类似方案？\n"
            "  • 直接竞品\n"
            "  • 间接竞品（用不同方式解决同一个问题）\n"
            "  • 我们相比有什么差异化优势？"
        ),
        "key": "alternatives",
        "label": "竞品分析",
    },
    {
        "id": "success",
        "title": "成功标准",
        "prompt": (
            "怎么衡量这个产品成功了？\n"
            "  • 核心指标（DAU？完成率？节省时间？）\n"
            "  • 最小可行范围是什么？\n"
            "  • 哪些功能可以后续迭代？"
        ),
        "key": "success_criteria",
        "label": "成功标准定义",
    },
]


def run_ideate(args: argparse.Namespace):
    """启动 4 阶段需求梳理。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    bead_adapter = BeadsAdapter(project_path)
    resume_from = args.resume

    print(f"\n{'=' * 56}")
    print(f"  Phase 1: Ideate — 需求梳理")
    print(f"  {'=' * 56}")
    print(f"  只讨论【做什么】，不讨论【怎么做】。")
    print(f"  每阶段完成后你可以补充或进入下一阶段。\n")

    # 加载已有进度（resume 模式）
    results = _load_existing(project_path)
    if results and "answers" in results:
        print(f"  📂 发现已有草稿（{len(results.get('answers', {}))} 阶段已完成）\n")

    for stage in STAGES:
        stage_id = stage["id"]
        # 如果已有答案且不强制重新开始，询问是否跳过
        if stage_id in results.get("answers", {}):
            if not args.force:
                print(f"  ✅ [{stage['label']}] 已有记录，跳过（--force 重新回答）\n")
                continue

        print(f"\n  ── [{stage['title']}] ──")
        print(f"\n  {stage['prompt']}\n")
        print(f"  (输入回答，空行结束，输入 'skip' 跳过)\n")

        lines = []
        while True:
            try:
                line = input("  > ")
            except (EOFError, KeyboardInterrupt):
                print()
                _save_draft(project_path, results)
                print(f"\n  ⏸️  已保存草稿。下次用 --resume 继续。\n")
                sys.exit(0)

            if line.strip().lower() == "skip":
                break
            if line.strip() == "":
                break
            lines.append(line.strip())

        if lines:
            answer = "\n".join(lines)
            results.setdefault("answers", {})[stage_id] = {
                "question": stage["title"],
                "answer": answer,
                "timestamp": datetime.now().isoformat(),
            }
            _save_draft(project_path, results)
            print(f"  ✅ [{stage['label']}] 已记录\n")

    # 所有阶段完成 → 生成摘要
    answers = results.get("answers", {})
    if len(answers) >= 4 or args.force:
        print(f"\n{'=' * 56}")
        print(f"  所有阶段完成！生成摘要...\n")

        summary = _generate_summary(answers)
        results["summary"] = summary
        results["completed_at"] = datetime.now().isoformat()
        _save_draft(project_path, results)

        print(f"  📋 需求摘要:\n")
        print(f"  {summary}\n")

        # 询问是否创建 epic
        try:
            resp = input("  是否创建 epic 并进入下一阶段？(Y/n): ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            resp = "n"

        if resp in ("", "y", "yes"):
            _create_epic_from_ideate(bead_adapter, results, project_path)
    else:
        print(f"\n  ⚠️  完成了 {len(answers)}/4 阶段。")
        print(f"  用 devflow ideate --resume 继续\n")


def _load_existing(project_path: Path) -> dict:
    """加载已有的 ideate 草稿。"""
    draft_file = project_path / ".devflow" / "ideate.json"
    if draft_file.exists():
        try:
            with open(draft_file, "r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            pass
    return {"answers": {}}


def _save_draft(project_path: Path, data: dict):
    """保存 ideate 草稿。"""
    draft_file = project_path / ".devflow" / "ideate.json"
    draft_file.parent.mkdir(parents=True, exist_ok=True)
    with open(draft_file, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def _generate_summary(answers: dict) -> str:
    """从各阶段回答生成简洁摘要。"""
    parts = []
    for stage in STAGES:
        sid = stage["id"]
        if sid in answers:
            answer_text = answers[sid]["answer"]
            # 取第一句或前 100 字作为摘要
            first_line = answer_text.split("\n")[0]
            parts.append(f"[{stage['title']}] {first_line}")
    return "\n".join(parts)


def _create_epic_from_ideate(adapter: BeadsAdapter, data: dict, project_path: Path):
    """从 ideate 结果创建 beads epic。"""
    answers = data.get("answers", {})
    summary = data.get("summary", "")

    # 构建 epic title
    title = summary.split("\n")[0][:80] if summary else "Ideate output"
    # 构建 epic description
    desc_parts = []
    for stage in STAGES:
        sid = stage["id"]
        if sid in answers:
            desc_parts.append(f"## {stage['title']}")
            desc_parts.append(answers[sid]["answer"])
            desc_parts.append("")
    description = "\n".join(desc_parts)

    # 构建 acceptance criteria
    acceptance = ""
    if "success_criteria" in answers:
        acceptance = answers["success_criteria"]["answer"]

    if adapter.is_available():
        title_clean = title.replace('"', "'")
        desc_clean = description.replace('"', "'").replace("\n", "\\n")[:500]
        accept_clean = acceptance.replace('"', "'").replace("\n", "\\n")[:300]
        adapter._run_bd([
            "create", "--type=epic",
            f'--title={title_clean}',
            f'--description={desc_clean}',
            f'--acceptance={accept_clean}',
        ], timeout=10)
        print(f"  ✅ Epic 已创建: {title}")
    else:
        # 降级 — 保存到本地文件
        epic_file = project_path / ".devflow" / "epics.json"
        epics = []
        if epic_file.exists():
            try:
                with open(epic_file, "r", encoding="utf-8") as f:
                    epics = json.load(f)
            except (json.JSONDecodeError, IOError):
                pass
        epics.append({
            "title": title,
            "description": description,
            "acceptance": acceptance,
            "created_at": datetime.now().isoformat(),
            "answers": answers,
        })
        with open(epic_file, "w", encoding="utf-8") as f:
            json.dump(epics, f, ensure_ascii=False, indent=2)
        print(f"  ✅ Epic 已保存到本地: .devflow/epics.json (beads 不可用)")
