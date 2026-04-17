---
id: integration.startup
module: integration
type: domain
priority: 1
status: pending
estimatedMinutes: 20
dependencies: [enterprise.loader, llm.connection, llm.env-setup, tools.blacklist]
---
# Wire Enterprise Config into Electron Startup

## Description
Integrate enterprise config loading into the Electron main process startup sequence. On app start: load enterprise.enc → decrypt & validate → create LlmConnection → set env vars → apply tool blacklist. On any config failure, show a dialog with the Chinese error message and exit.

## Environment Context
- Key file: `apps/electron/src/main/index.ts`
- Electron dialog API for error messages
- Flow: loadEnterpriseConfig() → createEnterpriseConnection() → configureEnterpriseEnvironment() → filterTools()
- Error handling: Electron dialog.showMessageBox() → app.exit()

## Acceptance Criteria
1. Electron main process calls loadEnterpriseConfig() early in startup
2. On success: connection created, env vars set, tool blacklist applied
3. On failure: Chinese error dialog shown, app exits after dismiss
4. Startup flow: config load → connection → env vars → UI init

## Test Cases (Red Phase)
- TEST: Electron starts with valid enterprise.enc → proceeds to main UI
- TEST: Electron starts without enterprise.enc → shows dialog "未检测到企业配置文件" → exits on dismiss
- TEST: Electron starts with corrupt enterprise.enc → shows dialog "企业配置文件已损坏" → exits
- TEST: After successful startup, ANTHROPIC_BASE_URL is set to proxy endpoint
- TEST: After successful startup, agent tools respect disabledTools blacklist
- TEST: Startup sequence completes in <100ms for config operations
