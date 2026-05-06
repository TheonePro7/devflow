# ADR 0003: Devflow Engine Architecture — Python CLI 状态机引擎

## 状态

已批准（2026-06-07）

## 背景

现有 devflow 架构存在 5 个根本问题：
1. 状态存 `.devflow/state` JSON 文件，agent 靠自觉读取和遵守
2. 门禁是 PreToolUse hook 告警，不是强制执行
3. beads/gitnexus/autoresearch/superpowers 之间数据不贯通
4. 流程线性"等人按按钮"，不能自主推进
5. SKILL.md 4.6 万字过度臃肿

目标：将 devflow 从"规范集合"升级为"自主工程引擎"。

## 决策

用 Python CLI 工具 (`devflow`) 作为核心引擎，包含 3 层架构：

```
状态机引擎 → 门禁系统 → 工具编排层 → beads 持久化存储
```

### 核心原则

1. **约束架构化** — 不是"建议你不要做"，而是"不满足条件做不了"
2. **数据贯通** — beads 是唯一事实来源，所有工具 IO 过 beads
3. **自主推进** — agent 进入 devflow 后系统自动往前走
4. **升级到人** — 连续失败 3 次自动暂停等人介入

### 技术选型

- **语言**: Python 3.11+
- **CLI 框架**: argparse（内置，零依赖）
- **持久化**: beads CLI（通过子进程调用）
- **代码分析**: gitnexus CLI/MCP
- **自动优化**: autoresearch skill
- **流程纪律**: superpowers skills
- **测试**: pytest

### 数据模型

所有数据存 beads，5 种 issue type：

| Type | 用途 | 创建时机 |
|------|------|---------|
| epic | 功能级大项，对应 PRD | Phase 1 完成 |
| task | 具体实现任务 | Phase 4 writing-plans |
| gate | 门禁记录（probe/security/verify） | 各门禁触发点 |
| state | 状态转移历史 | 每次 transition |
| decision | 设计决策，对应 ADR | Phase 2 或任意设计决策时 |

### 命令集

```
devflow state                  # 显示当前状态 + 可用操作
devflow transition <phase>     # 状态转移（含条件检查）
devflow gate check <task>      # 检查 task 门禁条件
devflow gate run-* <task>      # 运行具体门禁
devflow task create <epic>     # 创建 task
devflow task close <task>      # 关闭 task（检查所有门禁）
devflow sync                   # 同步各工具状态到 beads
```

### Agent 交互模式

引擎不执行实际工程工作（不写代码、不跑测试），只负责：
1. 告诉 agent "当前状态是什么"
2. 告诉 agent "下一步该做什么"
3. 检查 agent 做完的条件是否满足
4. 条件不满足时，告诉 agent "缺什么，怎么补"

## 影响

### 正面

- 状态机逻辑不受 agent 记忆影响
- 可加测试覆盖（pytest 测状态转移）
- 跨项目复用（装一次 devflow 所有项目受益）
- agent 无法绕过门禁

### 负面

- 需要开发完整的 Python CLI 工具
- 需要处理 Python 运行时依赖
- 现有 hooks/scripts 需要迁移

### 兼容性

- 现有 `.devflow/state` 文件废弃，迁移到 beads
- 现有 hooks 保留但逐步替换为 devflow CLI 调用
- 现有 scripts 保留但标记为 deprecated

## 实施计划

### 阶段一：核心引擎（3-5 天）

- Python 项目骨架
- 状态机引擎（Phase 1-5 + 转移条件）
- devflow state / transition 命令
- beads 适配器
- 基本门禁检查

### 阶段二：工具深度集成（5-7 天）

- gitnexus 适配器
- autoresearch 适配器
- 完整门禁检查
- PreToolUse hook 改造

### 阶段三：自主推进（5-7 天）

- 自主推进循环
- 升级到人机制
- 安装脚本重写
- 可选 MCP server
