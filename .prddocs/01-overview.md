# 01 - 项目概述

## 产品名称

**Craft Agents** — AI Agent 桌面应用平台

## 一句话描述

Claude Code 风格的 AI Agent 桌面应用，面向文档工作流，支持多 LLM 提供商、多会话管理、MCP/API/本地源连接，提供桌面端、Web 端、CLI 端多种访问方式。

## 核心价值主张

1. **Agent Native 体验**: 用户通过自然语言描述需求，Agent 自主完成工具调用、代码执行、文件操作等任务
2. **文档优先工作流**: 区别于代码编辑器（如 Claude Code），Craft Agents 面向文档场景，支持 TipTap 富文本编辑
3. **多任务并行**: 多会话管理 + 后台任务执行，支持同时处理多个 Agent 任务
4. **即插即用连接**: 无需配置文件即可连接 MCP 服务器、REST API、本地文件系统
5. **跨平台部署**: 桌面端（Electron）、远程服务器（Docker/裸机）、Web UI、CLI 全覆盖

## 目标用户

| 用户类型 | 使用场景 |
|----------|----------|
| 知识工作者 | 使用 AI Agent 处理文档、邮件、日历等日常任务 |
| 开发者 | 使用 Agent 编写代码、管理项目、自动化 CI/CD |
| 团队协作 | 通过共享会话和远程服务器实现团队协作 |
| 运维人员 | 通过 CLI 和远程服务器管理 Agent 集群 |

## 技术栈概览

### 运行时与语言
- **运行时**: Bun (JavaScript/TypeScript 运行时)
- **语言**: TypeScript (严格模式)
- **Python**: 文档转换工具链 (PDF/DOCX/PPTX/XLSX/ICAL)

### 前端
- **框架**: React 18 + TypeScript
- **桌面**: Electron 39+
- **UI 组件**: shadcn/ui + Radix UI
- **样式**: Tailwind CSS v4
- **富文本编辑**: TipTap 3.20+
- **状态管理**: Jotai (原子化状态)
- **构建**: Vite 6 (渲染进程) + esbuild (主进程)

### 后端
- **AI SDK**: Claude Agent SDK (`@anthropic-ai/claude-agent-sdk`)
- **Pi SDK**: `@mariozechner/pi-coding-agent` (Google/OpenAI/Copilot)
- **通信协议**: WebSocket (自定义 RPC 协议)
- **加密**: AES-256-GCM (凭据存储)
- **MCP**: Model Context Protocol SDK

### 开发工具
- **包管理**: Bun workspaces (monorepo)
- **代码质量**: ESLint + TypeScript 严格模式 + Husky
- **测试**: Bun test + Python unittest
- **CI/CD**: GitHub Actions
- **监控**: Sentry

## 项目规模

| 指标 | 值 |
|------|------|
| 源文件总数 | ~1371 |
| Apps (应用) | 4 个 (Electron, CLI, WebUI, Viewer) |
| Packages (包) | 8 个 (core, shared, server, server-core 等) |
| 依赖包数量 | ~80+ 外部依赖 |
| 代码行数（估算） | ~200,000+ |

## 产品形态

| 形态 | 描述 | 部署方式 |
|------|------|----------|
| **桌面应用** | 主界面，Electron 打包 | macOS / Windows / Linux 安装包 |
| **远程服务器** | 无头服务器，WebSocket RPC | Docker / 裸机 / VPS |
| **Web UI** | 浏览器前端，连接远程服务器 | 嵌入服务器同一端口 |
| **CLI 客户端** | 终端工具，脚本自动化 | npm 全局安装 |
| **会话查看器** | 只读分享，隐私优先 | 静态站点 |

## 待确认项

| ID | 内容 | 置信度 | 建议操作 |
|----|------|--------|----------|
| TC-001 | 用户画像是否包含企业级用户 | ⚠️ [待确认] | 确认目标用户群体范围 |
| TC-002 | 移动端是否在规划中 | ⚠️ [待确认] | Web UI 的移动端适配程度 |
