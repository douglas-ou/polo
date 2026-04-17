# 05 - 系统架构

## 架构概览

Craft Agents 采用 **Monorepo + 分层架构** 设计，分为 Foundation、Business Logic、Server Infrastructure、Application 四层。

```mermaid
graph TB
    subgraph "Application Layer"
        ELECTRON["Electron Desktop<br/>@craft-agent/electron"]
        WEBUI["Web UI<br/>@craft-agent/webui"]
        CLI["CLI Client<br/>@craft-agent/cli"]
        VIEWER["Session Viewer<br/>@craft-agent/viewer"]
    end

    subgraph "Server Infrastructure"
        SERVER["Headless Server<br/>@craft-agent/server"]
        SERVERCORE["Server Core<br/>@craft-agent/server-core"]
        MCPSERVER["Session MCP Server<br/>@craft-agent/session-mcp-server"]
        PISERVER["Pi Agent Server<br/>@craft-agent/pi-agent-server"]
    end

    subgraph "Business Logic"
        SHARED["Shared Logic<br/>@craft-agent/shared"]
        TOOLSCORE["Session Tools Core<br/>@craft-agent/session-tools-core"]
    end

    subgraph "Foundation"
        CORE["Core Types<br/>@craft-agent/core"]
        UI["UI Components<br/>@craft-agent/ui"]
    end

    subgraph "External"
        CLAUDE["Claude Agent SDK"]
        PISDK["Pi SDK"]
        MCP["MCP SDK"]
        ELECTRONSYS["Electron Runtime"]
    end

    ELECTRON --> SERVERCORE
    ELECTRON --> SHARED
    ELECTRON --> UI
    WEBUI --> UI
    CLI --> SHARED
    CLI --> SERVERCORE
    VIEWER --> UI

    SERVER --> SERVERCORE
    SERVERCORE --> SHARED
    SHARED --> CORE
    SHARED --> TOOLSCORE
    MCPSERVER --> TOOLSCORE
    MCPSERVER --> SHARED
    PISERVER --> PISDK

    SHARED --> CLAUDE
    SHARED --> PISDK
    SHARED --> MCP
    ELECTRON --> ELECTRONSYS
```

## 核心数据流

### 消息处理流程

```mermaid
sequenceDiagram
    participant U as User (Desktop/Web/CLI)
    participant T as WebSocket Transport
    participant SM as SessionManager
    participant AB as Agent Backend
    participant LLM as LLM Provider
    participant MCP as MCP/API Sources

    U->>T: SEND_MESSAGE RPC
    T->>SM: sendMessage()
    SM->>SM: Lazy load messages
    SM->>SM: Create user message
    SM-->>T: user_message event
    T-->>U: Push event

    SM->>AB: getOrCreateAgent()
    AB->>AB: Build source servers
    AB->>AB: Setup MCP pool

    SM->>AB: agent.chat()
    AB->>LLM: API call (streaming)

    loop Streaming Events
        LLM-->>AB: text_delta / tool_use
        AB-->>SM: processEvent()
        SM-->>T: Push events
        T-->>U: Real-time updates

        alt Tool Call
            AB->>MCP: Execute tool
            MCP-->>AB: Tool result
            AB->>LLM: Continue with result
        end
    end

    LLM-->>AB: Complete
    AB-->>SM: Processing complete
    SM->>SM: Persist session
    SM-->>T: Complete event
    T-->>U: Session updated
```

### WebSocket RPC 协议

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server

    C->>S: handshake {protocolVersion, auth, channels}
    S->>C: handshake_ack {clientId, channels}

    rect rgb(240, 248, 255)
        Note over C,S: Normal RPC
        C->>S: request {channel, method, params}
        S->>C: response {result}
    end

    rect rgb(255, 248, 240)
        Note over C,S: Server Push
        S->>C: event {seq, type, data}
        C->>S: sequence_ack {lastSeq}
    end

    rect rgb(240, 255, 240)
        Note over C,S: Reconnection
        C->>S: handshake {reconnectClientId, lastSeq}
        S->>S: Replay buffered events
        S->>C: handshake_ack + replayed events
    end
```

## 模块职责

### packages/core — 基础类型
| 职责 | 内容 |
|------|------|
| 类型定义 | Workspace, Session, Message, Attachment, Annotation 等所有核心类型 |
| 枚举 | SessionStatus, MessageRole, ErrorCode, PermissionRequestType 等 |
| 工具函数 | debug 日志, 路径工具 |
| 无依赖 | 不依赖任何内部包，纯类型包 |

### packages/shared — 核心业务逻辑
| 模块 | 职责 |
|------|------|
| `agent/` | Agent 后端抽象 (Claude/Pi)、权限管理、提示构建 |
| `auth/` | OAuth 流程 (Claude/Google/Microsoft/Slack/ChatGPT) |
| `config/` | 全局配置、LLM 连接、主题、存储迁移 |
| `credentials/` | AES-256-GCM 加密凭据管理 |
| `labels/` | 层级标签系统 + 自动标签规则 |
| `mcp/` | MCP 客户端池，集中管理所有 MCP 连接 |
| `protocol/` | WebSocket RPC 协议类型 |
| `sessions/` | 会话持久化 (JSONL)，类型定义 |
| `sources/` | 源存储、类型、API 工具构建器 |
| `statuses/` | 可配置会话状态系统 |
| `workspaces/` | 工作区存储和类型 |

### packages/server-core — 服务器基础设施
| 模块 | 职责 |
|------|------|
| `transport/` | WebSocket RPC 服务器、协议编解码、事件推送 |
| `bootstrap/` | 服务器启动流程 (PID锁、Token验证、Handler注册) |
| `handlers/` | RPC 通道处理器 (sessions, sources, skills 等) |
| `sessions/` | SessionManager — 会话生命周期、Agent 管理、消息处理 |
| `model-fetchers/` | 多提供商模型列表刷新服务 |
| `webui/` | Web UI HTTP 处理器 |

### apps/electron — 桌面应用
| 层 | 职责 |
|-----|------|
| `main/` | Electron 主进程：窗口管理、IPC、浏览器自动化、托盘 |
| `preload/` | Context Bridge：WebSocket RPC 客户端 + OAuth 流程 |
| `renderer/` | React UI：三栏布局、会话列表、聊天界面、设置页面 |

## Agent 后端架构

```mermaid
graph LR
    subgraph "Agent Backend Abstraction"
        FACTORY["Backend Factory"]
    end

    subgraph "Claude Backend"
        CLAUDE_AGENT["ClaudeAgent"]
        CLAUDE_SDK["Claude Agent SDK"]
        CLAUDE_PROC["Subprocess"]
    end

    subgraph "Pi Backend"
        PI_AGENT["PiAgent"]
        PI_SDK["Pi SDK"]
        PI_PROC["Subprocess (JSONL)"]
    end

    FACTORY -->|providerType: anthropic| CLAUDE_AGENT
    FACTORY -->|providerType: pi/pi_compat| PI_AGENT

    CLAUDE_AGENT --> CLAUDE_SDK
    CLAUDE_SDK --> CLAUDE_PROC
    PI_AGENT --> PI_SDK
    PI_SDK --> PI_PROC

    CLAUDE_PROC -->|supports| ANTHROPIC["Anthropic API"]
    CLAUDE_PROC -->|supports| OPENROUTER["OpenRouter"]
    CLAUDE_PROC -->|supports| OLLAMA["Ollama"]

    PI_PROC -->|supports| GOOGLE["Google AI Studio"]
    PI_PROC -->|supports| CODEX["ChatGPT/Codex"]
    PI_PROC -->|supports| COPILOT["GitHub Copilot"]
    PI_PROC -->|supports| OPENAI["OpenAI API"]
```

## MCP 客户端池架构

```mermaid
graph TB
    SM["SessionManager"]

    subgraph "MCP Client Pool"
        POOL["McpClientPool"]
        MCP1["MCP Client 1<br/>(Craft Docs)"]
        MCP2["MCP Client 2<br/>(Linear)"]
        MCP3["MCP Client 3<br/>(Custom)"]
    end

    subgraph "API Source Servers"
        API1["Google Gmail"]
        API2["Slack"]
    end

    subgraph "Local Sources"
        LOCAL1["Filesystem"]
        LOCAL2["Obsidian"]
    end

    SM --> POOL
    POOL --> MCP1
    POOL --> MCP2
    POOL --> MCP3
    SM --> API1
    SM --> API2
    SM --> LOCAL1
    SM --> LOCAL2

    MCP1 -.->|HTTP/SSE/Stdio| EXTERNAL1["External MCP Server"]
    MCP2 -.->|HTTP/SSE/Stdio| EXTERNAL2["External MCP Server"]
```

## 前端状态管理

```mermaid
graph TB
    subgraph "Jotai Atoms"
        SESSION["sessionAtomFamily(id)"]
        META["sessionMetaMapAtom"]
        IDS["sessionIdsAtom"]
        LOADED["loadedSessionsAtom"]
        PANEL["panelStackAtom"]
        SOURCES["sourcesAtom"]
        SKILLS["skillsAtom"]
    end

    subgraph "React Components"
        APP["App.tsx"]
        SHELL["AppShell"]
        LIST["SessionList"]
        CHAT["ChatDisplay"]
        SETTINGS["Settings"]
    end

    APP --> META
    APP --> IDS
    SHELL --> PANEL
    LIST --> META
    LIST --> IDS
    CHAT --> SESSION
    CHAT --> LOADED
    SETTINGS --> SOURCES
    SETTINGS --> SKILLS
```

## 待确认项

| ID | 内容 | 置信度 | 建议操作 |
|----|------|--------|----------|
| TC-501 | MCP 客户端池的连接数上限 | ⚠️ [待确认] | 确认并发 MCP 连接限制 |
| TC-502 | 消息处理的吞吐量限制 | ⚠️ [待确认] | 确认高并发场景下的性能 |
