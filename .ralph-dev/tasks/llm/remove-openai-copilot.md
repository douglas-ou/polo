---
id: llm.remove-openai-copilot
module: llm
type: domain
priority: 2
status: pending
estimatedMinutes: 15
dependencies: [setup.branch]
---
# Remove OpenAI and Copilot Code

## Description
Remove OpenAI LLM connection entries, GitHub Copilot OAuth flow (`@github/copilot-sdk`), and ChatGPT OAuth code. Delete auth files for ChatGPT (`chatgpt-oauth.ts`, `chatgpt-oauth-config.ts`). Remove OpenAI-related provider types and LlmConnection configurations.

## Environment Context
- Delete: `packages/shared/src/auth/chatgpt-oauth.ts`, `chatgpt-oauth-config.ts`
- Remove dep: `@github/copilot-sdk`, `openai`
- Update: LlmConnection types (remove OpenAI/Copilot provider types)
- Keep: Google, Microsoft, Slack, Generic OAuth
- Test strategy: Mix (unit mock, integration real)

## Acceptance Criteria
1. `chatgpt-oauth.ts` and `chatgpt-oauth-config.ts` deleted
2. No imports of `@github/copilot-sdk` or `openai` in source code
3. OpenAI/Copilot provider types removed from LlmConnection
4. `bun run build` succeeds after removal

## Test Cases (Red Phase)
- TEST: `ls packages/shared/src/auth/chatgpt-oauth*.ts` → files do not exist
- TEST: `grep -r "@github/copilot-sdk" --include="*.ts"` → 0 matches
- TEST: `grep -r "chatgpt-oauth" --include="*.ts"` → 0 matches
- TEST: `grep -r "providerType.*openai" packages/shared/src/` → 0 matches
- TEST: `bun run build` → succeeds
