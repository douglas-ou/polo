---
id: branding.paths
module: branding
type: domain
priority: 1
status: pending
estimatedMinutes: 20
dependencies: [setup.branch]
---
# Change Data Directory Paths: ~/.craft-agent/ → ~/.polo-ai/

## Description
Update all data directory references from `~/.craft-agent/` to `~/.polo-ai/`. This includes config paths, credential storage paths, workspace paths, and any hardcoded directory references. Since this is a fresh branch, no migration logic is needed.

## Environment Context
- Key files: `packages/shared/src/config/paths.ts`, `packages/shared/src/credentials/manager.ts`, `packages/shared/src/config/storage.ts`
- Config files: `config.json`, `credentials.enc`, `preferences.json`, `workspaces/`
- Test strategy: Mix (unit mock, integration real)

## Acceptance Criteria
1. All path constants reference `~/.polo-ai/` instead of `~/.craft-agent/`
2. Config, credentials, preferences, workspaces all use new path
3. New `enterprise.enc` path resolves to `~/.polo-ai/enterprise.enc`
4. No migration code needed (fresh branch)

## Test Cases (Red Phase)
- TEST: `getConfigDir()` returns path ending with `.polo-ai`
- TEST: `getCredentialsPath()` returns `~/.polo-ai/credentials.enc`
- TEST: `getPreferencesPath()` returns `~/.polo-ai/preferences.json`
- TEST: `getWorkspacesDir()` returns `~/.polo-ai/workspaces/`
- TEST: `getEnterpriseConfigPath()` returns `~/.polo-ai/enterprise.enc`
- TEST: `grep -r ".craft-agent" packages/shared/src/` returns 0 matches
- TEST: `grep -r ".craft-agent" apps/electron/src/` returns 0 matches
