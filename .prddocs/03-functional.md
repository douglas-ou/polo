# 03 - 功能需求

## 功能模块总览

```
Craft Agents
├── 会话管理 (Session Management)
├── Agent 交互 (Agent Interaction)
├── 源系统 (Sources)
├── 技能系统 (Skills)
├── 自动化 (Automations)
├── 权限系统 (Permissions)
├── 多 LLM 连接 (LLM Connections)
├── 工作区管理 (Workspace)
├── 状态与标签 (Status & Labels)
├── 文件处理 (File Handling)
├── 主题系统 (Themes)
├── 远程服务器 (Remote Server)
└── 多平台客户端 (Multi-Platform Clients)
```

---

## F1: 会话管理

### F1.1 会话生命周期
- **创建会话**: 支持指定名称、权限模式、模型、工作区
- **会话持久化**: JSONL 格式存储，首行为 SessionHeader 元数据，后续行为消息
- **懒加载**: 启动时仅加载元数据，消息按需加载
- **自动命名**: AI 生成会话标题或手动命名
- **归档/删除**: 支持归档和永久删除

### F1.2 会话状态
- **状态工作流**: Todo → In Progress → Needs Review → Done → Cancelled
- **自定义状态**: 工作区可配置自定义状态（颜色、图标、类别）
- **Inbox/Archive**: 按 `open`/`closed` 类别自动分组
- **标记 (Flagging)**: 标记重要会话快速访问

### F1.3 会话分支
- **SDK Fork**: 使用提供商原生的 fork 能力
- **Seeded Branch**: 从任意消息创建新会话，保留历史上下文
- **Turn Anchors**: 侧文件存储精确的分支截断点

### F1.4 会话传输
- **工作区间传输**: 将会话发送到其他工作区
- **远程传输**: 本地会话传输到远程服务器（带进度追踪）
- **传输摘要**: `transferredSessionSummary` 用于一次性上下文迁移

### F1.5 未读状态
- 基于窗口焦点和当前查看会话的未读徽章状态机
- `lastReadMessageId` 持久化追踪

---

## F2: Agent 交互

### F2.1 消息收发
- **用户消息**: 文本输入 + 文件附件 + @提及
- **Agent 响应**: 流式文本输出，实时渲染
- **工具调用可视化**: 显示工具名称、输入参数、执行结果、耗时
- **后台任务**: 长时间运行的操作支持后台执行 + 进度追踪

### F2.2 工具系统
- **原生工具**: Read, Write, Edit, MultiEdit, Glob, Grep, Bash, LSP, WebFetch, WebSearch
- **MCP 工具**: 通过 MCP 客户端池连接外部工具
- **API 工具**: 动态构建的 REST API 工具
- **会话工具**: submit_plan, call_llm, transform_data, script_sandbox, source_oauth_trigger 等
- **浏览器工具**: Agent 控制的浏览器自动化

### F2.3 计划系统
- **Submit Plan**: Agent 提交计划 (Markdown) 供用户审核
- **Accept & Compact**: 接受计划后压缩上下文继续执行
- **Pending Plan Tracking**: 追踪待执行计划状态

### F2.4 文件附件
- **拖拽上传**: 图片、PDF、Office 文档
- **自动转换**: Office 文档 → Markdown（Python 工具链）
- **图片处理**: 自动缩放、缩略图生成 (Sharp)
- **附件持久化**: 磁盘存储 + 元数据索引

### F2.5 @提及系统
- **Source 提及**: `@linear`, `@gmail` 等，启用对应源
- **Skill 提及**: `@skill-name`，加载对应技能
- **内联徽章**: 消息中渲染为带图标的徽章组件
- **动态加载**: 会话中随时提及新源/技能，即时生效

---

## F3: 源系统 (Sources)

### F3.1 MCP 服务器
- **传输协议**: HTTP, SSE, Stdio
- **认证**: OAuth, Bearer Token, 无认证
- **内置支持**: Craft (32+ 文档工具), Linear, GitHub, Notion 等
- **本地 MCP**: Stdio 方式运行 npx/Python/任意二进制

### F3.2 REST API 源
- **认证方式**: Bearer, Header, Query, Basic, OAuth, None
- **OAuth 提供商**: Google (Gmail/Calendar/Drive/YouTube), Microsoft, Slack
- **通用 OAuth**: 自定义 authorizationUrl/tokenUrl/clientId
- **动态工具**: 从配置自动生成 API 调用工具
- **API 探测**: GET 请求在 Explore 模式下始终允许

### F3.3 本地源
- **文件系统**: 连接本地目录
- **Obsidian Vault**: 支持 Obsidian 笔记库
- **Git 仓库**: 连接版本控制仓库

### F3.4 源管理
- **连接测试**: 验证源是否可达
- **OAuth Token 刷新**: 自动刷新过期的 OAuth 令牌
- **源连接状态**: connected, needs_auth, failed, untested, local_disabled
- **大响应处理**: 超过 ~60KB 的工具响应自动摘要

---

## F4: 技能系统 (Skills)

- **工作区级存储**: 每个工作区独立的技能目录
- **Markdown 格式**: 技能以 Markdown 文件存储
- **动态加载**: 通过 @提及即时激活技能
- **导入**: 支持从 Claude Code 导入技能
- **Agent 创建**: 通过自然语言描述让 Agent 创建新技能

---

## F5: 自动化 (Automations)

### F5.1 事件类型
- LabelAdd / LabelRemove
- PermissionModeChange
- FlagChange
- SessionStatusChange
- SchedulerTick (Cron)
- PreToolUse / PostToolUse
- SessionStart / SessionEnd

### F5.2 触发条件
- **Cron 表达式**: 定时触发（如 `0 9 * * 1-5` 工作日 9 点）
- **标签匹配**: 正则表达式匹配标签名
- **事件匹配**: 监听特定事件类型

### F5.3 动作类型
- **Prompt**: 创建新 Agent 会话并执行提示
- **环境变量**: 自动展开 `$CRAFT_LABEL`, `$CRAFT_SESSION_ID` 等
- **@提及**: 动作中支持 @source 和 @skill

---

## F6: 权限系统

### F6.1 权限模式
| 模式 | UI 名称 | 行为 |
|------|---------|------|
| `safe` | Explore | 只读模式，允许 Read/Glob/Grep/Task/WebFetch/WebSearch/LSP |
| `ask` | Ask to Edit | 默认模式，危险操作前请求审批 |
| `allow-all` | Auto | 自动批准所有操作 |

### F6.2 Bash 安全验证
- **AST 分析**: 使用 `bash-parser` 解析 Bash 命令 AST
- **阻止危险操作**: 重定向 (>/>>/</|)、替换 ($()/``/<()/>())、后台 (&)
- **复合命令**: 所有子命令都必须匹配只读模式
- **PowerShell 支持**: Windows 上的 PowerShell 验证

### F6.3 自定义权限配置
- `allowedBashPatterns`: 允许的 Bash 命令模式
- `allowedMcpPatterns`: 允许的 MCP 工具模式
- `allowedApiEndpoints`: 允许的 API 端点
- `allowedWritePaths`: 允许写入的路径
- `blockedTools`: 阻止的工具列表
- `blockedCommandHints`: 阻止的命令提示

### F6.4 特殊权限
- **安全模式写入例外**: `plansFolderPath` 和 `dataFolderPath` 即使在安全模式也允许写入
- **权限切换**: SHIFT+TAB 快速切换模式

---

## F7: 多 LLM 连接

### F7.1 支持的提供商
| 提供商 | 认证方式 | 后端 |
|--------|----------|------|
| Anthropic | API Key / Claude Max OAuth | Claude Agent SDK |
| Google AI Studio | API Key | Pi SDK |
| ChatGPT Plus | Codex OAuth | Pi SDK |
| GitHub Copilot | Device Code OAuth | Pi SDK |
| OpenAI | API Key | Pi SDK |
| OpenRouter | API Key + 自定义端点 | Claude Agent SDK |
| Ollama | 无需 API Key (本地) | Claude Agent SDK |
| 自定义 | 任意 URL | Claude Agent SDK |

### F7.2 连接管理
- **多连接**: 支持添加多个 LLM 连接
- **工作区默认**: 每个工作区可设置默认连接
- **连接锁定**: 会话首条消息后锁定连接，防止中途切换
- **模型刷新**: 定期从提供商获取可用模型列表（Anthropic 每 60 分钟）
- **离线回退**: 持久化模型列表 → 硬编码 MODEL_REGISTRY

### F7.3 Thinking 模式
- 级别: `off` | `low` | `medium` | `high` | `max`
- 工作区级和会话级配置

---

## F8: 工作区管理

### F8.1 工作区结构
```
~/.craft-agent/
├── config.json              # 全局配置
├── credentials.enc          # 加密凭据
├── preferences.json         # 用户偏好
├── theme.json               # 应用级主题
└── workspaces/{id}/
    ├── config.json          # 工作区配置
    ├── theme.json           # 工作区主题覆盖
    ├── automations.json     # 自动化规则
    ├── sessions/            # 会话数据 (JSONL)
    ├── sources/             # 连接的源
    ├── skills/              # 自定义技能
    ├── labels/              # 标签配置
    └── statuses/            # 状态配置
```

### F8.2 工作区配置
- **默认设置**: 模型、权限模式、思考级别、颜色主题
- **可循环模式**: 配置 SHIFT+TAB 切换的模式列表
- **工作目录**: Agent 的工作目录
- **源默认**: 工作区默认启用的源列表

---

## F9: 状态与标签

### F9.1 状态系统
- **内置状态**: todo, in-progress, needs-review, done, cancelled
- **类别**: `open` (Inbox) / `closed` (Archive)
- **自定义状态**: 可配置颜色、图标、排序
- **默认状态**: 新会话的初始状态

### F9.2 标签系统
- **层级标签**: 支持树形结构的标签
- **自动标签规则**: 基于条件自动添加标签
- **标签过滤**: 会话列表按标签筛选
- **批量操作**: 多选会话批量修改标签/状态

---

## F10: 主题系统

- **级联主题**: 应用级 → 工作区级，工作区覆盖应用设置
- **颜色主题**: 亮色/暗色/系统跟随
- **桌面平台适配**: macOS Vibrancy, Windows Mica/Acrylic, Linux 原生

---

## F11: 远程服务器

### F11.1 无头服务器
- **WebSocket RPC**: 自定义二进制协议
- **Bearer Token 认证**: 客户端连接需要 Token
- **TLS 支持**: PEM 证书加密 (wss://)
- **PID 锁文件**: 防止重复实例

### F11.2 瘦客户端模式
- **桌面端**: Electron 作为瘦客户端连接远程服务器
- **Web UI**: 浏览器通过 Cookie 认证连接
- **会话中继**: 断线重连 + 事件回放

### F11.3 Docker 部署
- **一键部署**: `docker run` 命令
- **数据卷**: 持久化 `~/.craft-agent` 数据
- **TLS 挂载**: 证书文件只读挂载

---

## F12: 多平台客户端

### F12.1 桌面应用 (Electron)
- **三栏布局**: 侧边栏 + 导航列表 + 内容面板
- **多面板**: VS Code 风格的水平分割面板
- **导航系统**: URL 作为唯一真相源，支持浏览器前进/后退
- **快捷键**: Cmd+N 新建, Cmd+1/2/3 聚焦, Cmd+/ 快捷键列表
- **深度链接**: `craftagents://` URL scheme
- **Deep Link 导航**: 外部应用跳转到特定会话/设置

### F12.2 Web UI
- **Cookie 认证**: 登录页面 → Session Cookie
- **完整功能**: 共享桌面应用的全部聊天功能
- **PWA**: 可安装的 Web 应用体验
- **i18n**: 多语言支持

### F12.3 CLI 客户端
- **WebSocket RPC**: 连接远程服务器
- **自包含运行**: `run` 命令自动启动服务器
- **多提供商**: `--provider` 指定 LLM 提供商
- **流式输出**: 文本或 JSON 流式输出
- **验证套件**: 30+ 步集成测试

### F12.4 会话查看器
- **只读分享**: 上传 JSON 文件或通过 URL 分享
- **隐私优先**: 本地处理，不上传数据
- **工具预览**: 代码/终端/JSON/Markdown 多种预览模式

## 待确认项

| ID | 内容 | 置信度 | 建议操作 |
|----|------|--------|----------|
| TC-301 | 计划系统的用户交互细节 | ⚠️ [待确认] | 确认 Accept & Compact 流程 |
| TC-302 | 自定义权限配置的用户界面 | ⚠️ [待确认] | 确认是否提供 GUI 配置 |
| TC-303 | 自动化的事件覆盖完整性 | ⚠️ [待确认] | 确认所有事件类型是否完备 |
