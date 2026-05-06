# Beads (bd) — 深度研究分析报告

> 项目：gastownhall/beads — "为你的编程智能体提供内存升级"
> 语言：Go（CLI），附带 MCP 服务器（Python）、npm 包
> 许可证：MIT
> Star 数：~23k
> 存储：Dolt（嵌入式或服务器模式 — 支持 Git 版本控制的 SQL 数据库）
> 文档：https://gastownhall.github.io/beads/

---

## 1. 完整 CLI 命令列表（含所有标志和参数）

### 核心生命周期命令

#### `bd init`
在项目中初始化 beads。创建包含 Dolt 数据库的 `.beads/` 目录。
```
标志：
  --server              使用外部 Dolt SQL 服务器（默认使用嵌入式）
  --stealth             不将 beads 文件提交到主仓库（个人使用）
  --contributor         将规划问题路由到独立仓库（~/.beads-planning）
  --skip-agents         不创建/更新 AGENTS.md
  --reinit-local        重新初始化本地数据库（丢弃仅本地数据）
  --discard-remote      丢弃远程数据库引用
  --team <name>         为团队设置
  --team-name, --team-remote 等
```

#### `bd create "<title>"`
创建新问题/任务。
```
标志：
  -p, --priority <0-4>            优先级（0=最高，默认值因情况而异）
  -a, --assignee <name>           负责人
  -d, --description <text>        问题描述
  --body <text>                   --description 的别名（遵循 GH CLI 惯例，隐藏）
  -m, --message <text>            --description 的别名（遵循 git 提交惯例，隐藏）
  --body-file <path>              从文件读取描述（使用 - 表示标准输入）
  --description-file <path>       --body-file 的别名（隐藏）
  --stdin                         从标准输入读取描述（--body-file - 的别名）
  --design <text>                 设计说明
  --design-file <path>            从文件读取设计（使用 - 表示标准输入）
  --acceptance <text>             验收标准
  --notes <text>                  附加说明
  --external-ref <ref>            外部引用（例如 'gh-9', 'jira-ABC'）
  --type <type>                   问题类型（bug, task, feature, epic, chore, story）
  -t, --template <name>           使用模板定义问题结构
  -l, --label <label>             添加标签
  --parent <id>                   父问题 ID
  -L, --link <id>                 链接到相关问题
  --dry-run                       预览但不创建
  -f, --file <path>               从 markdown 文件批量创建
  --graph <file>                  从图 JSON 批量创建
  --repo <name>                   覆盖路由数据库
  --waits-for-gate <name>         在关卡上阻塞
  --waits-for <id>                在另一个问题上阻塞
  --json                          JSON 输出
  --skills <text>                 所需技能说明
  --context <text>                上下文说明
  --due <time>                    截止日期（解析为相对时间）
  --defer <time>                  推迟到某个日期
  --estimate <minutes>            预估分钟数
  --spec-id <id>                  规范 ID
```

#### `bd show <id>`
显示问题详情。
```
标志：
  --short          简要格式
  --long           完整详情
  --json           JSON 输出
  --thread         显示消息线程
  --children       显示子问题
  --refs           显示引用
  --watch          监视模式（每 2 秒轮询一次）
  --current        显示当前活动问题
  --as-of <commit> 显示某个特定 Dolt 提交时的状态
  --local-time     以本地时区显示时间
  --id             显示解析后的内部 ID
```

#### `bd update <id> [flags]`
更新问题（未提供 ID 时自动选择最后修改的那个）。
```
标志：
  --status <status>               设置状态（open, in_progress, blocked, deferred, closed 以及自定义）
  -p, --priority <0-4>           设置优先级
  --title <text>                  修改标题
  -a, --assignee <name>           设置负责人（空值取消分配）
  -d, --description <text>        更新描述
  --design <text>                 更新设计说明
  --notes <text>                  替换备注
  --append-notes <text>           追加备注（使用换行符分隔）
  --acceptance <text>             更新验收标准
  --acceptance-criteria <text>    --acceptance 的别名
  --external-ref <ref>            设置外部引用
  --spec-id <id>                  设置规范 ID
  --estimate <minutes>            设置预估时间
  --type <type>                   更改问题类型
  --add-label <label>             添加标签
  --remove-label <label>          移除标签
  --set-labels <l1,l2,...>        替换所有标签
  --parent <id>                   重新设置父级
  --await-id <id>                 设置等待 ID
  --due <time>                    设置截止日期（空值清除）
  --defer <time>                  设置推迟日期（空值清除，自动设置状态为 deferred）
  --ephemeral / --persistent      切换临时状态（互斥）
  --no-history / --history        切换历史跟踪（互斥）
  --branch / --no-branch          关联/取消关联分支
  --json                          JSON 输出
```

#### `bd close <id...> [reason]`
关闭问题。别名：`bd done`。
```
标志：
  --reason <text>               关闭原因
  --resolution <text>           解决方案描述
  --message <text>              关闭消息
  --comment <text>              关闭时添加评论
  --reason-file <path>          从文件读取关闭原因（使用 - 表示标准输入）
  --suggest-next                建议后续步骤
  --continue                    推进到 molecule 中的下一步
  --claim-next                  自动认领最高优先级的就绪问题
  --force                       即使有阻塞也强制关闭
  --json                        JSON 输出
```
如果未提供 ID，则使用最后处理的问题。

#### `bd reopen <id...>`
重新打开已关闭的问题。
```
标志：
  -r, --reason <text>   重新打开的原因
  --json
```

#### `bd delete <id>`
删除问题。

### 列表与搜索

#### `bd list`
列出问题并支持筛选。
```
标志：
  -s, --status <status>         按状态筛选（open, closed, in_progress 等）
  -t, --type <type>             按问题类型筛选
  -p, --priority <n>            按优先级筛选
  -a, --assignee <name>         按负责人筛选
  -l, --label <label>           按标签筛选
  --label-mode <mode>           标签匹配模式：any, all, none
  --parent <id>                 按父问题筛选
  --exclude-parent <id>         排除父问题的子问题
  --tree                        以树形显示
  --long                        详细格式
  --json                        JSON 输出
  --csv                         CSV 输出
  --compact                     紧凑视图
  --limit <n>                   限制结果数量
  --offset <n>                  分页偏移
  --sort <field>                排序字段（created, updated, priority, title）
  --reverse                     反转排序顺序
  --created-after <time>
  --created-before <time>
  --updated-after <time>
  --updated-before <time>
  --closed-after <time>
  --closed-before <time>
  --no-assignee                 未分配的问题
  --no-labels                   无标签的问题
  --empty-description           无描述的问题
  --metadata-field <k=v>        按元数据 key=value 筛选
  --has-metadata-key <key>      包含特定元数据 key 的问题
```

#### `bd ready`
列出所有已解除阻塞（就绪）的问题。
```
标志：
  --claim                    原子性地认领第一个就绪问题
  --gated                    查找有关卡刚刚关闭的 molecule
  --mol <id>                 显示特定 molecule 内的就绪步骤
  --explain                  基于依赖关系的推理，说明为何某些项未就绪
  --include-deferred         包含已推迟的问题
  --include-ephemeral        包含临时问题
  --metadata-field <k=v>     按元数据筛选
  --has-metadata-key <key>   包含元数据 key
  --json                     JSON 输出
```

#### `bd blocked`
显示被阻塞的问题。

#### `bd stale`
显示陈旧问题（长时间未更新）。
```
标志：
  -d, --days <n>     最近 N 天内未更新的问题（默认：30）
  -s, --status <s>   按状态筛选（open|in_progress|blocked|deferred）
  -n, --limit <n>    最大结果数（默认：50）
  --json
```

#### `bd count`
统计符合筛选条件的问题数量。

### 分配与标签

#### `bd assign <id> <name>`
分配/取消分配问题（`bd update --assignee` 的快捷方式）。

#### `bd tag <id> <label>`
为问题添加标签（`bd update --add-label` 的快捷方式）。

#### `bd label`
标签管理。
```
子命令：
  label add <id...> <label>         为一个或多个问题添加标签
  label remove <id...> <label>      从一个或多个问题移除标签
  label list <id>                   列出问题的标签
  label list-all                    列出所有唯一标签及其计数
  label propagate <parent-id> <label>  将标签传播到子问题
```

### 依赖关系

#### `bd dep`
依赖关系管理。
```
子命令：
  dep add <child> <parent>       添加阻塞依赖关系
  dep remove <child> <parent>    移除依赖关系
  dep list <id>                  列出问题的依赖关系
  dep check                      检查是否存在依赖循环
  dep batch <file>               从 JSONL 文件批量添加依赖
dep add 的标志：
  --blocks         创建反向依赖关系（子问题阻塞父问题）
  -f, --file       从 JSONL 批量导入
```

#### `bd link <id1> <id2>`
在两个问题之间建立关联链接。

#### `bd relate <id1> <relationship> <id2>`
高级关系类型：relates_to, duplicates, supersedes, parent, blocks。

### Molecules 与 Formulas（工作流模板）

#### `bd mol`
Molecule 命令 — 智能体工作流的工作模板。
```
子命令：
  mol show <id>                  显示 proto/molecule 结构
  mol pour <id> [--var k=v]      将 proto 实例化为持久化 molecule（liquid 阶段）
  mol wisp <id> [--var k=v]      将 proto 实例化为临时 wisp（vapor 阶段）
  mol bond <id1> <id2>           组合 proto/molecule
  mol squash <id>                将 molecule 压缩为 digest
  mol burn <id>                  丢弃 wisp
  mol distill <id>               从 ad-hoc epic 中提取 proto
  mol seed                       从默认模板种子化启动 molecule
  mol current                    显示当前活跃的 molecule
  mol progress <id>              显示 molecule 进度
  mol last-activity              显示最近一次 molecule 活动
  mol stale                      显示陈旧的 molecule
  mol ready-gated                显示有关卡就绪的 molecule
全局标志：
  --var key=value                为模板替换定义变量
```

#### `bd pour <id> [--var k=v]`
`bd mol pour` 的别名 — 将 proto（模板）实例化为真实问题。

#### `bd formula`
Formula 管理（molecule 模板的源定义）。
```
子命令：
  formula list                    列出可用的 formula
  formula show <name>             显示 formula 详情
标志：
  --type <type>                   按类型筛选（workflow, expansion, aspect, convoy）
  --json                          JSON 输出
```

### 评论与讨论

#### `bd comment <id> [text...]`
添加评论。
```
标志：
  --stdin            从标准输入读取
  --file <path>      从文件读取
```

#### `bd comments <id>`
列出问题的评论。
```
标志：
  --json
```

#### `bd comments add <id> <text>`
添加评论（长格式）。

#### `bd thread <id>`
显示线程化对话视图。

### 关卡（异步协调）

#### `bd gate`
关卡管理，用于异步协调。
```
子命令：
  gate list                        列出关卡（默认显示开放的）
  gate create <name> [--blocks <id>]  创建临时关卡
  gate add-waiter <gate> <agent>   注册智能体以接收唤醒通知
  gate resolve <gate>              手动关闭关卡
  gate check                       评估所有开放的关卡
  gate discover <name>             从问题标题自动发现关卡
标志：
  --all                            同时显示已关闭的关卡
```

#### `bd ship <capability>`
发布能力，用于跨项目依赖。
```
标志：
  --force           即使问题未关闭也发布
  --dry-run         仅预览
```

### 记忆系统（智能体持久化）

#### `bd remember "<insight>"`
存储持久化记忆（每次会话由 `bd prime` 注入）。
```
标志：
  --key <key>       显式键名（未设置时根据内容自动生成）
```

#### `bd memories [search]`
列出或搜索记忆。

#### `bd recall <key>`
根据键名检索特定记忆。

#### `bd forget <key>`
移除一条记忆。

### 配置

#### `bd config`
配置管理。
```
子命令：
  config set <key> <value>         设置配置值
  config get <key>                 获取配置值
  config list                      列出所有配置
  config unset <key>               取消设置配置值
  config show                      显示生效的配置
  config apply <file>              从文件应用配置
  config drift                     检测配置漂移
标志：
  --json
  --force-git-tracked              强制将敏感键保存到 git 中（危险）
```

#### `bd statuses`
列出有效的问题状态（内置 + 自定义）。
```
标志：
  --json
```

### 备份与导出

#### `bd export [-o file]`
将问题导出为 JSONL 格式。
```
标志：
  -o, --output <file>      输出文件（省略时输出到标准输出）
  --all                    包含所有内容（基础设施、模板、关卡、记忆）
  --include-infra          包含 agent、rig、role、message
  --scrub                  排除测试/污染记录
  --include-memories       包含 bd remember 数据
```

#### `bd import <file>`
从 JSONL 导入问题。

#### `bd backup`
备份管理。
```
子命令：
  backup init <path>               设置备份目标
  backup sync                      推送备份
  backup restore --force <path>    从备份恢复
```

### 版本控制（Dolt）

#### `bd dolt`
Dolt 数据库命令。
```
子命令：
  dolt show                        显示 Dolt 配置和连接状态
  dolt set <key> <value>           设置 Dolt 配置（database, host, port, user, data-dir）
  dolt test                        测试 Dolt 服务器连接
  dolt push [remote]               推送提交到远程
  dolt pull [remote]               从远程拉取
  dolt remote add/list/remove      管理远程仓库
  dolt commit                      提交数据库更改
  dolt start                       启动 Dolt 服务器
  dolt stop                        停止 Dolt 服务器
  dolt status                      显示 Dolt 状态
```

### 管理与维护

#### `bd admin <subcommand>`
高级数据库维护。
```
子命令：
  admin cleanup        删除已关闭的问题（生命周期管理）
  admin compact        压缩旧的已关闭问题以节省空间
  admin reset          移除所有 beads 数据和配置
```

#### `bd compact`
压缩 — 对旧关闭任务进行语义化的"记忆衰退"。
```
标志（互斥模式）：
  --analyze            导出候选对象供智能体/人工审查
  --apply              接受预先编写的摘要
  --auto               通过 API 进行 AI 驱动的压缩
  --dolt               运行 Dolt 垃圾回收
其他标志：
  --id <id>            压缩特定问题
  --all                压缩所有符合条件的问题
  --dry-run            仅预览
  --force              强制（需要 --id）
  --stats              显示压缩统计信息
  --json               JSON 输出
```

#### `bd doctor`
健康诊断与修复。
```
子命令：
  doctor               运行所有检查
  doctor --fix         自动修复问题
  doctor validate      验证数据库完整性
  doctor health        健康检查
  doctor agent         智能体诊断
  doctor conventions   检查项目规范
  doctor artifacts     检查制品
  doctor repair        修复数据库
  doctor pollution     检查污染
```

#### `bd lint [issue-id...]`
检查问题是否缺少基于类型的模板章节。
```
标志：
  -t, --type <type>    按问题类型筛选
  -s, --status <s>     按状态筛选（默认：open，'all' 表示所有）
```

#### `bd preflight`
PR 就绪检查清单。
```
标志：
  --check              实际运行检查（而非静态清单）
  --skip-lint          跳过 golangci-lint 检查
  --fix                自动修复占位符
  --json               JSON 输出
```
8 项检查：测试通过、lint 通过、代码格式化、beads 污染、Nix hash、版本同步、AGENTS.md/CLAUDE.md 差异、flake 新鲜度。

#### `bd gc`
垃圾回收。

#### `bd prune`
清理旧数据。

#### `bd purge`
永久删除已清除的问题。

### 质量与分析

#### `bd graph [issue-id]`
依赖关系图可视化。
```
标志：
  --box             带层次分组的 ASCII 框
  --compact         每个问题单行的树形显示
  --dot             Graphviz DOT 格式
  --html            自包含的 D3.js 交互式 HTML
  --all             所有开放问题（按组件分组）
```
子命令：`bd graph check` — 检测依赖循环（退出码 0=无问题，1=存在问题）

#### `bd orphans`
查找孤立问题（没有父级、没有依赖关系）。

#### `bd duplicates`
查找重复问题。

#### `bd find-duplicates`
高级重复检测。

#### `bd critical-paths`
查找关键依赖路径。

#### `bd diff`
显示 Dolt 提交之间的差异。

#### `bd history <id>`
显示问题审计轨迹/变更历史。

#### `bd audit <id>`
显示问题的审计轨迹。

#### `bd status`（别名：`stats`）
显示问题数据库概览和统计信息。
```
标志：
  --all             显示所有（默认行为）
  --assigned        显示分配给当前用户的问题
  --no-activity     跳过 git 活动跟踪
  --json
```

### 版本控制与同步

#### `bd sync`
与远程 Dolt 数据库同步。

#### `bd vc commit`
版本控制提交。

#### `bd branch`
分支管理。

#### `bd merge-slot`
管理合并槽位。

### 智能体与设置

#### `bd prime`
打印智能体工作流上下文和持久化记忆（用于 SessionStart/PreCompact 钩子）。
```
标志：
  --full              强制输出完整 CLI 内容（忽略 MCP 检测）
  --stealth           会话关闭时不执行 git 命令
  --memories-only     仅持久化记忆（用于 compact 钩子）
  --mcp               MCP 模式（简短输出，约 50 个 token）
```

#### `bd setup <agent-type>`
安装 bead 智能体集成。
```
智能体类型：codex, claude, factory, mux, cursor, aider, cline, windsurf, roo, gui, openai, genaiscript, continue.dev, github-copilot
```

#### `bd onboard`
打印用于手动智能体设置的上手指南。

#### `bd bootstrap`
引导新的 beads 工作区。

#### `bd quickstart`
快速启动向导。

#### `bd edit [id]`
在 $EDITOR 中编辑问题字段。
```
标志：
  --title           编辑标题
  --description     编辑描述（默认）
  --design          编辑设计说明
  --notes           编辑备注
  --acceptance      编辑验收标准
```

#### `bd batch <file>`
从文件批量操作。

### 子问题与层级

#### `bd children <id>`
列出子问题（`bd list --parent <id> --status all` 的别名）。

#### `bd epic`
Epic 管理。
```
子命令：
  epic status [--eligible-only]           显示 epic 完成状态
  epic close-eligible [--dry-run]          关闭已完成的 epic
```

#### `bd promote <id>`
提升问题（向上更改类型）。

#### `bd flatten <id>`
展平层级结构。

### 临时工作与消息

#### `bd wisp <id>`
生成临时工作（vapor 阶段）。

#### `bd burn <id>`
丢弃临时工作。

#### `bd mail <id>`
发送消息类型（通过 --thread 支持线程化、临时生命周期、邮件委托）。

#### `bd note <id>`
快速给问题添加备注。

### 联合与跨项目

#### `bd federation`
跨项目依赖的联合管理。

#### `bd routed`
显示路由配置。

#### `bd context`
上下文管理。
```
子命令：
  context bind           绑定上下文
  context show           显示上下文
```

### 实用工具

#### `bd help`
帮助系统。
```
子命令：
  help --all              生成完整的 markdown 参考文档
  help --doc <command>    生成带有 Docusaurus 前置元数据的单命令文档
  help --list             列出所有可用命令
```

#### `bd completions [shell]`
生成 shell 补全。

#### `bd tips`
显示技巧。

#### `bd kv`
键值存储（底层）。
```
子命令：
  kv set <key> <value>     设置键
  kv get <key>             获取值
  kv clear <key>           删除键
  kv list                  列出所有键
```

#### `bd template`
模板管理。

#### `bd sql`
运行直接 SQL 查询。

#### `bd cook`
运行配方（formula 执行）。

#### `bd ping`
健康检查。

#### `bd info`
显示 beads 信息。

#### `bd version`
显示版本。

#### `bd migrate`
迁移数据库 schema。

#### `bd undelete`
恢复已删除的问题。

---

## 2. 问题数据模型（所有字段和类型）

`Issue` 结构体（来自 `internal/types/types.go`）包含约 60 多个字段，按逻辑分组如下：

### 标识
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `ID` | `string` | 基于哈希的 ID（例如 `bd-a1b2`） |
| `Number` | `int` | 人类可读的顺序编号 |
| `Title` | `string` | 问题标题 |
| `Slug` | `string` | URL 友好的 slug |

### 内容
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `Description` | `string` | 主要描述/正文 |
| `Design` | `string` | 设计说明 |
| `AcceptanceCriteria` | `string` | 验收标准 |
| `Notes` | `string` | 附加说明 |
| `SpecID` | `string` | 规范 ID（链接到外部规范） |

### 状态与工作流
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `Status` | `Status` | 枚举：open, in_progress, blocked, deferred, closed, pinned, hooked |
| `Priority` | `string` | P0-P4 或 0-4（P0=最高） |
| `IssueType` | `IssueType` | 枚举：bug, task, feature, epic, chore, story, message, spike, tech_debt, sub_epic, gate, rig, aspect, role, agent |
| `Pinned` | `bool` | 问题是否被置顶 |
| `IsTemplate` | `bool` | 问题是否为模板 |
| `IsEphemeral` | `bool` | 临时生命周期（关闭时自动删除） |

### 分配
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `Assignee` | `string` | 当前负责人 |
| `Owner` | `string` | 所有者（可能与负责人不同） |
| `CreatedBy` | `string` | 创建者 |

### 时间戳
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `CreatedAt` | `time.Time` | 创建时间戳 |
| `UpdatedAt` | `time.Time` | 最后更新时间戳 |
| `ClosedAt` | `*time.Time` | 关闭时间戳 |
| `DueAt` | `*time.Time` | 截止日期 |

### 调度
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `DeferUntil` | `*time.Time` | 推迟到某个日期 |
| `EstimatedMinutes` | `int` | 预估时间（分钟） |
| `LeadTime` | `float64` | 前置时间（小时） |

### 外部集成
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `ExternalRef` | `*string` | 外部引用（例如 `gh-9`、`jira-ABC`、Linear URL） |
| `SourceSystem` | `string` | 来源系统名称 |

### 自定义元数据
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `Metadata` | `json.RawMessage` | 任意 JSON 元数据（经过 schema 验证） |

### 压缩
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `Compacted` | `bool` | 该问题是否已被压缩 |
| `CompactedSummary` | `string` | AI 生成的压缩摘要 |
| `CompactedAt` | `*time.Time` | 压缩发生时间 |
| `CompactionTier` | `int` | 压缩层级（1=约 70% 缩减，2=约 95% 缩减） |

### 路由
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `PrefixRoute` | `string` | 路由前缀（例如 "xe-"） |
| `DBName` | `string` | 目标数据库名称 |

### 关系数据
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `ParentID` | `string` | 父问题 ID |
| `Dependencies` | `[]string` | 该问题依赖的 ID 列表 |
| `Dependents` | `[]string` | 依赖该问题的 ID 列表 |
| `RelatedIDs` | `[]string` | 相关问题的 ID 列表 |
| `DuplicateIDs` | `[]string` | 重复问题的 ID 列表 |
| `SupersedeIDs` | `[]string` | 被替代问题的 ID 列表 |
| `Labels` | `[]string` | 标签 |

### 消息
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `ThreadID` | `string` | 消息线程 ID |
| `MailDelegation` | `string` | 邮件委托目标 |

### 上下文标记
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `ContextMarkers` | `[]string` | 智能体的上下文标记 |
| `Waiters` | `[]string` | 等待解决的智能体 |

### 结合（Molecule 化合物）
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `BondedFrom` | `[]BondRef` | 该问题结合自哪些来源 |
| `BondType` | `string` | 结合类型 |

### 关卡
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `GateName` | `string` | 关卡名称 |
| `GateBlocking` | `[]string` | 该关卡阻塞的问题 |

### 来源追踪
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `SourceProtoID` | `string` | 来源 proto/模板 ID |
| `SpawnedFrom` | `string` | 生成来源 |

### Molecule 类型
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `MolType` | `MolType` | 枚举：none, proto, molecule, compound, digest |

### 工作类型
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `WorkType` | `WorkType` | 枚举：step, gate, parallel, decision, approval |

### 事件（用于消息类问题）
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `EventKind` | `string` | 事件类型 |
| `Actor` | `string` | 事件执行者 |
| `Target` | `string` | 事件目标 |
| `Payload` | `string` | 事件负载 |
| `Timeout` | `time.Duration` | 事件超时 |
| `AwaitType` | `string` | 等待类型 |
| `AwaitID` | `string` | 等待目标 ID |

### 统计信息（独立于 Issue 结构体）
| 字段 | 类型 | 描述 |
|-------|------|-------------|
| `TotalIssues` | `int` | 问题总数 |
| `OpenIssues` | `int` | 开放问题数 |
| `InProgressIssues` | `int` | 进行中问题数 |
| `BlockedIssues` | `int` | 被阻塞问题数 |
| `DeferredIssues` | `int` | 已推迟问题数 |
| `ClosedIssues` | `int` | 已关闭问题数 |
| `ReadyIssues` | `int` | 就绪可工作的问题数 |
| `PinnedIssues` | `int` | 置顶问题数 |
| `EpicsEligibleForClosure` | `int` | 可关闭的 epic 数 |
| `AverageLeadTime` | `float64` | 平均前置时间（小时） |

### 状态常量
```
StatusOpen        = "open"
StatusInProgress  = "in_progress"
StatusBlocked     = "blocked"
StatusDeferred    = "deferred"
StatusClosed      = "closed"
StatusPinned      = "pinned"
StatusHooked      = "hooked"
```

### 状态分类
```
CategoryActive  = "active"   — 出现在 'bd ready' 和默认 'bd list' 中
CategoryWIP     = "wip"      — 从 'bd ready' 中排除，在默认 'bd list' 中可见
CategoryDone    = "done"     — 从两者中排除
CategoryFrozen  = "frozen"   — 从两者中排除
```

### 问题类型常量
```
TypeBug, TypeTask, TypeFeature, TypeEpic, TypeChore,
TypeStory, TypeSpike, TypeTechDebt, TypeSubEpic,
TypeGate, TypeRig, TypeAspect, TypeRole, TypeAgent,
TypeMessage, TypeStory
```

---

## 3. 依赖关系的工作原理

### 添加依赖
```bash
bd dep add <child> <parent>      # 子问题依赖父问题（父问题阻塞子问题）
bd dep add <child> <parent> --blocks   # 反向：子问题阻塞父问题
bd dep add -f deps.jsonl          # 从 JSONL 文件批量添加
```

### 依赖语义
- **阻塞关系**：默认关系。父问题必须关闭后子问题才算"就绪"。
- **关联关系**：通过 `bd link <id1> <id2>` 或 `bd relate <id1> relates_to <id2>` 创建。
- **重复关系**：`bd relate <id1> duplicates <id2>`。
- **替代关系**：`bd relate <id1> supersedes <id2>`。
- **父子关系**：层级关系（epic -> task -> sub-task）。

### 依赖检查
- `bd dep check` — 检测依赖图中的循环。
- `bd ready` — 仅列出没有开放阻塞的问题。
- `bd graph check` — 验证图的完整性（循环检测）。
- `bd blocked` — 显示所有被阻塞的问题。

### 通过路由进行依赖解析
- `resolveIDWithRouting()` 支持跨存储解析（例如 `xe-5ls` 引用不同 rig/数据库中的问题）。
- `isChildOf()` 检查问题 ID 之间的父子关系。

### 跨项目依赖
```bash
# 在消费项目中：
bd dep add <issue> external:<project>:<capability>

# 在提供项目中（必须先发布）：
bd ship <capability>
```
`ship` 命令会查找带有 `export:<capability>` 标签的问题，验证其已关闭，然后添加 `provides:<capability>` 标签。

---

## 4. Beads 如何与 Git/Dolt 集成

### 两种存储模式

#### 嵌入式模式（默认）
- Dolt 在进程中运行（无需外部服务器）。
- 数据存储在 `.beads/embeddeddolt/` 中。
- 仅单写入者（强制文件锁定）。

#### 服务器模式（`--server` 标志）
- 连接到外部 `dolt sql-server`。
- 数据存储在 `.beads/dolt/` 中。
- 支持多个并发写入者。
- 可通过标志或环境变量配置：
  - `--server-host` / `BEADS_DOLT_SERVER_HOST`（默认：`127.0.0.1`）
  - `--server-port` / `BEADS_DOLT_SERVER_PORT`（默认：`3307`）
  - `--server-socket` / `BEADS_DOLT_SERVER_SOCKET`（Unix 套接字）
  - `--server-user` / `BEADS_DOLT_SERVER_USER`（默认：`root`）
  - `BEADS_DOLT_PASSWORD`
  - `BEADS_DOLT_CLI_DIR` — 本地 Dolt 数据库路径，用于 CLI push/pull

### Beads 中的 Dolt 命令
```bash
bd dolt show        # 显示 Dolt 配置和连接状态
bd dolt set <k> <v> # 设置配置键（database, host, port, user, data-dir）
bd dolt test        # Ping 已配置的 Dolt 服务器
bd dolt push        # 推送提交到远程
bd dolt pull        # 从远程拉取
bd dolt remote add/list/remove   # 管理远程仓库
bd dolt commit      # 提交数据库更改
bd dolt start/stop  # 服务器生命周期管理
bd dolt status      # 显示 Dolt 状态
```

### 自动提交策略
- `commandDidWrite` — 原子布尔值，跟踪是否有任何命令写入了数据库。
- `commandDidExplicitDoltCommit` — 防止重复提交。
- `commandDidWriteTipMetadata` — 元数据写入的独立跟踪。
- 默认情况下，变更命令会自动提交。

### Git 集成
- 管理的 Git 钩子：pre-commit, post-merge, pre-push, post-checkout, prepare-commit-msg。
- 基于章节的钩子注入（`BEGIN BEADS INTEGRATION` / `END BEADS INTEGRATION` 标记）。
- 标记之外的用户自定义内容会被保留。
- `bd init` 自动设置钩子。
- 自动检测 git 钩子框架（pre-commit, Husky, lefthook, Overcommit）。
- `bd sync` 使用 Dolt 远程仓库进行 push/pull。
- Git 保护措施阻止 12 种危险模式。

### 工作区与 Worktree 支持
- `FindBeadsDir()` 解析符号链接、worktree 和 `BEADS_DIR` 覆盖。
- 通过工作区重定向支持多工作区。

---

## 5. 钩子系统

### Git 钩子（受管理）
通过章节注入管理的五个钩子：
- `pre-commit`
- `post-merge`
- `pre-push`
- `post-checkout`
- `prepare-commit-msg`

每个钩子脚本：
1. 检查 `bd` 是否在 `PATH` 中。
2. 设置可配置的超时时间（默认 300s，环境变量 `BEADS_HOOK_TIMEOUT`）。
3. 运行 `bd hooks run <hookname> "$@"`。
4. 优雅处理退出码 3（未初始化的数据库）— 记录警告，以 0 退出。
5. 同样处理超时（退出码 124）。

### Claude 钩子（settings.json）
在 `.claude/settings.json` 中注册：
- `SessionStart` — 运行 `bd prime` 注入工作流上下文。
- `PreToolUse` — 对危险 git 命令的保护措施。
- `PreCompact` — 运行 `bd prime --memories-only` 以保留上下文。

### 钩子运行器（`bd hooks run <hookname>`）
- 从数据库加载已注册的钩子。
- 支持插件（从 `.beads/plugins/` 加载）。
- Windows 兼容性（当 `os.TempDir()` 包含 `\` 时使用 `cmd /c`）。
- 退出码传播（保留非零退出码以阻止 git 操作）。
- 日志记录到 `bd-hooks.log`。

### Prime 系统（`bd prime`）
输出智能体优化的工作流上下文（markdown 格式）：
- **CLI 模式**（约 1-2k token）：完整命令参考。
- **MCP 模式**（约 50 token）：简短的工作流提醒。
- **Stealth 模式**：会话关闭协议中不含 git 命令。
- **Memories-only**：仅持久化记忆，用于 compact 钩子。

自定义优先级：
1. `.beads/PRIME.md`（特定克隆的本地覆盖）
2. `<beadsDir>/PRIME.md`（通过重定向的工作区覆盖）
3. `~/.config/beads/PRIME.md`（用户级别的全局覆盖）
4. 内置默认的 `outputPrimeContextWithOptions()`

MCP 自动检测会读取 `~/.claude/settings.json`，查找 `mcpServers` 下包含 `"beads"` 的任何键。

---

## 6. 查询/筛选功能

### 列表筛选器
- `--status` — 按状态筛选（open, closed, in_progress, blocked, deferred, 自定义）。
- `--type` — 按问题类型筛选（bug, task, feature, epic, chore, story 等）。
- `--priority` — 按优先级筛选/排序。
- `--assignee` — 按负责人筛选。
- `--label` / `--label-mode` — 标签筛选（any, all, none）。
- `--parent` / `--exclude-parent` — 基于父级的筛选。
- `--created-after/before`、`--updated-after/before`、`--closed-after/before` — 日期范围。
- `--priority-min`、`--priority-max` — 优先级范围。
- `--desc-contains`、`--notes-contains`、`--external-contains` — 模式匹配。
- `--empty-description`、`--no-assignee`、`--no-labels` — 缺失检查。
- `--metadata-field <k=v>`、`--has-metadata-key <key>` — 元数据筛选。
- `--limit`、`--offset` — 分页。
- `--sort` — 排序字段（created, updated, priority, title）。
- `--reverse` — 反转排序顺序。
- `--all` — 包含所有状态。

### 搜索
- 跨标题的全文搜索。
- ID 类查询（`bd-123`）使用快速精确/前缀匹配。
- 与列表相同的筛选标志。
- 默认排除已关闭的问题。

### 查询语言（`bd query`）
- 基于文本的查询语法，支持谓词筛选。
- 支持 OR 查询、基于标签的条件、显式状态筛选。
- 排序、限制以及 JSON/格式化输出。

### 就绪筛选器
- `bd ready` 自动筛选出没有开放阻塞的问题。
- `--claim` 自动认领第一个就绪的问题。
- `--gated` 查找有关卡刚刚关闭的 molecule。
- `--explain` 提供基于依赖关系的推理说明。
- `--include-deferred` / `--include-ephemeral` 用于边缘情况。

---

## 7. 验证功能

### 问题验证
- `validation.LintIssue()` 按类型检查是否缺少模板章节：
  - bug：复现步骤、验收标准
  - task：验收标准
  - feature：验收标准
  - epic：成功标准
  - chore：（无，始终通过）
- 优先级验证：P0-P4 或 0-4。
- 状态验证：自定义状态对照 `status.custom` 配置进行验证。
- 标题空值检查。

### 配置验证
- 键名验证拒绝受保护的仅初始化键。
- 未识别的键会收到警告并附带建议。
- Git 安全检查防止 API 密钥/令牌泄露。
- `status.custom` 值在写入前进行解析和验证。

### 关卡验证
- 关闭前检查关卡是否满足条件。
- 开放阻塞验证。
- Epic 子问题完成度验证。

### 数据库验证
- `bd doctor validate` — 数据库完整性验证。
- `bd doctor health` — 健康检查。
- `bd doctor repair` — 修复常见问题。
- `bd doctor pollution` — 检查污染/测试记录。

### Preflight 检查（8 项）
1. 测试通过（`go test -short ./...`）
2. Lint 通过（`golangci-lint run`）
3. 代码格式化（`gofmt -l .`）
4. Beads 污染（`.beads/issues.jsonl` 未被意外修改）
5. Nix hash 新鲜度
6. `version.go` 和 `default.nix` 之间的版本同步
7. AGENTS.md/CLAUDE.md 差异检测
8. Nix flake 锁文件新鲜度

### 关闭验证
- `--reason` / `--resolution` / `--message` / `--comment` 验证。
- 可配置的 `validation.on-close` 模式（error/warn）。
- 关闭前的守卫检查：force、关卡满足条件、开放阻塞、epic 子问题。
- 关闭原因文件支持（`--reason-file`，从路径或标准输入读取）。

---

## 8. 工作流 Formulas（mol/pour）

### Molecule 系统
Molecule 是智能体工作流的工作模板。它们使用阶段隐喻：
- **Proto**：未实例化的模板（别名为 `protomolecule`）。一个带有 "template" 标签、定义了工作 DAG 的模板 epic。
- **Molecule**：proto 的生成实例 — 从模板创建的真实问题。
- **Spawn**：实例化 proto，从模板创建真实问题。
- **Bond**：多态组合操作（proto+proto, proto+mol, mol+mol）。
- **Distill**：将 ad-hoc epic 提取为可复用的 proto。
- **Compound**：结合操作的结果。
- **Digest**：压缩/浓缩后的 molecule。
- **Liquid 阶段**：存储在 `.beads/` 中的持久化 molecule。
- **Vapor 阶段**：临时 wisp（关闭时自动删除）。

### Pour 命令
```bash
bd mol pour <id> --var key=value     # 实例化 proto -> 持久化 mol
bd mol wisp <id> --var key=value     # 实例化 proto -> 临时 wisp
```
- 变量替换：模板中的 `{{key}}` 被替换为 `--var key=value`。
- 支持 dry-run 预览、JSON 输出、vapor 阶段警告。

### Formula 系统
Formula 是定义 molecule 模板的源层（TOML 文件）：
- 搜索路径：项目 `.beads/formulas/`、用户 `~/.beads/`、编排器 `$GT_ROOT`。
- Formula 类型：workflow, expansion, aspect, convoy。
- 每个 formula 包含：元数据、变量、步骤、extends、advice 规则、compose 规则、bond 点。
- 生命周期：Rig -> Cook -> Run。

### Bond 命令
```bash
bd mol bond <id1> <id2>
```
支持所有组合的多态结合操作。

---

## 9. 质量工具

### Lint
```bash
bd lint [issue-id...]
```
- 按类型检查问题是否缺少模板章节。
- 支持按 `--type` 和 `--status` 筛选。
- 如果发现警告则以退出码 1 退出（CI 友好）。
- JSON 输出。

### Preflight
```bash
bd preflight
```
- 静态清单或通过 `--check` 的自动检查模式。
- 8 项检查：测试、lint、格式化、污染、版本同步、文档差异。
- JSON 输出，便于 CI 集成。

### Stale
```bash
bd stale
```
- 查找最近 N 天内未更新的问题（通过 `--days` 配置，默认 30）。
- 按状态筛选，JSON 输出。

### Orphans
```bash
bd orphans
```
- 查找没有父级且没有依赖关系的问题。

### Duplicates
```bash
bd duplicates
bd find-duplicates
```
- 重复问题检测。

### Graph Check
```bash
bd graph check
```
- 通过检测循环来验证图的完整性。
- 退出码 0（无问题）或 1（发现问题）。

### Doctor
```bash
bd doctor
bd doctor --fix
```
- 全面的健康诊断，支持自动修复。
- 验证项：健康、制品、规范、污染、智能体设置。

### Compact
```bash
bd compact [--analyze|--apply|--auto|--dolt]
```
- 第 1 层：关闭 >= 30 天的问题，约 70% 缩减（语义压缩）。
- 第 2 层：关闭 >= 90 天的问题，约 95% 缩减（尚未实现）。
- 推荐智能体驱动的工作流：analyze -> 智能体编写摘要 -> apply。

---

## 10. 配置选项

### 配置后端
1. **YAML**（`config.yaml`）：启动设置，如 `no-db`，在数据库打开前读取。按优先级顺序的来源：
   - `~/.beads/config.yaml`（旧版）
   - `~/.config/bd/config.yaml`（用户级别）
   - 项目本地 `.beads/config.yaml`
   - `$BEADS_DIR/config.yaml`（最高优先级）
2. **Git 配置**：`beads.role`（通过 `git config` 存储）。
3. **SQLite 数据库**：所有其他配置键（需要直接模式）。
4. **环境变量**：`BD_*` 前缀的环境变量覆盖配置文件。

### 配置键（示例）
- `status.custom` — 自定义状态定义（`name:category,...` 格式）。
- `doctor.suppress.*` — 抑制特定的 doctor 警告。
- `validation.on-close` — 关闭原因验证模式（none/warn/error）。
- `beads.role` — 贡献者或维护者。
- `dolt_mode` — 嵌入式或服务器。
- 联合：远程、主权、允许的模式、类型排除。
- 元数据 schema 验证。
- `no-db` — 无数据库模式的启动标志。

### 配置命令
```bash
bd config set <key> <value>          # 设置值
bd config get <key>                  # 获取值
bd config list                       # 列出所有
bd config unset <key>                # 取消设置值
bd config show                       # 显示生效的配置
bd config apply <file>               # 从文件应用
bd config drift                      # 检测配置漂移
```

---

## 11. Beads 的预期使用方式（开发工作流）

### 个人开发者

1. **初始化**：在项目根目录运行 `bd init` — 创建包含 Dolt 数据库的 `.beads/` 目录。
2. **创建工作**：使用结构化描述运行 `bd create "任务标题" -p 1 -a @me -l bug`。
3. **认领工作**：`bd ready --claim` — 查看可用任务并原子性地认领一个。
4. **跟踪进度**：`bd update bd-abc --status in_progress` 或 `bd done bd-abc` 关闭。
5. **添加上下文**：使用 `bd remember "关键洞察"` 进行持久化记录；`bd prime` 在每次会话中自动注入。
6. **审查状态**：`bd status` 查看概览；`bd list` 查看筛选后的视图。
7. **管理依赖**：`bd dep add <child> <parent>` 定义阻塞关系。
8. **同步**：`bd dolt push/pull` 用于远程协作。

### AI 智能体（主要用例）

Beads 专为 AI 编程智能体设计：

1. **会话开始**：`bd prime` 通过 SessionStart 钩子自动运行，将工作流上下文和所有 `bd remember` 记忆注入到智能体的上下文窗口中。
2. **查找工作**：智能体运行 `bd ready` 查找未被阻塞的任务。
3. **认领工作**：智能体运行 `bd update <id> --claim` 原子性地认领任务（设置负责人并标记为 in_progress）。
4. **开发**：智能体按照任务描述进行开发，提交代码。
5. **关闭**：智能体完成时运行 `bd close <id>`（自动建议后续步骤）。
6. **持久化知识**：智能体使用 `bd remember "洞察"` 替代编写 MEMORY.md 文件。
7. **预压缩**：在压缩前运行 `bd prime --memories-only` 以保留关键上下文。
8. **会话关闭**：智能体提交所有更改、运行质量门禁、推送。

### 团队使用

1. **通过 Dolt 远程分发**：多个智能体/开发者通过 Dolt 类似 Git 的分支功能同步。
2. **零冲突**：基于哈希的 ID（`bd-a1b2`）防止合并冲突。
3. **多分支工作流**：智能体在独立分支上工作，通过 Dolt 合并。
4. **联合**：通过 `bd ship` 和 `bd dep add external:...` 实现跨项目依赖。
5. **关卡**：通过 `bd gate` 实现异步协调，支持人工介入或基于计时器的关卡。

### 最佳实践（从 CLI 设计推断）

- **使用结构化描述**：包含设计说明、验收标准、所需技能、上下文章节。
- **模板保证一致性**：为可重复的工作模式创建 proto/molecule。
- **依赖感知规划**：使用 `bd dep add` 定义工作顺序，然后用 `bd ready` 查看可执行项。
- **压缩旧工作**：定期运行 `bd compact` 总结已完成任务，节省上下文窗口。
- **安全导出**：`bd export -o backup.jsonl` 用于 Dolt 外的可移植性。
- **使用 `bd doctor --fix`** 在手动管理命令前进行常规维护。
- **关闭前 Lint**：`bd lint` 在标注完成前捕捉缺失的章节。
- **个人项目使用 Stealth 模式**：在共享项目上使用 `bd init --stealth` 避免提交 beads 文件。
- **智能体工作流**：优先使用 `bd remember` 而非 MEMORY.md 文件；`bd prime` 自动注入所有记忆。
