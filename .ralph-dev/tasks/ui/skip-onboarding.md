---
id: ui.skip-onboarding
module: ui
type: ui
priority: 2
status: pending
estimatedMinutes: 15
dependencies: [enterprise.loader]
---
# Skip Onboarding for Enterprise Users

## Description
When enterprise config is loaded successfully, skip the onboarding wizard entirely and proceed directly to the main UI (or workspace selector if no workspace exists). The onboarding wizard component can remain in codebase but is never shown.

## Environment Context
- Key component: OnboardingWizard in renderer
- Key file: `apps/electron/src/renderer/App.tsx` (routing/startup logic)
- Enterprise config presence = skip onboarding

## Acceptance Criteria
1. When enterprise config loaded → no onboarding screen shown
2. App goes directly to main UI or workspace selector
3. OnboardingWizard component code can remain but is never rendered

## Test Cases (Red Phase)
- TEST: App startup with enterprise config → renders main UI, not onboarding wizard
- TEST: App startup with enterprise config + no workspace → renders workspace selector
- TEST: OnboardingWizard component not in DOM when enterprise config present
- TEST: grep for onboarding skip logic → condition checks for enterprise config
