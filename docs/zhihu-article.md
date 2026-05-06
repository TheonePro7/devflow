# 我如何用 4 层防御链，让 Claude Code 从"健忘实习生"变成"靠谱全栈工程师"

## 一个让人崩溃的场景

如果你用过 Claude Code、Cursor 或者 Copilot，你一定经历过这个场景：

> **你**："帮我把用户注册功能做完，先写设计文档，然后拆任务，逐个实现。"
>
> **AI**："好的！我先写设计文档……（一顿输出）"
>
> **AI**："设计写好了，现在开始实现。"
>
> *（30 分钟后）*
>
> **你**："怎么直接开始写代码了？设计文档还没评审呢。"
>
> **AI**："……什么评审？"

这就像你招了一个聪明但永远记不住流程的实习生：他能把每个任务做得很好，但总是跳过步骤、忘记规范、想到哪做到哪。

为什么？因为 LLM 没有**自觉意识**。每次对话对它来说都是全新开始。它不会"记得"要遵循什么流程——它只有当前上下文里的提示词。

这个问题的本质是：**AI agent 的能力已经足够强了，缺的是让它按流程执行的那套"制度"。**

## 破局者：superpowers（179k ⭐）

在解决这个问题的路上，有一个项目让我眼前一亮——[obra/superpowers](https://github.com/obra/superpowers)。

**基本信息：**
- 作者：**Jesse Vincent（obra）** / Prime Radiant
- ⭐ 179k 星 | 🍴 15.9k Forks | MIT License
- 最新版本：**v5.1.0（2026年5月4日）**，共 5 个 Release
- 主语言：Shell（66.4%），还有 JavaScript、Python、TypeScript

**它解决什么问题：**
Superpowers 是一套"AI agent 技能框架+软件开发方法论"。当 agent 启动时，它"不会直接跳进去写代码"——而是先退一步，通过对话细化需求。它定义了 7 个核心 skill 的串行流程：

`brainstorming → using-git-worktrees → writing-plans → subagent-driven-development → test-driven-development → requesting-code-review → finishing-a-development-branch`

**为什么它很牛：**
179k 星不是白给的。它是目前 Claude Code 生态中最有影响力的方法论项目。而且它不只是 Claude Code 专属——最新版已经支持 **Claude Code、Codex CLI、Codex App、Factory Droid、Gemini CLI、OpenCode、Cursor、GitHub Copilot CLI** 等多种 AI 编程工具。Prime Radiant 团队在做的事，基本上就是这个领域的方向标。

**但它没解决什么：**
Superpowers 定义了"流程应该长什么样"，但它不强制 agent 执行流程。也没有把代码知识图谱（gitnexus）和任务追踪（beads）整合进来。Agent 仍然会"跳步骤"——这不是 superpowers 的问题，而是它的设计边界。

## 拼图的另外两块：beads（23.2k ⭐）和 gitnexus（35.8k ⭐）

**[beads](https://github.com/gastownhall/beads)** — "A memory upgrade for your coding agent"

**基本信息：**
- 作者：gastownhall（团队）
- ⭐ 23.2k 星 | 🍴 1.5k Forks | MIT License
- 最新版本：**v1.0.3（2026年4月24日）**，共 89 个 Release
- 主语言：**Go（94.4%）**，还有 Python、Shell、JavaScript
- 安装方式：`npm install -g @beads/bd`、Homebrew、go install
- 支持平台：macOS、Linux、Windows、FreeBSD

**它解决什么问题：**
Beads 是一个"为 AI agent 设计的分布式图结构 issue tracker"，底层由 **Dolt**（一个支持 Git 式版本控制的 SQL 数据库）驱动。它不是 Jira，不是 GitHub Issues——它直接嵌入你的项目目录。AI agent 不需要打开浏览器去点看板，直接在终端里 `bd create`、`bd close`、`bd dep add`，所有数据就在 `.beads/` 目录下，自带版本历史和分布式同步。

关键特性包括：基于 hash 的 ID 防冲突、依赖图追踪、"记忆衰减"机制自动压缩旧 issue 节省上下文窗口、以及内置的消息系统。在 agent 工作流里，beads 是目前唯一一个**真正从 agent 视角设计的任务追踪系统**。

**有个数据很能说明问题：8713 次 commit。** 这个项目不是玩票，是在持续重度开发。

---

**[gitnexus](https://www.npmjs.com/package/gitnexus)** — "Zero-Server Code Intelligence Engine"

**基本信息：**
- 作者：**Abhigyan Patwari**
- ⭐ 35.8k 星 | 🍴 4.1k Forks | **PolyForm Noncommercial 1.0.0 License**
- 最新版本：**v1.6.3（2026年4月24日）**，共 163 个 Release
- 主语言：**TypeScript（98%）**
- 安装方式：`npm install -g gitnexus`
- 支持架构：CLI + MCP Server、Web UI

**它解决什么问题：**
Gitnexus 是一个"零服务器代码智能引擎"。你把代码库丢进去，它输出一个交互式知识图谱——捕获"每一个依赖、调用链、集群和执行流"。然后通过 **MCP（Model Context Protocol）** 暴露给 AI agent，支持 **16 个 MCP 工具**：query（混合搜索）、impact（爆炸半径分析）、context（符号 360 度视图）、detect_changes、rename、Cypher 查询等。

**技术栈很硬核：** Tree-sitter 做 AST 解析、LadybugDB 做图存储、Sigma.js 做 WebGL 可视化、transformers.js 做 embedding、BM25 + semantic + RRF 混合搜索。

**注意许可证：** 它是 **PolyForm Noncommercial**，不是 MIT——商业使用需要联系 akonlabs.com 的企业版。

---

**但问题在于：这三个项目各自解决了一个维度的问题，却彼此孤立。**

- Superpowers 定义了流程，但不执行流程
- Beads 追踪了任务，但不驱动流程
- Gitnexus 理解代码，但不参与流程

就像你有最好的厨师、最好的食材、最好的厨房，但没有一个"店长"来管理整个后厨的运转。

## 站在巨人肩膀上的 devflow

这就是 devflow 的由来。

我的想法很简单：**把这些工具串联起来，再加一道保险，让 AI 按流程走，想跳也跳不了。**

### 我"借用"了哪些巨人的肩膀

| 项目 | 作者 | ⭐ | 我的角色 |
|------|------|---|---------|
| [superpowers](https://github.com/obra/superpowers) | Jesse Vincent (obra) / Prime Radiant | **179k** | **流程骨架** — 14 个 skill 直接做管道定义 |
| [beads](https://github.com/gastownhall/beads) | gastownhall | **23.2k** | **任务追踪** — AI agent 原生的嵌入式 issue tracker |
| [gitnexus](https://www.npmjs.com/package/gitnexus) | Abhigyan Patwari | **35.8k** | **代码知识图谱** — Symbol 索引 + 调用链 + Graph RAG |
| [autoresearch](https://github.com/uditgoenka/autoresearch) | Udit Goenka | **4.3k** | **自动优化引擎** — Karpathy 自反馈迭代的 Claude 实现 |
| [mattpocock/skills](https://github.com/mattpocock/skills) | Matt Pocock | **60.2k** | **模式来源** — Grill 拷问、Git guardrails、ADR 模式 |

**每个名字都值得你关注：**

- **Jesse Vincent（obra）** — 179k 星的 repo 不需要介绍。他另一个知名项目是 **Prime**（键盘硬件）。能力范围横跨硬件和 AI 方法论，极少有人能在这两个领域都做出顶级项目

- **Matt Pocock** — TypeScript 社区无人不知。他在 TypeScript 类型体操方面的教程影响了整个前端生态。他的 skills 仓库只有 **63 个 commit、没有正式 release**，但拿了 **60.2k 星**——因为这个仓库是"工程师写给工程师"的风格，`/grill-me`、`/grill-with-docs`、`/tdd` 这些命令全是解决真实痛点的

- **Udit Goenka** — 连续创业者，自称"帮 700+ 创业公司产生了 ~2500 万美金收入"。他实现的 autoresearch 基于 **Andrej Karpathy** 的自反馈迭代思想（Modify → Verify → Keep/Discard → Repeat），把 ML 领域的方法论推广到了**任何领域**——代码、内容、营销、销售、HR、DevOps。目前 37 个 release，迭代非常快

- **Abhigyan Patwari** — 用 Tree-sitter + Graph RAG 做代码理解，**163 个 release** 说明这个项目在疯狂迭代。16 个 MCP 工具的覆盖面在同类项目里是最全的

**我做的事情就是把这些项目粘在一起。** 就像一个乐队指挥——我不写谱子，不演奏乐器，但我知道什么时候让谁进场。

## devflow：那个"指挥"

### 核心架构：5 阶段流水线

```
Phase 1    Ideate（创意梳理）    — 从模糊想法到结构化 PRD
Phase 2    Design（前端设计）    — PRD → 前端脚手架
Phase 3    Setup（项目初始化）   — 一键安装所有工具链
Phase 4    Develop（开发循环）   — 核心开发管道
Phase 5    Finish（会话收尾）    — 任务关闭 + 报告生成
```

Phase 4 是整个系统的核心。它的管道长这样——**每个箭头都是一个自动或人工关卡**：

```
① brainstorming（注入 beads + gitnexus + 领域词汇）
    │
    ①½ plan-grill（人工拷问设计盲点） ← **HITL 硬关卡**
    │
    ①¾ autoresearch:probe（8 个 AI 人格对抗辩论，找隐藏约束）
    │
    ② writing-plans（注入 beads 子任务 + gitnexus 影响分析）
    │
    ②½ autoresearch:scenario（12 维度边界案例生成）
    │
    ③ subagent-driven-development（TDD + 每任务零错误门）
    │
    code-review → ②¾ autoresearch:security → finish-branch
```

每一步都在往 AI agent 的上下文中注入不同工具的输出：

- **① brainstorming** → 先跑 `beads create --type=epic` 创建追踪任务，再跑 `gitnexus context <key-symbol>` 预取代码上下文
- **①½ plan-grill** → 读 `docs/CONTEXT.md` 校验术语，读 `docs/adr/` 检查架构兼容性，用 gitnexus 验证代码符号存在性
- **② writing-plans** → 跑 `gitnexus impact <symbol>` 分析变更爆炸半径，用 `scripts/prd-to-beads.sh` 自动将设计文档拆成 beads sub-issues
- **③ implementation** → 每完成一个任务，autoresearch:fix 自动跑测试修复直到零错误，才能 claim 下一个任务

### 4 层防御链：让 AI 无法"忘记"

这是我觉得最有意思的设计。一个 LLM 只有记忆，没有自觉——所以必须用系统级的机制来补这个缺陷。

我构建了 4 层防御：

**Layer 1 — CLAUDE.md 最高指示（提示词层）**
每次会话自动加载，告诉 agent："必须先读 .devflow/state，不能跳步骤，不能绕过 Phase 1 直接写代码。" 这是在系统提示词层面写的"宪法"，agent 无法忽略。

**Layer 2 — UserPromptSubmit Hook（消息层）**
用户每发一条消息，hook 自动注入当前状态：`⚙️ devflow: [Phase 4] [Step: impl] 功能: 用户注册`。就像每隔 5 分钟有人拍一下 agent 的肩膀说："别忘了你在做什么。"

**Layer 3 — PreToolUse Hook（执行层）**
AI 想写代码？先检查当前阶段。如果 Phase < 3 就试图编辑代码文件——**直接拦截**。这是物理层面的阻断，不是靠"提醒"。

**Layer 4 — 全局 SessionStart Hook（入口层）**
每个 Claude Code 会话启动时检测 `.devflow/state`。新项目自动提示初始化，从未接入 devflow 的项目自动创建全套配置。

```
Agent 的"遗忘"链：          devflow 的防御链：
─────────────────           ─────────────────
没有意识 → 只有记忆          CLAUDE.md = 系统提示（不能忽略）
记忆会丢失 → 跳步骤          UserPromptSubmit = 每步提醒（强制刷新）
                              PreToolUse = 写代码前拦截（物理阻断）
                              全局 Hook = 新项目入口（预防性）
```

这套设计的精妙之处在于：**单层防御可以被绕过，但 4 层同时失效的概率极低。**

Agent 没有自觉意识，但 4 层防御形成了一个**记忆闭环**——让 agent 永远不会"忘记"devflow 流程。

### 状态驱动执行

整个流程的核心是一个 JSON 文件：

```json
{"phase":4,"step":"impl","feature":"用户注册","updatedAt":"2026-05-05T00:00:00Z"}
```

`.devflow/state` 是单一事实来源。所有 hook、所有 agent 行为、所有阶段检查，都以这个文件为准。每完成一步，更新这个文件。

这不是什么新技术，就是最朴素的**状态机**——但在 AI agent 的场景下，它解决了最根本的问题：让无状态的 LLM 拥有持续的状态意识。

## 踩过的坑（说多了都是泪）

### Docker on Windows 的噩梦

Gitnexus 依赖 tree-sitter 原生模块做代码解析。在 Windows 上，Node 22 + tree-sitter = 必崩（SIGSEGV，段错误）。解决方案是用 Docker 运行 gitnexus，让 tree-sitter 在 Linux 容器里跑。

但 Docker on Windows 又有新坑：
- `.git` 是隐藏文件夹，Docker Desktop 默认**不挂载隐藏目录**
- 容器内非 root 用户**无法写入 Windows 卷挂载**

修复方案：`--user root` + `--skip-git`，并在 `setup.sh` 里自动检测 Docker 可用性，不可用时优雅跳过。

这让我深刻体会到：**跨平台兼容性不是在 Mac 上写好代码，然后期望 Windows 也能用。而是每个平台都要亲手踩一遍坑。**

### Permission 管理失控

开发过程中，`.claude/settings.json` 的 `allow` 数组不断膨胀——每跑一个命令就加一条权限。改了几次才找到正确做法：只用 settings.local.json 管理个人权限，settings.json 只放团队共享配置。

### Guardrails 把自己人也拦了

`git checkout --` 被 guardrails 拦截——但我自己开发时需要用它。最后只能手动编辑 settings.json 绕过。这挺讽刺的：你造了一个监狱，然后发现自己是第一个想越狱的人。

## 现在还存在的问题

说完了好听的，来点真实的。

**太重了。** 依赖链太长：

```
Claude Code → superpowers × 14 → beads (Go 二进制) → 
gitnexus (npm + Docker) → autoresearch → Docker Desktop
```

任何一个环节出问题都能卡住。理想状态是一条命令搞定：

```bash
npx devflow init
```

目前正在往这个方向重构。

**Phase 1 的增量价值有限。** 对于有经验的开发者，Claude 本身已经很擅长追问需求了。4 阶段自适应探索引擎带来的增量价值不大——真正受益的是完全不懂技术的人，但这些人又卡在前期的安装配置上。这是目前最大的悖论。

**生态锁定。** 尽管 superpowers 已经支持多平台，但 beads、autoresearch 仍然深度绑定 Claude Code。换到 Cursor 或 Copilot 有迁移成本。

尽管有这些问题，但我认为方向是对的：**AI agent 的能力会越来越强，但"让 agent 按规范执行"这个问题只会越来越重要。** 当 agent 能写 90% 的代码时，那 10% 的流程管控反而成为瓶颈。

## 一点思考

我经常想这个问题：如果 AI 最终能写出所有代码，那人类开发者还剩下什么价值？

Devflow 给了我一个可能的答案：**定义"怎么做"的能力。**

AI 擅长执行明确定义的任务。但"应该用什么流程"、"在什么节点需要人工确认"、"哪些操作不能自动化"——这些判断需要理解业务、理解风险、理解团队。这些是人类的领域。

所以 devflow 的定位不是一个"自动化所有东西"的工具，而是一个**让 AI 在人类定义的框架内工作的工具**。它把人类的判断（流程设计、关卡设置、安全策略）固化到系统中，然后放手让 AI 去执行。

就像 DevOps 不会取代运维工程师，而是重新定义了他们的工作——devflow 也在重新定义"AI 时代开发者"的角色：从写代码的人，变成**定义流程和标准的人**。

---

*项目地址：[github.com/TheonePro7/devflow](https://github.com/TheonePro7/devflow)*

*参考项目（数据截至 2026 年 5 月）：*
- *[obra/superpowers](https://github.com/obra/superpowers) — ⭐ 179k，Jesse Vincent / Prime Radiant 的 AI agent 技能框架，v5.1.0*
- *[gastownhall/beads](https://github.com/gastownhall/beads) — ⭐ 23.2k，AI agent 原生嵌入式分布式 issue tracker，v1.0.3*
- *[abhigyanpatwari/gitnexus](https://www.npmjs.com/package/gitnexus) — ⭐ 35.8k，零服务器代码知识图谱引擎，v1.6.3（PolyForm Noncommercial License）*
- *[uditgoenka/autoresearch](https://github.com/uditgoenka/autoresearch) — ⭐ 4.3k，Karpathy 自反馈迭代的 Claude 实现，v2.0.03*
- *[mattpocock/skills](https://github.com/mattpocock/skills) — ⭐ 60.2k，Matt Pocock 的工程师向 AI 技能集合*

*如果你也在用 Claude Code 做开发，欢迎交流。有任何建议直接留言。*
