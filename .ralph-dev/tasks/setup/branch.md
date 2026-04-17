---
id: setup.branch
module: setup
type: domain
priority: 1
status: pending
estimatedMinutes: 5
dependencies: []
---
# Create polo-enterprise Branch

## Description
Create the `polo-enterprise` git branch from current `main`. This is the foundation for all enterprise work, providing isolation from the upstream open-source version.

## Environment Context
- Build: Bun monorepo (TypeScript + React + Electron)
- Test runner: `bun test`
- Verify: `npx tsc --noEmit && npm run lint && npm test && npm run build`

## Acceptance Criteria
1. `polo-enterprise` branch exists and is checked out
2. Branch is based on current `main` HEAD

## Test Cases (Red Phase)
- TEST: `git branch --show-current` outputs "polo-enterprise"
- TEST: `git log --oneline -1` matches main's latest commit
