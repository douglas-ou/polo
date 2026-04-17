# 11 - 技术债与重构建议

## 已识别技术债

### TD-1: 超大文件

| 文件 | 大小 | 问题 | 建议 |
|------|------|------|------|
| `SessionManager.ts` | ~300KB / ~6000+ 行 | 职责过多，维护困难 | 拆分为 SessionLifecycle, AgentFactory, MessageProcessor, SourceManager 等模块 |
| `AppShell.tsx` | ~166KB | 渲染逻辑过于集中 | 提取为独立的面板管理器、布局引擎、事件分发器 |
| `App.tsx` | ~2061 行 | 状态管理和生命周期混合 | 提取 useSessionManager, useEventProcessor 等 Custom Hooks |
| `NavigationContext.tsx` | ~1294 行 | 导航逻辑复杂 | 提取路由匹配、面板协调、URL 同步为独立模块 |

### TD-2: 启动迁移复杂度

**位置**: `packages/shared/src/config/`

**问题**: LLM 连接迁移链过长
```
Codex/Copilot → Pi
Bedrock/Vertex/anthropic_compat → Pi
Model backfills
Opus/Sonnet 4.5 → 4.6 upgrades
```

**建议**: 引入声明式迁移框架，每个迁移版本独立文件，支持回滚测试。

### TD-3: 双后端维护成本

**问题**: Claude Agent SDK 和 Pi SDK 两套后端，工具处理逻辑需要双倍维护。

**具体表现**:
- `session-tools-core` 定义工具 schema
- `session-mcp-server` 为 Codex 路径重新实现工具
- `pi-agent-server` 又一层代理转发

**建议**: 统一工具执行接口，后端只负责 LLM 通信差异。

### TD-4: 自定义 ESLint 规则

**位置**: `apps/electron/eslint-rules/`

共 8 条自定义规则：
- `no-direct-file-open` — 阻止直接 `shell.openPath`
- `no-direct-navigation-state` — 强制使用 NavigationContext
- `no-direct-platform-check` — 强制使用平台工具函数
- `no-hardcoded-path-separator` — 强制使用 `path.sep`
- `no-hardcoded-z-index` — 阻止硬编码 z-index
- `no-inline-source-auth-check` — 强制集中认证检查
- `no-localstorage` — 阻止使用 localStorage
- `no-nonstandard-shadows` — 统一阴影样式

**观察**: 这些规则反映了跨平台一致性问题。说明存在需要运行时强制执行的约定。

**建议**: 逐步将这些约束内化到共享工具函数中，减少对 lint 规则的依赖。

---

## 架构改进建议

### AI-1: 拆分 SessionManager

```
SessionManager (当前)
├── SessionLifecycle      # 创建/删除/归档/分支
├── AgentFactory          # Agent 后端创建和配置
├── MessageProcessor      # 消息收发和流式处理
├── SourceManager         # 源连接和 MCP 池管理
├── PersistenceManager    # JSONL 读写和队列
└── EventHandler          # 事件分发和推送
```

### AI-2: 统一工具执行管道

```
当前:
  Claude SDK → in-process handlers
  Pi SDK → session-mcp-server → subprocess
  Copilot → session-mcp-server → HTTP callback → main process

建议:
  ToolRegistry (统一注册)
    → ToolExecutor (统一执行)
      → BackendAdapter (Claude/Pi/Copilot 差异)
```

### AI-3: 前端状态管理优化

```
当前:
  App.tsx (2000+ 行状态管理)
  → AppShell.tsx (166KB 布局)

建议:
  hooks/
  ├── useSessionManager.ts
  ├── useEventProcessor.ts
  ├── useWorkspaceManager.ts
  └── useNavigation.ts
```

---

## 代码质量观察

### 正面
- **TypeScript 严格模式**: 全项目严格类型检查
- **Zod schema 验证**: 运行时 schema 验证
- **Monorepo 分层**: 清晰的依赖方向
- **自定义 lint 规则**: 强制代码规范
- **Husky 预提交钩子**: 自动化质量检查

### 待改进
- **测试覆盖率**: 缺少端到端测试
- **文档**: 缺少 API 文档和架构文档
- **错误处理**: 部分模块缺少统一错误处理
- **日志**: 生产环境日志策略不明确

---

## 依赖健康度

### 需要关注
| 依赖 | 版本 | 风险 |
|------|------|------|
| `@dnd-kit/dom` | `^0.4.0-beta` | Beta 版本，API 可能变化 |
| `zod` | `^4.0.0` | 大版本升级，需验证兼容性 |
| `electron` | `^39.2.7` | 需要跟进 Electron 更新 |

### 外部 SDK 依赖
- Claude Agent SDK (`^0.2.78`) — 版本号较小，API 可能不稳定
- Pi SDK (`^0.66.1`) — 第三方 SDK，更新频率未知
- GitHub Copilot SDK (`^0.1.23`) — 早期版本

## 待确认项

| ID | 内容 | 置信度 | 建议操作 |
|----|------|--------|----------|
| TC-1101 | SessionManager 拆分可行性 | ⚠️ [待确认] | 评估拆分风险和收益 |
| TC-1102 | 测试覆盖率目标 | ❌ [需人工确认] | 确认测试策略 |
| TC-1103 | 双后端统一计划 | ⚠️ [待确认] | 是否计划统一工具执行路径 |
