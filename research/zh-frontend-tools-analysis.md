# 前端代码生成工具：全面分析

> 为 devflow 阶段 2（设计引擎）集成所做的调研
> 日期：2025 年 7 月（基于最新可用数据）

---

## 目录

1. [screenshot-to-code (abi/screenshot-to-code)](#1-screenshot-to-code-abiscreenshot-to-code)
2. [bolt.diy (stackblitz-labs/bolt.diy)](#2-boltdiy-stackblitz-labsboltdiy)
3. [OpenUI (wandb/openui)](#3-openui-wandbopenui)
4. [Google Stitch MCP](#4-google-stitch-mcp)
5. [其他值得关注的工具](#5-其他值得关注的工具)
6. [框架与设计系统映射](#6-框架与设计系统映射)
7. [对比矩阵](#7-对比矩阵)
8. [devflow 集成建议](#8-devflow-集成建议)

---

## 1. screenshot-to-code (abi/screenshot-to-code)

### 概览

- **仓库地址：** `abi/screenshot-to-code` (GitHub)
- **星标数：** ~72,400+（该类别中星标最多的工具）
- **许可证：** MIT（部分组件可自托管）
- **主要用途：** 将截图/设计稿转换为整洁的前端代码
- **devflow SKILL.md 状态：** 已有文档记录，基于 Docker 安装，按需提供

### 核心特性

- **输入方式：** 截图、屏幕录制、Figma 设计稿导出
- **输出格式：** HTML + Tailwind、React + Tailwind、Vue + Tailwind、SVG
- **AI 后端：** GPT-4o vision（默认），Claude 3.5 Sonnet 备选
- **质量：** 视觉布局保真度高；复杂交互逻辑处理较弱
- **堆栈生成：** 生成单文件或最小项目结构

### 安装方式

| 方式 | 命令 | 备注 |
|--------|---------|-------|
| Docker（推荐） | `docker pull screenshot-to-code` | 最简单，环境一致 |
| 本地（npm） | `npm install -g screenshot-to-code` | 需要 API 密钥 |
| 后端（Python） | `pip install -r requirements.txt` | 需要完整后端环境 |

### 输出质量评估

| 方面 | 评分 | 备注 |
|--------|--------|-------|
| 视觉保真度 | 8/10 | 简单布局可达像素级精确 |
| 响应式设计 | 6/10 | 断点需要手动调整 |
| 交互逻辑 | 4/10 | 点击处理、状态管理较弱 |
| 代码整洁度 | 7/10 | HTML/CSS 结构良好，JS 代码精炼 |
| 框架规范性 | 6/10 | 遵循框架模式但不地道 |

### 代理管线集成

- **最佳集成点：** devflow 阶段 2 子阶段 3，当用户提供截图时
- **当前 devflow 集成：** 通过 Docker 按需安装，当截图可用时提供
- **局限性：** 生成静态输出——无法基于代理反馈进行迭代（除非重新运行）
- **变通方案：** 作为"初稿"生成器使用，再由 Claude Direct 精炼

---

## 2. bolt.diy (stackblitz-labs/bolt.diy)

### 概览

- **仓库地址：** `stackblitz-labs/bolt.diy` (GitHub)
- **星标数：** ~25,000+（从 bolt.new 分支而来，活跃维护中）
- **许可证：** MIT
- **主要用途：** 根据自然语言提示生成全栈 Web 应用
- **devflow SKILL.md 状态：** 已有文档记录，用于大型项目（16 页以上）

### 核心特性

- **多 LLM 支持：** 支持 OpenAI、Anthropic、Google Gemini、本地模型（Ollama）
- **全栈生成：** 前端 + 后端 + 数据库模式一步到位
- **实时预览：** 内置 WebContainer 实现即时预览
- **迭代编辑：** 可通过聊天修改已生成的代码
- **一键部署：** 集成 Netlify 部署
- **架构：** 基于 WebContainer（StackBlitz 技术），在浏览器中运行

### 安装方式

| 方式 | 命令 | 备注 |
|--------|---------|-------|
| Git 克隆 | `git clone && npm install && npm run dev` | 完整项目，体积较大（~500MB） |
| Docker | `docker pull stackblitz/bolt-diy` | 推荐用于 CI/代理场景 |
| Netlify 部署 | 从 GitHub 一键部署 | 无需本地安装 |

### 输出质量评估

| 方面 | 评分 | 备注 |
|--------|--------|-------|
| 项目结构 | 8/10 | 完整的项目脚手架 |
| 代码质量 | 7/10 | 因模型而异；Claude 3.5 效果最佳 |
| 交互逻辑 | 7/10 | 优于 screenshot-to-code |
| 可扩展性 | 5/10 | 适合原型，不适合生产环境 |
| 框架支持 | 8/10 | React、Next.js、Vue、Svelte 等 |

### 代理管线集成

- **最佳集成点：** devflow 阶段 2 子阶段 3，用于大型/复杂项目
- **当前 devflow 集成：** 向用户推荐用于 16 页以上或具有复杂交互的项目
- **主要优势：** 可通过 API 以编程方式调用（支持无头模式）
- **主要局限：** 资源消耗大；每个实例运行完整的 IDE
- **建议：** 仅用于初始脚手架搭建，然后由 Claude Direct 精炼

### 值得关注：bolt.diy v1.0.0

v1.0.0 版本带来了：
- 改进的代理编排（提示路由到专用代理）
- 生成过程中更好的错误恢复能力
- 持久化工作空间会话
- 扩展模型支持（通过 Ollama 使用 LLaMA、Mistral）

---

## 3. OpenUI (wandb/openui)

### 概览

- **仓库地址：** `wandb/openui` (GitHub，由 Weights & Biases 维护)
- **星标数：** ~22,300（快速增长中）
- **许可证：** Apache 2.0
- **主要用途：** 文本到 UI 生成，支持实时预览和迭代
- **devflow SKILL.md 状态：** 已有文档记录，`pip install openui`

### 核心特性

- **文本到 UI：** 用自然语言描述 UI，获得生成的代码
- **实时预览沙盒：** 实时运行生成的 HTML，支持编辑
- **迭代优化：** 修改提示词以调整输出效果
- **多框架输出：** React、Vue、Svelte、纯 HTML
- **版本历史：** 保存之前的生成结果，便于对比
- **Weights & Biases 集成：** 跟踪实验（面向 W&B 用户）

### 安装方式

| 方式 | 命令 | 备注 |
|--------|---------|-------|
| pip | `pip install openui` | 最简单，Python 包 |
| Docker | `docker pull wandb/openui` | 隔离化，容器化运行 |
| 源码 | `git clone && pip install -e .` | 开发模式 |

### 输出质量评估

| 方面 | 评分 | 备注 |
|--------|--------|-------|
| UI 组件质量 | 7/10 | 单个组件表现良好 |
| 多页面应用 | 4/10 | 专注于单页面 |
| 设计系统匹配 | 6/10 | 能够匹配给定的设计风格 |
| 迭代便利性 | 8/10 | 同类最佳，快速迭代 |
| 代码导出 | 6/10 | 需要从沙盒中提取 |

### 代理管线集成

- **最佳集成点：** devflow 阶段 2 子阶段 3，用于中型项目（6-15 页）
- **当前 devflow 集成：** 为中等复杂度项目提供
- **主要优势：** 快速迭代周期（提示 -> 预览 -> 修改）
- **主要局限：** 不支持全栈生成，仅生成 UI 组件
- **建议：** 在 Claude Direct 脚手架内用于组件级别的生成

### 安全通知

CVE-2024-10649：未经认证的文件上传漏洞（未经认证的用户可上传任意文件）。已在后续版本中修复。对于将 OpenUI 暴露给外部输入的代理管线来说，这一点很重要。

---

## 4. Google Stitch MCP

### 概览

- **仓库地址：** `davideast/stitch-mcp`（MCP 服务器）+ `google-labs-code/stitch-skills`（代理技能库）
- **来源：** Google Labs（官方）
- **主要用途：** AI 优先的 UI 设计平台，配备 MCP 桥接，用于代理化编码工作流
- **devflow SKILL.md 状态：** 当前尚未记录——这是一个新的集成候选方案

### 架构

Google Stitch MCP 通过三个组件实现"设计到代码"的桥接：

1. **Stitch 平台**（云端）：AI 驱动的可视化 UI 设计工具，运行在浏览器中
2. **stitch-mcp**（npm 包）：MCP 服务器，将设计从 Stitch 平台传输到本地开发环境
3. **stitch-skills**（GitHub 仓库）：面向 Claude Code、Gemini CLI、Cursor、Antigravity 的代理技能集合

工作流：代理描述 UI -> Stitch 生成视觉设计 -> MCP 提取代码 -> 代理集成到项目中

### 安装方式

| 方式 | 命令 / 步骤 | 备注 |
|--------|-----------------|-------|
| MCP 服务器 | `npx @_davideast/stitch-mcp` | NPM 包，需要 Google Cloud 项目 |
| 代理技能 | `git clone google-labs-code/stitch-skills` | 面向 Claude Code 的代理技能库 |
| Codelab | Google Codelab "Design to Code with Antigravity + Stitch" | 分步教程 |

### MCP 服务器设置要求

- 已启用结算功能的 Google Cloud 项目（即使规模很小也需要）
- 已启用 Vertex AI API
- 已配置应用默认凭据（ADC）
- 已在代理的 `settings.json` 的 MCP 部分注册 `stitch-mcp`
- Windows 注意事项：Issue [#36](https://github.com/davideast/stitch-mcp/issues/36)——运行代理命令时出现 `spawn EINVAL` 错误

### stitch-skills 库

Google 官方发布了 stitch-skills（开源，采用代理技能标准格式）：

| 技能 | 用途 |
|-------|---------|
| `stitch-design` | 通过 Stitch 平台生成 UI 设计 |
| `design-md` | 用结构化 markdown 记录设计决策 |
| （库中有更多技能） | 设计评审、导出、主题提取 |

这些技能与 Claude Code、Gemini CLI、Cursor 和 Antigravity 代理兼容。

### 代理管线集成潜力

- **最佳集成点：** devflow 阶段 2 子阶段 2（架构蓝图）或子阶段 3（脚手架生成）
- **模型：** 代理描述 UI 架构 -> Stitch 生成视觉原型 -> MCP 提取 HTML/CSS -> 代理集成到脚手架
- **主要优势：** Google 背书，积极开发中，MCP 原生支持，代理技能兼容
- **主要劣势：** 需要 Google Cloud 项目和 Vertex AI API（非纯本地）
- **Windows 问题：** 已知代理中存在 `spawn EINVAL` 错误（在 GitHub 上有跟踪）
- **建议：** 作为可选的阶段 2 工具加入，面向已搭建 Google Cloud 的用户；MCP 集成方式很简洁

---

## 5. 其他值得关注的工具

### 5.1 v0.dev (Vercel)

- **类型：** SaaS（免费增值，基于代币计费）
- **主要用途：** React + Tailwind / Next.js 的 AI UI 生成
- **星标数：** 非开源（Vercel 专有）
- **为何重要：** 输出质量最高；作为对比的金标准
- **定价：** 免费层（有限代币），付费层按代币使用量计费
- **输出质量：** 9/10——地道的 React，规范的 Tailwind，默认响应式
- **集成潜力：** 无 CLI/MCP（Vercel 仅提供 Web UI 和 API）。没有 API 访问权限时不适用于代理管线。
- **结论：** 作为质量对比的基线，但如果没有 API 密钥和商业许可，无法直接集成到 devflow 代理管线中。

### 5.2 Lovable.dev

- **类型：** SaaS（免费增值）
- **主要用途：** 从自然语言生成全栈 Web 应用
- **集成潜力：** 基于 API，类似 bolt.new
- **定价：** 免费层（有限），付费从 $20/月起
- **结论：** 质量高但存在 SaaS 锁定。不推荐用于开源代理管线。

### 5.3 Dyad (dyad.sh / dyad-sh/dyad)

- **类型：** 开源（MIT），本地优先
- **星标数：** 快速增长中（2025 年约 10,000+）
- **主要用途：** 本地 AI 应用构建器——v0/Lovable/Bolt 的替代方案
- **安装方式：** `npm install -g dyad` 或桌面应用（Electron）
- **核心特性：**
  - 完全本地化，无云端依赖
  - 支持 Ollama 实现离线 LLM
  - 类似 bolt.diy 的实时预览
  - 生成的代码为干净的 React/Next.js
- **对 devflow 的优势：** 本地优先（与阶段 3 兼容），无 SaaS 依赖，输出整洁
- **劣势：** 较新项目，社区较小，Electron 应用开销
- **建议：** 前景良好，关注稳定性；未来有潜力纳入

### 5.4 Claudable (opactorai/Claudable)

- **类型：** 开源（MIT）
- **星标数：** ~3,000+（2025 年）
- **主要用途：** 将任务委托给本地 CLI 代理（Claude Code、Codex、Gemini CLI 等）的 Web 构建器
- **关键洞察：** 使用 Claude Code 作为"引擎"——与 devflow 自身的架构高度一致
- **特性：**
  - 多代理：将任务路由到不同的 CLI 编码代理
  - 零配置：自动配置代理环境
  - 部署：一键部署到托管平台
  - 全栈：生成完整项目
- **为何重要：** Claudable 本质上在做 devflow 阶段 2 + 阶段 4 已经做的事情，但专注于 Web 应用构建。与其替代，devflow 可以从其代理路由模式中学习。
- **建议：** 研究其多代理路由架构；devflow 可以在阶段 2 脚手架生成中采用类似模式。

### 5.5 Open Design (nexu-io/open-design)

- **类型：** 开源（MIT）
- **星标数：** ~5,000+（2025 年，在 Claude Design 发布后快速增长）
- **主要用途：** 本地优先、开源的 Anthropic Claude Design 替代方案
- **核心特性：**
  - 19 个用于设计生成的代理技能
  - 包含 71 个品牌级设计系统
  - 可生成：Web 原型、桌面/移动端 UI、幻灯片、图片、视频
  - HyperFrames：多屏交互式原型
  - 导出格式：HTML、PDF、PPTX、MP4
  - 多 CLI 支持：Claude Code、Codex、Cursor、Gemini、OpenCode、Qwen、Copilot、Hermes、Kimi
- **为何重要：** 最全面的开源设计到代码工具；直接与 Claude Design 竞争。内置的 71 个设计系统与 devflow 的框架匹配表很好地对应。
- **建议：** devflow 阶段 2 集成的强力候选——仅其设计系统库就极具价值。当设计质量至关重要时，考虑将其作为 Claude Direct 生成的替代方案。

### 5.6 InstantCoder (osanseviero/InstantCoder)

- **类型：** 开源（Apache 2.0）
- **主要用途：** 使用 Google Gemini API 创建应用
- **特性：** 实时预览、代码导出、由 Gemini 驱动
- **拥有 MCP 服务器：** `InstantCoder-MCP` 可用
- **结论：** 小众领域，Gemini 专属。不是 devflow 的优先项。

### 5.7 open-codesign (OpenCoworkAI/open-codesign)

- **类型：** 开源（MIT）
- **主要用途：** 开源的 Claude Design 替代方案
- **特性：** 自带密钥（BYOK）、多模型、一键导入 API 密钥
- **类似：** Open Design (nexu-io)，成熟度较低
- **结论：** 保持关注。Open Design 势头更强劲。

### 5.8 WebBuilder / AnyCoder / Micracode

- **类型：** 各类开源的 Lovable/Bolt 克隆
- **成熟度：** 早期阶段，社区规模小
- **结论：** 暂不推荐集成。过于不稳定。

### 5.9 Quests（基于 Groq 的本地应用构建器）

- **类型：** 开源
- **主要用途：** 针对 Groq 硬件优化的本地应用构建器
- **结论：** 小众硬件依赖。不适用于一般的 devflow 使用。

---

## 6. 框架与设计系统映射

当前 devflow 框架匹配（来自 SKILL.md）：

| 项目类型 | 默认框架 | 设计系统 |
|---|---|---|
| 落地页 | Next.js + Tailwind | Tailwind UI |
| 管理后台 | React + Ant Design | Ant Design Pro |
| 社交平台 | Next.js + Tailwind | shadcn/ui |
| 电商 | Next.js + Tailwind | shadcn/ui |
| 工具类 | React + Tailwind | shadcn/ui |
| 内容站点 | Next.js + Tailwind + MDX | Tailwind UI |
| 移动端 | React Native + NativeWind | NativeWind |

### 增强机会

Open Design 的 71 个设计系统可以补充此表。应考虑的关键补充项：

| 项目类型 | 潜在替代框架 | 替代设计系统 |
|---|---|---|
| 落地页 | Astro + Tailwind | Tailwind UI（不变） |
| 管理后台 | Vue 3 + Element Plus | Element Plus |
| 社交平台 | SvelteKit + Tailwind | shadcn-svelte |
| 电商 | Next.js + Tailwind | Tailwind UI commerce |
| 工具类 | React + Mantine | Mantine |
| 内容站点 | Astro + MDX | Starlight |
| 移动端 | Flutter | Material Design 3 |

当用户有特定偏好时，这些可以作为次要选项提供。

---

## 7. 对比矩阵

| 工具 | 类型 | 星标数（约） | 安装复杂度 | 全栈 | 视觉输入 | 迭代能力 | 代理友好 | 本地优先 | Windows 兼容 |
|------|------|---------------|-------------------|------------|-------------|-----------|---------------|-------------|----------------|
| screenshot-to-code | 开源 | 72.4k | 中等（Docker） | 否 | 是（截图） | 否 | 部分 | 是（Docker） | 是（Docker） |
| bolt.diy | 开源 | 25k | 高（npm） | 是 | 否（仅文本） | 是 | 部分 | 是 | 部分 |
| OpenUI | 开源 | 22.3k | 低（pip） | 否 | 否（仅文本） | 是 | 部分 | 是 | 是 |
| Google Stitch MCP | Google + 开源 | 新（2025） | 中等（GCloud） | 否 | 是（Stitch 平台） | 是 | 优秀（MCP 原生） | 否 | 部分（#36 错误） |
| v0.dev | SaaS（专有） | 不适用 | 无（云端） | 否 | 否（仅文本） | 是 | 有限（仅 API） | 否 | 不适用 |
| Lovable.dev | SaaS（专有） | 不适用 | 无（云端） | 是 | 否（仅文本） | 是 | 有限（仅 API） | 否 | 不适用 |
| Dyad | 开源 | ~10k | 低（npm） | 是 | 否（仅文本） | 是 | 部分 | 是 | 是 |
| Claudable | 开源 | ~3k | 低（npm） | 是 | 否（仅文本） | 是 | 优秀（基于 Claude Code） | 是 | 是 |
| Open Design | 开源 | ~5k | 低（npm） | 否 | 是（HyperFrames） | 是 | 优秀（代理技能） | 是 | 是 |

### 维度说明

- **类型：** 开源 vs. SaaS/专有
- **安装复杂度：** 低（pip/npm 单命令）、中等（Docker）、高（多步骤）
- **全栈：** 是否同时生成后端代码和前端代码
- **视觉输入：** 是否支持从截图、设计稿或视觉原型出发
- **迭代能力：** 是否支持反复优化而无需从头开始
- **代理友好：** 是否可通过代理脚本以编程方式触发（MCP、CLI、API）
- **本地优先：** 是否无需云端依赖即可运行
- **Windows 兼容：** 能否在 Windows 上无重大问题地运行

---

## 8. devflow 集成建议

### 当前状态（SKILL.md 阶段 2）

```
小型（1-5 页）      -> Claude Direct
中型（6-15 页）     -> 提供 OpenUI
大型（16 页以上）   -> 提供 bolt.diy
用户提供截图        -> screenshot-to-code（Docker）
```

### 建议的增强方案

#### 层级 1：保留 Claude Direct 作为默认方案（覆盖 80% 项目）

Claude Direct 仍然是大多数项目的正确默认方案。零安装、零依赖、完全可控。

#### 层级 2：添加 Google Stitch MCP 作为可选桥接

- **何时提供：** 用户拥有 Google Cloud 项目，且希望采用设计优先的工作流
- **集成点：** devflow 阶段 2 子阶段 2（架构蓝图）
- **方式：** 在项目设置中注册 MCP 服务器，提供 stitch-design 技能用于 UI 生成
- **好处：** 在代码生成之前实现一流的视觉设计
- **成本：** Google Cloud API 使用费（小项目用量极少）
- **注意：** Windows 用户可能遇到 spawn EINVAL 问题

#### 层级 3：添加 Open Design 作为 Claude Direct 增强

- **何时提供：** 设计质量至关重要；用户希望使用 71 个内置设计系统
- **集成点：** devflow 阶段 2 子阶段 3（脚手架生成）
- **方式：** 使用 Open Design 的设计系统库作为 Claude Direct 生成的参考
- **好处：** 利用专业设计系统提升 Claude Direct 输出质量
- **成本：** 免费（MIT），在同一个 CLI 代理（Claude Code）上运行

#### 层级 4：将 bolt.diy 升级为可选的全栈脚手架

- **何时提供：** 用于复杂全栈应用（管理面板、仪表盘、社交平台）
- **集成点：** devflow 阶段 2 子阶段 3
- **方式：** 让 bolt.diy 生成完整的脚手架，然后 devflow 的 Claude Direct 精炼并添加业务逻辑
- **好处：** 更快获得可运行的原型
- **成本：** 资源消耗大

#### 层级 5：添加 Dyad 作为本地优先的 Bolt 替代方案

- **何时提供：** 用户希望纯本地环境，不依赖 Docker，不依赖云端
- **集成点：** devflow 阶段 2 子阶段 3（bolt.diy 替代）
- **方式：** 在 bolt.diy 过于笨重时，用 Dyad 替代工具选项中的 bolt.diy
- **好处：** 轻量、纯本地、生成干净的 React 代码
- **成本：** 较新项目，经过的实战检验较少

### 建议的更新决策树

```
用户是否提供截图？
  是 -> screenshot-to-code（Docker）-> Claude Direct 精炼
  否 -> 继续

项目复杂度？
  小型（1-5 页）：
    -> Claude Direct（默认）
    -> 或 Open Design + 设计系统（如果质量至关重要）
    -> 或 Google Stitch MCP（如果用户有 GCloud）

  中型（6-15 页）：
    -> OpenUI（pip install）用于快速原型
    -> 或 Open Design 用于结构化组件生成
    -> Claude Direct 用于集成

  大型（16 页以上）：
    -> bolt.diy（git clone + npm）或 Dyad（本地替代方案）
    -> 或 Claudable（多代理路由）
    -> Claude Direct 用于业务逻辑和打磨
```

### devflow 的实施优先级

1. **立即实施（低投入，高价值）：**
   - 将 Open Design 的设计系统库作为 Claude Direct 的参考
   - 这不需要任何新的依赖，并能立即提升输出质量

2. **中期（适度投入）：**
   - 将 Google Stitch MCP 添加为可选的阶段 2 工具
   - 需要在项目设置和文档中进行 MCP 注册

3. **长期（较高投入）：**
   - 添加 Dyad 作为纯本地的 bolt.diy 替代方案
   - 添加 Open Design 代理技能集成以用于阶段 2

### 跨平台注意事项（Windows）

| 工具 | Windows 状态 | 备注 |
|------|---------------|-------|
| screenshot-to-code | 通过 Docker 可用 | 需要 Docker Desktop |
| bolt.diy | 部分支持 | npm 可用但较笨重；部分脚本假设 Unix 环境 |
| OpenUI | 可用 | pip 在 Windows 上正常工作 |
| Google Stitch MCP | 有 Bug | Issue #36：代理中 spawn EINVAL 错误 |
| Dyad | 可用 | Electron 应用，npm 正常工作 |
| Claudable | 可用 | 基于 Node.js |
| Open Design | 可用 | 基于 Node.js，代理技能 |

---

## 总结

- **screenshot-to-code** 仍然是视觉输入驱动生成（截图）的最佳选择
- **bolt.diy** 是全栈生成能力最强的工具，但较为笨重
- **OpenUI** 快速且轻量，适合 UI 组件原型设计
- **Google Stitch MCP** 架构上最为优雅（MCP 原生）但需要 Google Cloud
- **Open Design** 是最有前景的新入局者，拥有 71 个设计系统和代理技能
- **Dyad** 和 **Claudable** 是值得关注的新兴替代方案，适合未来集成
- **Claude Direct**（默认方案）在质量、速度和零依赖之间取得了最佳平衡，适用于大多数 devflow 项目
