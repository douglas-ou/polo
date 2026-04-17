# Referenced Files Index

## Source
- Extracted from: `.prddocs/enterprise-edition-spec.md` Sections 7, 10
- Verified against codebase: 2026-04-18

## New Files to Create

| File | Purpose |
|------|---------|
| `packages/shared/src/enterprise/config.ts` | Enterprise config types, loader, validator |
| `packages/shared/src/enterprise/encryption.ts` | AES-256-GCM encrypt/decrypt for enterprise.enc |
| `packages/shared/src/enterprise/tool-filter.ts` | Tool blacklist enforcement |
| `tools/enterprise-encrypt.ts` | CLI tool for admins to generate enterprise.enc |
| `docs/enterprise-setup.md` | Admin setup documentation |

## Major Modifications

| File (Spec Path) | Actual Path | Change |
|------------------|-------------|--------|
| `apps/electron/src/main/index.ts` | (exists) | Load enterprise config at startup, exit if missing |
| `packages/shared/src/config/config.ts` | `packages/shared/src/config/` (multiple files: index.ts, storage.ts, paths.ts, etc.) | Support `~/.polo-ai/` directory, enterprise config |
| `packages/shared/src/config/llm-connections.ts` | (exists) | Enterprise creates single locked connection |
| `packages/shared/src/agent/claude-agent.ts` | (exists) | Apply tool blacklist, use enterprise config |
| `packages/shared/src/credentials/secure-storage.ts` | `packages/shared/src/credentials/` (index.ts, manager.ts, types.ts, backends/) | Update for `~/.polo-ai/` path |
| `apps/electron/src/renderer/App.tsx` | (exists) | Skip onboarding, hide AI settings |
| `apps/electron/src/renderer/pages/settings/` | (exists - 12 files) | Remove AI settings page |
| `apps/electron/src/renderer/components/apisetup/` | (exists - 6 files) | Delete entire directory |
| `package.json` (root + apps) | (exists) | Update name, description, product name |

## Files/Directories to Delete

| Path | Reason |
|------|--------|
| `packages/pi-agent-server/` | Entire Pi SDK server package |
| `apps/electron/src/renderer/components/apisetup/` | API setup UI components (6 files) |
| `apps/electron/src/renderer/pages/settings/AiSettingsPage.tsx` | AI settings page |

## Auth Files to Remove (Non-Anthropic)

| File | Provider |
|------|----------|
| `packages/shared/src/auth/claude-oauth.ts` | Claude OAuth |
| `packages/shared/src/auth/claude-oauth-config.ts` | Claude OAuth config |
| `packages/shared/src/auth/claude-token.ts` | Claude token handling |
| `packages/shared/src/auth/chatgpt-oauth.ts` | ChatGPT OAuth |
| `packages/shared/src/auth/chatgpt-oauth-config.ts` | ChatGPT OAuth config |

## Auth Files to KEEP

| File | Provider |
|------|----------|
| `packages/shared/src/auth/google-oauth.ts` | External service OAuth (keep) |
| `packages/shared/src/auth/microsoft-oauth.ts` | External service OAuth (keep) |
| `packages/shared/src/auth/slack-oauth.ts` | External service OAuth (keep) |
| `packages/shared/src/auth/generic-oauth.ts` | Generic OAuth (keep) |
| `packages/shared/src/auth/oauth.ts` | Core OAuth infrastructure (keep) |
| `packages/shared/src/auth/pkce.ts` | PKCE (keep) |
| `packages/shared/src/auth/oauth-flow-store.ts` | Flow store (keep) |
| `packages/shared/src/auth/oauth-flow-types.ts` | Flow types (keep) |
| `packages/shared/src/auth/oauth-relay.ts` | Relay (keep) |
| `packages/shared/src/auth/callback-server.ts` | Callback server (keep) |
| `packages/shared/src/auth/callback-page.ts` | Callback page (keep) |
