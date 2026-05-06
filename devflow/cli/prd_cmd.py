"""devflow prd 命令 — IDEATE 产出转 PRD markdown。"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

PRD_TEMPLATE = """# PRD: {title}

> 生成时间: {date}
> 来源: devflow ideate

---

## 1. 背景与目标

{background}

---

## 2. 目标用户

{target_users}

---

## 3. 场景与痛点

{scenario_pain}

---

## 4. 现有方案分析

{alternatives}

---

## 5. 成功标准

{success_criteria}

---

## 6. 范围

### MVP 范围
- （此部分需在 Design 阶段补充）

### 后续迭代
- （此部分需在 Design 阶段补充）

---

## 7. 非功能性需求（可选）

- （此部分需在 Design 阶段补充）

---

## 8. 风险评估

- （此部分需在 Design 阶段补充）

---

*PRD 由 devflow ideate 自动生成 — 请在 Design 阶段补充完整。*
"""

STAGE_LABELS = {
    "users": "目标用户分析",
    "scenario": "场景与痛点分析",
    "alternatives": "竞品分析",
    "success": "成功标准定义",
}


def run_prd(args: argparse.Namespace):
    """从 ideate 草稿生成 PRD markdown。"""
    project_path = Path(args.path) if args.path else Path.cwd()
    draft_file = project_path / ".devflow" / "ideate.json"

    if not draft_file.exists():
        print(f"  ❌ 未找到 IDEATE 草稿: {draft_file}")
        print(f"  请先运行 devflow ideate\n")
        sys.exit(1)

    with open(draft_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    answers = data.get("answers", {})
    if not answers:
        print(f"  ❌ IDEATE 草稿为空，请运行 devflow ideate\n")
        sys.exit(1)

    # 从回答中提取各阶段内容
    target_users = answers.get("users", {}).get("answer", "（待补充）")
    scenario_pain = answers.get("scenario", {}).get("answer", "（待补充）")
    alternatives = answers.get("alternatives", {}).get("answer", "（待补充）")
    success_criteria = answers.get("success", {}).get("answer", "（待补充）")

    # 从第一条回答提取标题
    first_answer = next(
        (a["answer"] for a in answers.values() if a.get("answer")),
        ""
    )
    title = first_answer.split("\n")[0][:60] if first_answer else "未命名项目"
    if args.title:
        title = args.title

    background = data.get("summary", (target_users + "\n" + scenario_pain)[:200])

    prd_content = PRD_TEMPLATE.format(
        title=title,
        date=datetime.now().strftime("%Y-%m-%d"),
        background=background,
        target_users=target_users,
        scenario_pain=scenario_pain,
        alternatives=alternatives,
        success_criteria=success_criteria,
    )

    # 写入 docs/prd/
    prd_dir = project_path / "docs" / "prd"
    prd_dir.mkdir(parents=True, exist_ok=True)

    filename_slug = title.lower().replace(" ", "-")[:40]
    prd_path = prd_dir / f"{datetime.now().strftime('%Y-%m-%d')}-{filename_slug}.md"

    if prd_path.exists() and not args.force:
        print(f"  ⚠️  文件已存在: {prd_path}")
        print(f"  使用 --force 覆盖\n")
        sys.exit(1)

    prd_path.write_text(prd_content, encoding="utf-8")
    print(f"\n  ✅ PRD 已生成: {prd_path}\n")

    # 更新 beads 记录
    from devflow.protocols.beads_adapter import BeadsAdapter
    adapter = BeadsAdapter(project_path)
    summary = f"PRD generated: {title}"
    adapter.create_state_record("prd", summary)
    print(f"  💾 状态记录已保存\n")
