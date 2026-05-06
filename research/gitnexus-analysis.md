# GitNexus 完整调研报告

> 版本: 1.6.3 | 许可证: PolyForm-Noncommercial-1.0.0（非商业免费，商业需授权）
> 仓库: https://github.com/abhigyanpatwari/GitNexus
> 描述: "Graph-powered code intelligence for AI agents. Index any codebase, query via MCP or CLI."
> 作者: Abhigyan Patwari (Akon Labs)

---

## 一、设计哲学与核心灵魂

### 核心定位
"Building nervous system for agent context" — GitNexus 要做的是**为 AI Agent 构建代码上下文的中枢神经系统**。它不仅是一个代码索引工具，而是一个**知识图谱引擎**，将代码库转换为 AI Agent 可以高效查询的结构化知识网络。

### 解决的问题
1. **AI Agent 上下文窗口限制** — 大型代码库无法完整放入 LLM 上下文，需要高效检索
2. **代码理解碎片化** — 传统搜索只能找符号定义，无法理解跨文件的执行流和依赖关系
3. **多仓库协作困难** — 微服务架构下改动一个接口需要知道影响哪些下游服务
4. **Agent 工具链断裂** — 开发过程中需要在不同工具间切换，没有统一的知识接口

### 关键设计决策
- **100% 本地** — 所有索引和分析在本地完成，代码不上传
- **MCP 优先** — 原生支持 Model Context Protocol，直接嵌入 AI 编辑器的工具链
- **图谱即真相** — 不是简单符号表，而是完整的知识图谱（neo4j-like 数据模型）
- **无服务器架构** — 浏览器也可运行完整分析（Web UI 模式）

### 与同类工具对比
| 维度 | GitNexus | Sourcegraph | DeepWiki | ripgrep |
|------|----------|-------------|----------|---------|
| 部署 | 本地 CLI/MCP | SaaS/自托管 | 云端 | 本地 |
| 索引粒度 | 知识图谱+执行流 | 符号索引+搜索 | 文档生成 | 文本搜索 |
| Agent 集成 | MCP 原生 | Cody API | 有限 | 无 |
| 多仓库 | Group 机制 | 支持 | 单仓库 | 单仓库 |
| 实时diff分析 | detect-changes | 有限 | 无 | 无 |

---

## 二、完整 CLI 命令参考

### 2.1 顶层命令一览

```
Usage: gitnexus [options] [command]

Commands:
  setup                                   一次性 MCP 配置
  analyze [options] [path]                索引仓库（完整分析）
  index [options] [path...]               注册已有 .gitnexus/ 目录（无需重新分析）
  serve [options]                         启动本地 HTTP 服务器（Web UI）
  mcp                                     启动 MCP 服务器（stdio 模式）
  list                                    列出所有已索引仓库
  status                                  查看当前仓库索引状态
  clean [options]                         删除索引
  remove [options] <target>               按别名/路径删除已注册仓库
  wiki [options] [path]                   从知识图谱生成仓库维基
  augment <pattern>                       用知识图谱上下文增强搜索模式（Hook 使用）
  query [options] <search_query>          搜索知识图谱中的执行流
  context [options] [name]                符号的 360 度视图
  impact [options] <target>               影响范围分析（修改某符号会破坏什么）
  cypher [options] <query>                直接执行 Cypher 查询
  detect-changes [options]                将 git diff hunk 映射到索引符号
  eval-server [options]                   轻量级 HTTP 服务器（用于评估）
  group                                   管理仓库组（跨仓库影响分析）
```

### 2.2 子命令详解

#### `analyze` — 核心索引命令

```
npx gitnexus analyze [path] [options]

选项:
  -f, --force               强制完全重索引
  --embeddings              启用 embedding 生成（语义搜索，默认关闭）
  --drop-embeddings         重建时丢弃已有 embedding
  --skills                  从检测到的社区生成技能文件
  --skip-agents-md          跳过更新 AGENTS.md 和 CLAUDE.md
  --no-stats                跳过在 AGENTS.md/CLAUDE.md 写入统计
  --skip-git                索引非 git 目录
  --name <alias>            自定义注册名
  --allow-duplicate-name    允许重复注册名
  -v, --verbose             详细日志
  --max-file-size <kb>      跳过大文件（默认 512KB，硬上限 32768KB）

环境变量:
  GITNEXUS_NO_GITIGNORE=1   跳过 .gitignore 解析
  GITNEXUS_MAX_FILE_SIZE=N  覆盖文件大小限制（KB）
```

#### `context` — 符号 360 度视图

```
npx gitnexus context [name] [options]

功能: 显示一个代码符号的完整上下文：调用者、被调用者、所属执行流

选项:
  -r, --repo <name>    目标仓库
  -u, --uid <uid>      直接通过 UID 查找（零歧义）
  -f, --file <path>    用文件路径消歧（同名符号）
  --content            包含完整源码

数据模型:
  - callers: 谁调用了此符号
  - callees: 此符号调用了谁
  - processes: 所属的执行流（一系列相关符号组成的链路）
```

#### `impact` — 影响范围分析（核心功能）

```
npx gitnexus impact <target> [options]

功能: 分析修改某个符号会破坏什么（"blast radius"）

选项:
  -d, --direction <dir>  upstream(依赖者) 或 downstream(依赖项)
                         (默认: "upstream")
  -r, --repo <name>      目标仓库
  --depth <n>            最大关系深度 (默认: 3)
  --include-tests        包含测试文件

上游(upstream) = 依赖此符号的代码 = "破坏范围"
下游(downstream) = 此符号依赖的代码 = "需要同步修改的"
```

#### `query` — 知识图谱语义搜索

```
npx gitnexus query <search_query> [options]

功能: 搜索知识图谱中与概念相关的执行流

选项:
  -r, --repo <name>      目标仓库
  -c, --context <text>   任务上下文（改进排序）
  -g, --goal <text>      搜索目标描述
  -l, --limit <n>        最大返回进程数 (默认: 5)
  --content              包含完整符号源码
```

#### `detect-changes` — 实时变更分析

```
npx gitnexus detect-changes [options]

功能: 将 git diff 的 hunk 映射到已索引的符号和受影响的执行流

选项:
  -s, --scope <scope>   unstaged, staged, all, compare (默认: unstaged)
  -b, --base-ref <ref>  compare 模式的基线（如 main）
  -r, --repo <name>     目标仓库

使用场景: 在修改代码后立即查看哪些执行流受影响，适合预提交检查
```

#### `wiki` — 维基生成

```
npx gitnexus wiki [path] [options]

功能: 从知识图谱生成仓库维基文档

选项:
  -f, --force              强制重新生成
  --provider <provider>    LLM 提供者: openai 或 cursor (默认: openai)
  --model <model>          LLM 模型 (默认: minimax/minimax-m2.5)
  --base-url <url>         API 地址（支持 Azure）
  --api-key <key>          API 密钥
  --reasoning-model        推理模型模式（o1/o3/o4-mini）
  --concurrency <n>        并行 LLM 调用数 (默认: 3)
  --gist                   发布为 GitHub Gist
  --review                 先生成分组结构供审查
```

#### `augment` — Hook 用上下文增强

```
npx gitnexus augment <pattern>

功能: 用知识图谱上下文增强搜索模式，设计为被编辑器 Hook 调用
```

#### `cypher` — 原始查询

```
npx gitnexus cypher <query> [options]

功能: 直接对知识图谱执行 Cypher 查询（类似 Neo4j 语法）

选项:
  -r, --repo <name>  目标仓库
```

#### `group` 子命令 — 多仓库管理

```
Commands:
  create <name>          创建新组
  add <group> <path> <name>  添加仓库到组
  remove <group> <path>      从组移除仓库
  list [name]                列出所有组
  status <name>              检查组和仓库的时效性
  sync <name>                同步契约注册表（提取跨仓库契约）
  impact <name>              跨仓库符号影响分析
  query <name> <query>       跨仓库执行流搜索
  contracts <name>           检查契约注册表

group impact 选项:
  --target <symbol>     要分析的符号
  --repo <groupPath>    成员路径（如 app/backend）
  --direction <dir>     upstream/downstream
  --service <path>      可选的 monorepo 服务目录前缀
  --subgroup <path>     限制参与跨仓库扇出的仓库
  --max-depth <n>       图谱遍历深度
  --cross-depth <n>     跨仓库跳转深度
  --min-confidence <n>  最小置信度 (0-1)
  --include-tests       包含测试
  --timeout-ms <n>      超时时间
  --json                JSON 输出
```

---

## 三、知识图谱架构

### 3.1 数据模型

GitNexus 在底层使用类似 Neo4j 的图数据库模型：

- **节点 (Nodes)**: 每个代码符号（函数、类、变量、接口、模块/文件）
- **边 (Edges)**: 符号之间的关系（调用、继承、导入、定义、赋值）
- **进程 (Processes)**: 一系列相关符号组成的执行流（类似静态分析中的调用链路）

### 3.2 底层技术栈

```
索引层:
  - tree-sitter (C/C++/Go/Java/PHP/Ruby) — 语法分析
  - tree-sitter ^0.21.1 — 核心解析库
  - glob — 文件匹配

存储层:
  - @ladybugdb/core — 嵌入式图数据库
  - graphology ^0.26.0 — 图操作库
  - graphology-utils — 图工具

语义搜索:
  - onnxruntime-node ^1.24.0 — 本地 embedding 推理

Web 服务:
  - express ^4.19.2 — HTTP 服务器
  - cors — 跨域支持

MCP:
  - 原生 MCP 协议支持 (stdio)

实用工具:
  - commander — CLI 框架
  - js-yaml / jsonc-parser — 配置解析
  - ignore — .gitignore 解析
  - cli-progress — 进度条
  - lru-cache — 缓存
  - mnemonist — 数据结构
  - pandemonium — 随机工具
  - uuid — 唯一标识
```

### 3.3 Tree-Sitter 支持的语言

从依赖中确认支持的语言：
- **C** — `tree-sitter-c 0.23.2`
- **C++** — `tree-sitter-cpp ^0.23.4`
- **Go** — `tree-sitter-go ^0.23.0`
- **Java** — `tree-sitter-java ^0.23.5`
- **PHP** — `tree-sitter-php ^0.23.0`
- **Ruby** — `tree-sitter-ruby ^0.23.1`

企业版额外支持 OCaml。

注意：通过 tree-sitter 的通用架构，理论上可以扩展支持更多语言。当前版本选择了主流的后端/系统语言作为优先支持。

### 3.4 索引文件结构

分析后在仓库根目录生成 `.gitnexus/` 目录，包含：
```
.gitnexus/
  ├── meta.json        # 索引元数据（时间戳、统计）
  ├── graph.db/        # LadybugDB 图数据库文件
  ├── embeddings/      # （可选）embedding 向量
  └── ...
```

全局注册表位于 `~/.gitnexus/registry.json`，记录所有已索引仓库的路径和别名。

---

## 四、MCP 集成

### 4.1 协议支持

GitNexus 原生支持 **Model Context Protocol (MCP)**，可以直接作为 MCP 服务器运行：

```bash
# 在当前仓库启动 MCP 服务器
npx gitnexus mcp

# 此命令启动 stdio 模式的 MCP 服务器
# 提供所有已索引仓库的查询能力
```

### 4.2 编辑器配置

`setup` 子命令一键配置以下编辑器的 MCP 集成：
- **Cursor** — 添加为 MCP 工具
- **Claude Code** — 添加到 claude.json
- **OpenCode** — 配置 MCP 服务器
- **Codex** — 配置 MCP 工具

### 4.3 Agent 可用工具

通过 MCP，AI Agent 可以获得以下能力：
1. `context(symbol)` — 查看符号上下文
2. `impact(symbol)` — 影响范围分析
3. `query(pattern)` — 执行流搜索
4. `detect-changes()` — 分析当前变更
5. `augment(pattern)` — 上下文增强

---

## 五、输出格式

### 5.1 CLI 输出

默认输出为**格式化文本**，设计为人类可读。关键命令（如 `group impact`、`group sync`、`group contracts`）支持 `--json` 标志输出 JSON。

### 5.2 context 输出示例

```
Symbol: UserService.createUser
File: src/services/user.ts:42
Type: Function

Callers:
  - UserController.registerUser (src/controllers/user.ts:15)
  - AdminController.createUser (src/controllers/admin.ts:88)

Callees:
  - UserRepository.save (src/repositories/user.ts:120)
  - EmailService.sendWelcome (src/services/email.ts:55)

Processes:
  - User Registration Flow (涉及 8 个符号)
  - Admin User Creation Flow (涉及 12 个符号)
```

### 5.3 impact 输出示例

```
Impact Analysis: UserService.createUser
Direction: upstream (dependants)
Depth: 3

Level 1 (direct callers):
  - UserController.registerUser
  - AdminController.createUser

Level 2 (indirect):
  - Route.registerUserRoute → UserController.registerUser
  - Route.adminCreateUserRoute → AdminController.createUser

Level 3:
  - App.server → Route.registerUserRoute
  - App.server → Route.adminCreateUserRoute

Total affected symbols: 5
Affected execution flows: 2
```

---

## 六、核心使用场景

### 场景 1：Agent 驱动的代码理解

```
用户：这个仓库的认证流程是什么样的？
Agent → query("authentication") → 获取执行流
Agent → context("login") → 获取完整上下文
Agent → impact("login") → 了解修改影响
```

### 场景 2：预提交影响检查

```
开发者修改了 createUser 函数
→ detect-changes --scope staged
→ 检测到 3 个受影响执行流
→ 确认是否需要更新相关测试
```

### 场景 3：跨仓库微服务分析

```
配置 group 包含 auth-service, user-service, payment-service
修改 auth-service 的 token 验证接口
→ group impact --target auth-service --direction upstream --cross-depth 2
→ 发现影响 user-service 和 payment-service 的 5 个调用点
```

### 场景 4：知识文档生成

```
npx gitnexus wiki --provider openai --model gpt-4o --gist
→ 从知识图谱自动生成仓库维基
→ 发布为 GitHub Gist 供团队参考
```

---

## 七、Windows 兼容性注意

GitNexus 在 Windows 上使用 tree-sitter 原生模块时可能出现 **SIGSEGV**（段错误，退出码 139），原因是 tree-sitter 的 C/C++ 原生绑定与 Node 22 在 Windows 上的兼容性问题。

解决方案已在 devflow 中实现：
- `scripts/gitnexus-docker.ps1` — 通过 Docker 容器运行 tree-sitter 分析（Linux 环境）
- 降级模式 — 没有 Docker 时直接运行原生 gitnexus（可能失败）

---

## 八、总结

GitNexus 的设计灵魂在于：**它不是"代码搜索"工具，而是"代码理解"引擎**。通过构建静态知识图谱，它还原子工阅读代码时的"跳转-理解-关联"过程，让 AI Agent 能够高效理解大型代码库。

其创新点：
1. **知识图谱数据模型** — 超越传统的符号索引，保留符号间的复杂关系
2. **执行流 (Processes)** — 知道符号属于哪个完整的执行链路
3. **Group 机制** — 原生支持微服务架构的多仓库分析
4. **MCP 原生** — 直接嵌入 AI 开发工具链
5. **detect-changes** — 将 git 变更与知识图谱实时关联

devflow 集成建议：
- Phase 4（开发阶段）接入 gitnexus，作为代码理解的知识基础设施
- 使用 `detect-changes` 作为预提交质量门禁
- 多项目关联场景使用 `group` 功能
- Docker 模式解决 Windows tree-sitter 兼容性问题
