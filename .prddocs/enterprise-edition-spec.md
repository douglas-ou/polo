# Polo AI Enterprise Edition - Specification

> Generated: 2026-04-14
> Status: Draft
> Based on: 8-round structured interview

---

## 1. Overview

Transform **Craft Agents** (codebase: `polo`) into **Polo AI**, an enterprise-internal AI agent desktop application with pre-configured API connections. Users receive a ready-to-use application without any API key setup required.

### 1.1 Core Principle

- **One LLM provider**: Internal proxy/gateway (e.g., LiteLLM Proxy) that implements Anthropic Messages API
- **Zero user configuration for LLM**: All API credentials are pre-configured by administrators
- **Per-user credentials**: Each employee receives a unique API key via individual config files
- **Unified build**: Same application binary for all employees; differentiation via config files only

### 1.2 Code Management Strategy

- Create an independent branch: `polo-enterprise`
- Separate from upstream open-source version
- Full freedom to modify/remove code without upstream compatibility concerns

---

## 2. Branding Changes

| Before | After |
|--------|-------|
| Craft Agents | **Polo AI** |
| `~/.craft-agent/` | `~/.polo-ai/` |
| App identifiers, titles, menus | All references to "Craft Agents" replaced with "Polo AI" |

### 2.1 Scope of Rebranding

- Application name in Electron (`productName`, `name` in package.json)
- Window titles, menu items, tray icon labels
- Data directory paths (`~/.polo-ai/`)
- Error messages and user-facing strings
- CLI help text and prompts
- Headless server startup messages
- **NOT changing**: internal code variable names, npm package names (unless published externally)

---

## 3. Enterprise Configuration System

### 3.1 Configuration File

**Location**: `~/.polo-ai/enterprise.enc`

**Format**: JSON, AES-256-GCM encrypted with a hardcoded application key

**Minimal Schema**:

```jsonc
{
  // Required: Proxy server endpoint (Anthropic Messages API compatible)
  "endpoint": "https://llm-proxy.internal.company.com",

  // Required: User-specific API key for the proxy
  "apiKey": "user-abc123-key",

  // Required: Fixed default model for all sessions
  "defaultModel": "claude-sonnet-4-20250514",

  // Optional: List of tool names to disable (blacklist)
  // If absent or empty, all tools are allowed
  "disabledTools": ["shell", "write_file"]
}
```

### 3.2 Encryption

- **Algorithm**: AES-256-GCM (consistent with existing credential storage)
- **Key**: Hardcoded in source code (`ENTERPRISE_CONFIG_KEY` constant)
- **File format**: Binary with header `POLO01\0`, followed by: salt (16 bytes), IV (12 bytes), auth tag (16 bytes), encrypted JSON payload
- **Key derivation**: PBKDF2 with the hardcoded key, 100,000 iterations

### 3.3 Admin Tooling

Provide a CLI command for admins to generate encrypted config files:

```bash
# Usage:
npx polo-enterprise-encrypt \
  --endpoint "https://llm-proxy.internal.company.com" \
  --api-key "user-abc123-key" \
  --default-model "claude-sonnet-4-20250514" \
  --disabled-tools "shell,write_file" \
  --output "./enterprise.enc"

# Or from a plain JSON file:
npx polo-enterprise-encrypt --input config.json --output enterprise.enc
```

Include documentation (README or Markdown guide) covering:
- Config file schema and field descriptions
- Example configurations for common proxy setups
- Deployment instructions (where to place the file)
- Key rotation procedures

### 3.4 Startup Behavior

**When `enterprise.enc` is found**:
1. Decrypt and parse the config file
2. Create an internal LLM connection with the proxy endpoint and API key
3. Skip onboarding entirely
4. Proceed directly to main UI (or workspace selector if no workspace exists)

**When `enterprise.enc` is NOT found**:
1. Display dialog: "未检测到企业配置文件，请联系 IT 部门获取配置文件并放置在 ~/.polo-ai/enterprise.enc"
2. Exit application after user dismisses dialog

---

## 4. LLM Connection Architecture

### 4.1 Backend Selection

- **Keep**: Claude Agent SDK (`@anthropic-ai/claude-agent-sdk`)
- **Mechanism**: Set `ANTHROPIC_BASE_URL` to the proxy endpoint from enterprise config
- **Authentication**: Set `ANTHROPIC_API_KEY` to the user-specific key from enterprise config

### 4.2 Remove Non-Anthropic Code

The following components must be **completely removed** from the codebase:

| Component | Package/Path | Reason |
|-----------|-------------|--------|
| Pi SDK backend | `packages/pi-agent-server/`, Pi-related code in `packages/shared/src/agent/` | Not needed for single Anthropic proxy |
| OpenAI connections | LlmConnection entries for OpenAI, OpenRouter, etc. | Replaced by proxy |
| GitHub Copilot OAuth | `src/auth/copilot.ts`, Copilot device code flow | Replaced by proxy |
| ChatGPT/Codex OAuth | `src/auth/chatgpt.ts` | Replaced by proxy |
| Claude OAuth | `src/auth/claude.ts`, Claude Max/Pro support | Enterprise uses proxy, not personal subscriptions |
| Pi provider types | `providerType: 'pi'` and `'pi_compat'` in LlmConnection | Not needed |
| Bedrock IAM | `authType: 'iam_credentials'` in LlmConnection | Not needed |
| GCP Vertex | `authType: 'service_account'` in LlmConnection | Not needed |
| API key input UI | `ApiKeyInput.tsx` with preset selectors | Users never configure APIs |
| OAuth connect UI | `OAuthConnect.tsx` for LLM providers | Users never configure LLM OAuth |
| Onboarding wizard | `OnboardingWizard` component | Users never configure APIs |
| AI Settings page | `AiSettingsPage.tsx` | Users cannot modify LLM settings |

### 4.3 Model Management

- **Default model**: Fixed from enterprise config (`defaultModel` field)
- **Model list**: Dynamic fetch from proxy endpoint's `GET /v1/models` on startup
- **Model selection**: Users **cannot** switch models; all sessions use the configured default
- **Thinking mode**: Admin sets a default in config (if applicable), but users **can adjust** thinking budget within a session

### 4.4 LLM Connection Internal Representation

The enterprise config creates a single internal `LlmConnection`:

```typescript
{
  slug: 'enterprise-default',
  name: 'Enterprise AI',
  providerType: 'anthropic',
  authType: 'api_key_with_endpoint',
  baseUrl: '<endpoint from enterprise.enc>',
  defaultModel: '<defaultModel from enterprise.enc>',
  // No user-visible configuration
}
```

This connection is:
- Created automatically at startup from enterprise config
- Not editable or deletable by users
- The only LLM connection available
- Not shown in any settings UI

---

## 5. Tool Blacklist

### 5.1 Mechanism

- Admin specifies `disabledTools` array in enterprise config
- **Blacklist model**: All tools enabled by default; only listed tools are disabled
- If `disabledTools` is absent or empty, all tools are enabled
- Tool names map to the internal tool identifiers used by the Claude Agent SDK

### 5.2 Common Tool Identifiers

```typescript
// Examples of tool names that can be disabled:
"read_file"        // Read file contents
"write_file"       // Write/modify files
"search_files"     // Grep/ripgrep search
"list_directory"   // List directory contents
"shell"            // Execute shell commands (Bash tool)
"web_fetch"        // Fetch web content
"web_search"       // Web search
"lsp"              // Language Server Protocol operations
```

### 5.3 Enforcement Point

Tool blacklist is enforced at the agent tool registration layer. When the ClaudeAgent initializes, it filters out tools whose names appear in `disabledTools`. The agent never sees these tools, so the LLM cannot request them.

---

## 6. UI Changes

### 6.1 Remove

| Component | Location | Action |
|-----------|----------|--------|
| Onboarding Wizard | `OnboardingWizard.tsx` | Delete, skip entirely |
| AI Settings Page | `AiSettingsPage.tsx` | Delete, remove from navigation |
| API Key Input | `ApiKeyInput.tsx` | Delete |
| OAuth Connect (LLM) | `OAuthConnect.tsx` | Delete LLM-specific OAuth UI |
| LLM Connection List | Settings sidebar | Remove "AI" section from settings |
| Provider selector | Onboarding/settings | Delete |
| Add Connection dialog | Settings | Delete |

### 6.2 Modify

| Component | Change |
|-----------|--------|
| Settings navigation | Remove "AI" / "LLM" settings section entirely |
| Main app title | Change "Craft Agents" → "Polo AI" |
| About dialog | Update branding |
| Status bar indicators | Show "Connected to Enterprise AI" instead of provider name |
| Error messages | Replace "API key" references with "enterprise configuration" language |
| New workspace dialog | Remove model/connection selection steps |

### 6.3 Keep Unchanged

| Component | Reason |
|-----------|--------|
| Sources management (MCP, REST APIs) | Users still configure their own integrations |
| OAuth for external services (Slack, Google, Microsoft) | Users still connect their own accounts |
| Session management | Core feature, unchanged |
| Workspace management | Core feature, unchanged |
| Skill editor | Users still create custom skills |
| Automation rules | Users still create automations |
| Permission modes (Safe/Ask/Allow All) | Keep all three modes |
| Auto-update mechanism | Keep electron-updater as-is |
| Background tasks | Core feature, unchanged |

---

## 7. Application Components

### 7.1 Components to Keep (All)

| Component | Path | Status |
|-----------|------|--------|
| Electron desktop app | `apps/electron/` | Keep, apply all changes |
| CLI client | `apps/cli/` | Keep, update branding + config loading |
| Headless server | `packages/server/`, `packages/server-core/` | Keep, update config loading |
| Viewer app | `apps/viewer/` | Keep, update branding |

### 7.2 Shared Packages

| Package | Path | Action |
|---------|------|--------|
| `core` | `packages/core/` | Update types (remove non-Anthropic provider types) |
| `shared` | `packages/shared/` | Major changes: enterprise config loader, remove Pi SDK, update LLM connection logic |
| `ui` | `packages/ui/` | Remove AI settings components, update branding |
| `server` | `packages/server/` | Update for enterprise config |
| `server-core` | `packages/server-core/` | Update for enterprise config |
| `session-mcp-server` | `packages/session-mcp-server/` | Minor updates |
| `session-tools-core` | `packages/session-tools-core/` | Update tool blacklist filtering |
| `pi-agent-server` | `packages/pi-agent-server/` | **Delete entirely** |

---

## 8. Data Directory Migration

### 8.1 Path Changes

| Before | After |
|--------|-------|
| `~/.craft-agent/` | `~/.polo-ai/` |
| `~/.craft-agent/config.json` | `~/.polo-ai/config.json` |
| `~/.craft-agent/credentials.enc` | `~/.polo-ai/credentials.enc` |
| `~/.craft-agent/preferences.json` | `~/.polo-ai/preferences.json` |
| `~/.craft-agent/workspaces/` | `~/.polo-ai/workspaces/` |
| N/A (new) | `~/.polo-ai/enterprise.enc` |

### 8.2 Migration

Since this is an independent branch (not upgrading existing users), no automatic migration is needed. The enterprise branch starts fresh with `~/.polo-ai/`.

---

## 9. Configuration Reference

### 9.1 Enterprise Config Schema

```typescript
interface EnterpriseConfig {
  /** Proxy server base URL (Anthropic Messages API compatible) */
  endpoint: string;

  /** User-specific API key for proxy authentication */
  apiKey: string;

  /** Default model ID for all sessions */
  defaultModel: string;

  /** Tool names to disable (blacklist). Optional, defaults to [] */
  disabledTools?: string[];
}
```

### 9.2 Validation Rules

| Field | Rule |
|-------|------|
| `endpoint` | Required. Must be valid HTTPS URL (or HTTP for localhost) |
| `apiKey` | Required. Non-empty string |
| `defaultModel` | Required. Non-empty string matching a model ID pattern |
| `disabledTools` | Optional. Array of valid tool name strings |

### 9.3 Error Handling

- **File not found**: Show dialog, exit application
- **Decryption failure**: Show "企业配置文件已损坏，请联系 IT 重新获取", exit
- **JSON parse error**: Show "企业配置文件格式错误，请联系 IT", exit
- **Missing required fields**: Show "企业配置文件缺少必要字段 [field]，请联系 IT", exit
- **Invalid endpoint URL**: Show "企业配置文件中的服务地址无效，请联系 IT", exit
- **Proxy unreachable**: Keep existing error handling (generic API error display)

---

## 10. Key Files to Modify

### 10.1 New Files

| File | Purpose |
|------|---------|
| `packages/shared/src/enterprise/config.ts` | Enterprise config types, loader, validator |
| `packages/shared/src/enterprise/encryption.ts` | AES-256-GCM encrypt/decrypt for enterprise.enc |
| `packages/shared/src/enterprise/tool-filter.ts` | Tool blacklist enforcement |
| `tools/enterprise-encrypt.ts` | CLI tool for admins to generate enterprise.enc |
| `docs/enterprise-setup.md` | Admin setup documentation |

### 10.2 Major Modifications

| File | Change |
|------|--------|
| `apps/electron/src/main/index.ts` | Load enterprise config at startup, exit if missing |
| `packages/shared/src/config/config.ts` | Support `~/.polo-ai/` directory, enterprise config |
| `packages/shared/src/config/llm-connections.ts` | Enterprise creates single locked connection |
| `packages/shared/src/agent/claude-agent.ts` | Apply tool blacklist, use enterprise config |
| `packages/shared/src/credentials/secure-storage.ts` | Update for `~/.polo-ai/` path |
| `apps/electron/src/renderer/App.tsx` | Skip onboarding, hide AI settings |
| `apps/electron/src/renderer/pages/settings/` | Remove AI settings page |
| `apps/electron/src/renderer/components/apisetup/` | Delete entire directory |
| `package.json` (root + apps) | Update name, description, product name |

### 10.3 Files to Delete

| Path | Reason |
|------|--------|
| `packages/pi-agent-server/` | Entire Pi SDK server package |
| `apps/electron/src/renderer/components/apisetup/` | API setup UI components |
| `apps/electron/src/renderer/pages/settings/AiSettingsPage.tsx` | AI settings page |
| Related Pi/OpenAI/Copilot auth files in `src/auth/` | Non-Anthropic auth providers |

---

## 11. Build & Distribution

### 11.1 Build Process

1. Checkout `polo-enterprise` branch
2. Build Electron app with standard `bun run build`
3. Distribute the same binary to all employees
4. Admin generates per-user `enterprise.enc` files using the CLI tool
5. Each employee receives their `enterprise.enc` file (via IT deployment, email, or shared drive)
6. Employee places file at `~/.polo-ai/enterprise.enc`
7. App starts, reads config, connects to proxy

### 11.2 Config File Lifecycle

- **Creation**: Admin runs `npx polo-enterprise-encrypt` for each user
- **Distribution**: Admin sends file to user via secure channel
- **Placement**: User (or IT script) copies to `~/.polo-ai/enterprise.enc`
- **Rotation**: Admin generates new file, user replaces the old one, app re-reads on next restart
- **Revocation**: User deletes the file (or admin provides an empty/invalid one)

---

## 12. Summary of Decisions

| Decision Area | Choice |
|---------------|--------|
| LLM Provider | Single: internal proxy/gateway |
| SDK Backend | Claude Agent SDK (via ANTHROPIC_BASE_URL) |
| Proxy Auth | User-level API keys |
| Config Format | JSON + AES-256-GCM encrypted file |
| Encryption Key | Hardcoded in source code |
| Config Location | `~/.polo-ai/enterprise.enc` |
| Key Distribution | Per-user config files, generated by admin |
| Admin Tooling | CLI encrypt command + documentation |
| Model Selection | Fixed default, dynamic list from proxy |
| Thinking Mode | Admin default + user adjustable |
| Tool Control | Blacklist (disable specific tools) |
| Onboarding | Skip entirely |
| AI Settings UI | Completely hidden |
| OAuth Integrations | Keep user-configurable (Slack, Google, etc.) |
| MCP Servers | Keep user-configurable |
| Permission Modes | Keep all three (Safe/Ask/Allow All) |
| Auto-Update | Keep existing mechanism |
| Missing Config | Show dialog, exit |
| Branding | Rename to "Polo AI" |
| Data Directory | `~/.polo-ai/` |
| Non-Anthropic Code | Remove entirely |
| Claude OAuth | Remove |
| Code Strategy | Independent branch `polo-enterprise` |
| App Components | Keep all (Electron, CLI, Server, Viewer) |
