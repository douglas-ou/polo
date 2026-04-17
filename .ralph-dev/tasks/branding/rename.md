---
id: branding.rename
module: branding
type: domain
priority: 1
status: pending
estimatedMinutes: 25
dependencies: [setup.branch]
---
# Rename Branding: Craft Agents → Polo AI

## Description
Replace all user-facing references to "Craft Agents" with "Polo AI" throughout the codebase. This includes package.json product names, Electron window titles, menu items, tray icon labels, error messages, CLI help text, and server startup messages. Do NOT change internal variable names or npm package names.

## Environment Context
- Build: Bun monorepo (TypeScript + React + Electron)
- Test runner: `bun test`
- Key files: root package.json, apps/electron/package.json, apps/cli/, apps/viewer/, packages/server/
- Test strategy: Mix (unit mock, integration real)

## Acceptance Criteria
1. `productName` in Electron config shows "Polo AI"
2. Window titles display "Polo AI"
3. Menu items and tray icon labels show "Polo AI"
4. CLI help text and prompts reference "Polo AI"
5. Headless server startup messages show "Polo AI"
6. Error messages reference "Polo AI" where user-facing
7. Internal code variable names are unchanged
8. `grep -ri "craft.agent" --include="*.ts" --include="*.tsx"` returns no user-facing results (only internal/package references)

## Test Cases (Red Phase)
- TEST: Search for "Craft Agents" in user-facing strings → 0 matches
- TEST: Search for "Craft Agent" in user-facing strings → 0 matches
- TEST: Electron productName in package.json → "Polo AI"
- TEST: Window title renders "Polo AI"
- TEST: `grep -ri "craft.agent" apps/` returns no user-visible strings (only internal identifiers)
- TEST: Server startup log message contains "Polo AI"
- TEST: CLI --help output contains "Polo AI"
