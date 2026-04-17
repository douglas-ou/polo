---
id: ui.status-bar
module: ui
type: ui
priority: 2
status: pending
estimatedMinutes: 10
dependencies: [llm.connection]
---
# Update Status Bar and Error Messages

## Description
Update the status bar indicator to show "Connected to Enterprise AI" instead of provider name. Replace "API key" references in error messages with "enterprise configuration" language.

## Environment Context
- Key component: Status bar in renderer
- Error messages throughout the app
- Enterprise connection name: "Enterprise AI"

## Acceptance Criteria
1. Status bar shows "Connected to Enterprise AI" when connected
2. Error messages reference "enterprise configuration" not "API key"
3. About dialog shows "Polo AI" branding

## Test Cases (Red Phase)
- TEST: Status bar renders → shows "Connected to Enterprise AI" text
- TEST: `grep -r "API key" apps/electron/src/renderer/ --include="*.tsx"` → 0 user-facing matches (only internal)
- TEST: About dialog → displays "Polo AI" name
- TEST: Error message for connection failure → contains "企业配置" or "enterprise" language
