---
id: integration.cli-server
module: integration
type: domain
priority: 2
status: pending
estimatedMinutes: 20
dependencies: [enterprise.loader, llm.env-setup, tools.blacklist]
---
# Update CLI and Headless Server for Enterprise Config

## Description
Update the CLI client (`apps/cli/`) and headless server (`packages/server/`, `packages/server-core/`) to load enterprise config at startup, set ANTHROPIC_BASE_URL and ANTHROPIC_API_KEY env vars, and apply tool blacklist. On missing config, print Chinese error message and exit with code 1.

## Environment Context
- CLI: `apps/cli/` — command-line interface
- Server: `packages/server/`, `packages/server-core/` — headless server
- Error output: stderr (no dialog in CLI/server mode)
- Test strategy: Mix (unit mock, integration real)

## Acceptance Criteria
1. CLI loads enterprise config before any agent operation
2. Headless server loads enterprise config on startup
3. Both set ANTHROPIC_BASE_URL and ANTHROPIC_API_KEY from config
4. Both apply tool blacklist
5. Missing config → print Chinese error to stderr, exit code 1

## Test Cases (Red Phase)
- TEST: CLI with valid enterprise.enc → sets env vars, proceeds normally
- TEST: CLI without enterprise.enc → stderr contains "未检测到企业配置文件", exit code 1
- TEST: CLI with corrupt enterprise.enc → stderr contains "已损坏", exit code 1
- TEST: Headless server with valid config → logs "Connected to Enterprise AI"
- TEST: Headless server without config → stderr error, exit code 1
- TEST: CLI respects disabledTools blacklist in agent tools
