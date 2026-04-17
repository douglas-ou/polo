---
id: ui.remove-model-select
module: ui
type: ui
priority: 2
status: pending
estimatedMinutes: 15
dependencies: [setup.branch]
---
# Remove Model/Connection Selection from Workspace Dialog

## Description
Remove model selection and connection picker steps from the new workspace dialog. Enterprise users get the fixed default model from enterprise config automatically — no choice needed.

## Environment Context
- Key component: New workspace dialog in renderer
- Model/connection selection is part of workspace creation flow
- Enterprise default model applied automatically

## Acceptance Criteria
1. New workspace dialog has no model/connection selection step
2. Workspace automatically uses enterprise default model
3. No provider/LLM connection dropdown in workspace creation

## Test Cases (Red Phase)
- TEST: New workspace dialog renders → no model selection dropdown
- TEST: New workspace dialog renders → no connection picker
- TEST: Created workspace uses enterprise defaultModel
- TEST: `grep -r "model.*select\|connection.*picker" apps/electron/src/renderer/` → 0 matches in workspace dialog
