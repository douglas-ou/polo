# 04 - 非功能需求

## NFR1: 性能

### NFR1.1 启动性能
- **冷启动**: 元数据仅加载 SessionHeader，消息懒加载
- **热启动**: 恢复上次工作区和会话状态
- **远程连接**: WebSocket 握手 + 断线重连 < 2 秒

### NFR1.2 运行时性能
- **流式响应**: Agent 响应实时流式传输，首 token 延迟取决于 LLM 提供商
- **消息持久化**: 异步队列 + 防抖，不阻塞 UI
- **会话列表**: 虚拟化渲染，支持数千会话不卡顿
- **Jotai 原子状态**: 单会话更新不触发其他会话重渲染

### NFR1.3 内存管理
- **无单体状态**: 避免 `sessionsAtom` 数组，使用 `sessionAtomFamily` 隔离
- **懒加载**: 消息按需加载，不使用的会话释放内存
- **图片处理**: 自动缩放大图，生成缩略图

### NFR1.4 网络性能
- **WebSocket 持久连接**: 避免频繁建立连接
- **事件缓冲**: 断线时服务端保留事件缓冲区，重连后回放
- **大响应摘要**: 工具响应 > 60KB 自动摘要

---

## NFR2: 安全

### NFR2.1 凭据安全
- **加密存储**: AES-256-GCM 加密文件存储
- **范围隔离**: `type::scope` 格式，LLM/工作区/源级隔离
- **环境变量过滤**: 本地 MCP 启动时过滤敏感环境变量
- **阻止列表**: ANTHROPIC_API_KEY, AWS_*, GITHUB_TOKEN 等自动过滤

### NFR2.2 传输安全
- **TLS**: 远程服务器支持 wss:// 加密连接
- **Token 认证**: Bearer Token 验证 + 熵检查
- **Cookie 认证**: Web UI 使用 HttpOnly Cookie

### NFR2.3 权限安全
- **Bash AST 验证**: 解析命令 AST 阻止危险操作
- **MCP 环境隔离**: 敏感环境变量不传递给子进程
- **权限模式**: 三级模式 (Explore/Ask/Auto) 控制操作范围

---

## NFR3: 可靠性

### NFR3.1 数据持久化
- **JSONL 格式**: 逐行写入，崩溃不丢失已写入消息
- **异步持久化队列**: 带防抖的异步写入
- **SessionHeader**: 预计算元数据，快速恢复

### NFR3.2 连接可靠性
- **心跳检测**: WebSocket ping/pong + 超时断开
- **断线重连**: 客户端身份匹配 + 事件回放
- **事件序列号**: 客户端确认序列号，服务端释放缓冲区

### NFR3.3 错误恢复
- **错误分类**: 22 种 ErrorCode 覆盖常见错误场景
- **恢复动作**: retry/settings/reauth/open_url/reconnect_source
- **OAuth 令牌刷新**: 自动刷新过期令牌 + 速率限制

---

## NFR4: 可扩展性

### NFR4.1 水平扩展
- **无状态服务器**: 服务器不持有全局状态，会话数据持久化到磁盘
- **多客户端**: 同一服务器支持多个 WebSocket 客户端同时连接
- **工作区隔离**: 每个工作区独立的数据目录

### NFR4.2 插件扩展
- **MCP 协议**: 通过 MCP 服务器扩展工具集
- **REST API**: 通过 API 源扩展外部服务连接
- **技能系统**: Markdown 格式的可扩展指令集
- **自动化事件**: 可编程的事件驱动工作流

---

## NFR5: 可维护性

### NFR5.1 代码组织
- **Monorepo**: 清晰的包分层 (Foundation → Business → Infrastructure → Application)
- **类型安全**: TypeScript 严格模式，Zod schema 运行时验证
- **ESLint 自定义规则**: 8 条自定义规则（如 no-hardcoded-z-index, no-direct-platform-check）

### NFR5.2 测试
- **单元测试**: Bun test (TypeScript) + Python unittest (工具链)
- **集成测试**: CLI 30+ 步验证套件
- **类型检查**: 全量 TypeScript 类型检查 (`typecheck:all`)

### NFR5.3 可观测性
- **Sentry 集成**: Electron + React 错误追踪
- **调试日志**: `CRAFT_DEBUG` 环境变量启用详细日志
- **日志文件**: 平台特定的日志路径

---

## NFR6: 跨平台兼容性

### NFR6.1 操作系统
| 平台 | 状态 | 特殊处理 |
|------|------|----------|
| macOS (ARM64/x64) | 完全支持 | Vibrancy 标题栏, 深度链接 |
| Windows (x64) | 完全支持 | Mica/Acrylic, PowerShell 验证 |
| Linux (ARM64/x64) | 完全支持 | 原生窗口框架 |

### NFR6.2 架构适配
- **Sharp**: 多平台二进制 (@img/sharp-{platform}-{arch})
- **esbuild**: 跨平台构建
- **Electron Builder**: 多平台打包

---

## NFR7: 国际化 (i18n)

- **框架**: i18next + react-i18next
- **浏览器检测**: 自动检测浏览器语言
- **动态加载**: 按需加载语言包
- **覆盖范围**: UI 文本、错误消息、状态名称

---

## NFR8: 可访问性

- **键盘导航**: 完整快捷键系统 (Cmd+N, Cmd+1/2/3, Shift+Tab 等)
- **Radix UI**: 基于 Radix 的可访问组件库
- **ARIA**: Radix 组件内置 ARIA 支持
- **命令面板**: 类似 VS Code 的命令面板快速操作

## 待确认项

| ID | 内容 | 置信度 | 建议操作 |
|----|------|--------|----------|
| TC-401 | 性能基准测试数据 | ❌ [需人工确认] | 缺少实际性能指标 |
| TC-402 | 国际化支持语言列表 | ⚠️ [待确认] | 确认已翻译的语言 |
| TC-403 | 可访问性合规等级 | ⚠️ [待确认] | 确认 WCAG 合规目标 |
