---
name: devflow
description: devflow 5-phase product orchestrator. 从模糊创意到可交付产品。
---

# devflow — 自主工程引擎

## ⚠️ NEW PROJECT DETECTION — 最高优先级

**如果 `.devflow/state` 不存在，说明项目尚未初始化。** 检测到新项目时：

```
1. 检测：读取 .devflow/state — 文件不存在 → 新项目
2. 安装：bash setup.sh（自动安装工具 + 创建 hooks）
3. 验证：确认 .devflow/state 已创建
4. 继续：运行 devflow state 查看当前状态
```

**这是最高优先级规则，不可跳过。**

## 核心工作流

devflow 已从 SKILL.md 升级为独立的 Python CLI 工具（`devflow` 命令）。

### 你的任务

1. **运行 devflow state** 了解当前阶段
2. **按 devflow 的提示执行操作**（transition → 工作 → gate close → 循环）
3. **不要跳步骤** — devflow 引擎会检查条件，不满足会告诉你缺什么

### 人的介入

- **Phase 1（需求梳理）**：深度追问目标用户、痛点、场景、成功标准。不问技术细节。
- **Phase 5（收尾）**：给人看最终结果。
- **其他阶段全自动** — agent 自主推进，不需要人按按钮。

### Phase 快速参考

```
Phase 1: Ideate（需求梳理）       agent 追问，输出 PRD
Phase 2: Design（设计）           agent 出方案 + 自动审批
Phase 3: Setup（项目初始化）      devflow init 自动执行
Phase 4: Develop（开发循环）      自主处理 task → gate close → 下一个
Phase 5: Finish（收尾）           git push + beads close + 报告
```

### 常用命令

```bash
devflow state                    # 查看当前状态
devflow transition <phase>       # 状态转移
devflow gate check <task>        # 检查门禁条件
devflow gate close <task>        # 关闭 task（自动检查所有条件）
devflow task list                # 查看待办 task
```

## 工具生态

devflow 不重新实现以下工具的能力，而是在正确的时间点调用它们：

- **beads** — 记忆和追踪（任务、状态、决策的持久化存储）
- **gitnexus** — 代码知识图谱（影响分析、上下文感知）
- **superpowers-*** — 流程纪律（设计审批、代码审查、工作区隔离）
- **autoresearch** — 质量闭环（probe/security/optimize 验证循环）

## 关键规则

1. **Phase 1 先于一切** — 需求未梳理清楚不得进入设计或编码
2. **无设计审批不得写代码** — Phase 4 brainstorming 的 HARD GATE
3. **无证据不得声称完成** — 每个 task close 前必须有验证
4. **devflow CLI 是事实来源** — 不是 `.devflow/state` 文件
5. **跳过规则 = 系统拒绝** — 门禁条件不满足，task 无法关闭
