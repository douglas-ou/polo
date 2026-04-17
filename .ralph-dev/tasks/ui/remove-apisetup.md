---
id: ui.remove-apisetup
module: ui
type: ui
priority: 2
status: pending
estimatedMinutes: 15
dependencies: [setup.branch]
---
# Delete API Setup Components

## Description
Delete the entire `apps/electron/src/renderer/components/apisetup/` directory and remove all imports/references to these components from the codebase. These components are no longer needed since users never configure APIs.

## Environment Context
- Delete: `apps/electron/src/renderer/components/apisetup/` (6 files)
- Update: any components importing from apisetup/
- Test strategy: Build verification

## Acceptance Criteria
1. `apps/electron/src/renderer/components/apisetup/` directory deleted
2. No imports reference apisetup components
3. `bun run build` succeeds

## Test Cases (Red Phase)
- TEST: `ls apps/electron/src/renderer/components/apisetup/` → directory does not exist
- TEST: `grep -r "apisetup" --include="*.ts" --include="*.tsx"` → 0 matches
- TEST: `grep -r "ApiKeyInput\|OAuthConnect" --include="*.tsx"` → 0 matches in renderer
- TEST: `bun run electron:build` → succeeds
