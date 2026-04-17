---
id: llm.remove-pi
module: llm
type: domain
priority: 2
status: pending
estimatedMinutes: 20
dependencies: [setup.branch]
---
# Remove Pi SDK Server and Related Code

## Description
Delete the entire `packages/pi-agent-server/` directory and remove all Pi-related code: Pi agent code in `packages/shared/src/agent/`, Pi provider types (`providerType: 'pi'` and `'pi_compat'`) from LlmConnection types, and any Pi-specific dependencies.

## Environment Context
- Delete: `packages/pi-agent-server/` (entire package)
- Update: root package.json (remove workspace references to pi-agent-server build scripts)
- Dependencies to remove: `@mariozechner/pi-ai`, `@mariozechner/pi-coding-agent`
- Test strategy: Mix (unit mock, integration real)

## Acceptance Criteria
1. `packages/pi-agent-server/` directory no longer exists
2. No imports reference `pi-agent-server` or `pi-ai` packages
3. `providerType: 'pi'` and `'pi_compat'` removed from LlmConnection types
4. Pi-related test files removed or updated
5. `bun run build` succeeds after removal

## Test Cases (Red Phase)
- TEST: `ls packages/pi-agent-server/` → directory does not exist
- TEST: `grep -r "pi-agent-server" --include="*.ts" --include="*.json"` → 0 matches
- TEST: `grep -r "pi-ai" --include="*.ts" --include="*.json"` → 0 matches (except node_modules)
- TEST: `grep -r "providerType.*pi" packages/shared/src/` → 0 matches
- TEST: `bun run build` → succeeds
