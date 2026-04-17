---
id: ui.remove-ai-settings
module: ui
type: ui
priority: 2
status: pending
estimatedMinutes: 20
dependencies: [setup.branch]
---
# Remove AI Settings Page and Navigation

## Description
Delete `AiSettingsPage.tsx`, remove the "AI" / "LLM" settings section from the settings sidebar navigation, remove the "Add Connection" dialog, and clean up related routes. Users cannot modify LLM settings in the enterprise version.

## Environment Context
- Delete: `apps/electron/src/renderer/pages/settings/AiSettingsPage.tsx`
- Update: Settings navigation/sidebar component (remove AI section)
- Update: Route definitions (remove AI settings route)
- Keep: All other settings pages (general, sources, etc.)
- Test strategy: Build verification

## Acceptance Criteria
1. AiSettingsPage.tsx deleted
2. No "AI" or "LLM" section in settings navigation
3. No route to AI settings page
4. Add Connection dialog removed
5. `bun run build` succeeds

## Test Cases (Red Phase)
- TEST: `ls apps/electron/src/renderer/pages/settings/AiSettingsPage.tsx` → file does not exist
- TEST: `grep -r "AiSettings\|ai-settings\|AiSettingsPage" --include="*.tsx" --include="*.ts"` → 0 matches in renderer
- TEST: Settings page renders without AI section → no "AI" tab/link visible
- TEST: `bun run electron:build` → succeeds
