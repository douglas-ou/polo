---
id: llm.remove-claude-oauth
module: llm
type: domain
priority: 2
status: pending
estimatedMinutes: 15
dependencies: [setup.branch]
---
# Remove Claude OAuth Code

## Description
Remove Claude OAuth files since enterprise uses the proxy, not personal subscriptions. Delete `claude-oauth.ts`, `claude-oauth-config.ts`, and `claude-token.ts`. Remove Claude Max/Pro support and Claude-related LlmConnection auth types.

## Environment Context
- Delete: `packages/shared/src/auth/claude-oauth.ts`, `claude-oauth-config.ts`, `claude-token.ts`
- Keep: Anthropic API key auth (enterprise uses this via proxy)
- Update: auth/index.ts exports, auth/types.ts
- Test strategy: Mix (unit mock, integration real)

## Acceptance Criteria
1. Claude OAuth files deleted
2. No Claude OAuth flow imports remain
3. Claude token handling removed
4. `bun run build` succeeds

## Test Cases (Red Phase)
- TEST: `ls packages/shared/src/auth/claude-oauth*.ts` → files do not exist
- TEST: `ls packages/shared/src/auth/claude-token.ts` → file does not exist
- TEST: `grep -r "claude-oauth" --include="*.ts"` → 0 matches
- TEST: `grep -r "claude-token" --include="*.ts"` → 0 matches
- TEST: `bun run build` → succeeds
