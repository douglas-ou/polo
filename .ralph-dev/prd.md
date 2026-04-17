# Polo AI Enterprise Edition - Product Requirements Document

## Context Index (CRITICAL - Read These First After Compression)

> **Recovery Instructions**: If context was compressed, read these files in order:

| Priority | File | Contains |
|----------|------|----------|
| 1 | `.ralph-dev/context/user-intent.md` | User's exact requirements & codebase reality check |
| 2 | `.ralph-dev/context/files-referenced.md` | All file paths (new, modify, delete, keep) |
| 3 | `.ralph-dev/context/decisions.md` | Architecture decisions, error messages, test strategy |
| 4 | `.prddocs/enterprise-edition-spec.md` | Original 8-round interview spec (full detail) |

---

## 1. Project Overview

Transform **Craft Agents** (`craft-agent` v0.8.6) into **Polo AI**, an enterprise-internal AI agent desktop application with pre-configured API connections. Users receive a ready-to-use application without any API key setup required.

### 1.1 Core Principles

1. **One LLM provider**: Internal proxy/gateway (e.g., LiteLLM Proxy) implementing Anthropic Messages API
2. **Zero user configuration for LLM**: All API credentials pre-configured by administrators
3. **Per-user credentials**: Each employee receives a unique API key via individual encrypted config files
4. **Unified build**: Same binary for all employees; differentiation via config files only

### 1.2 Code Management

- Independent branch: `polo-enterprise` (created from current `main`)
- Separate from upstream open-source version
- Full freedom to modify/remove code without upstream compatibility concerns

---

## 2. Technical Stack

- **Language**: TypeScript (monorepo)
- **Framework**: React + Electron
- **Build**: Bun workspaces
- **Package Manager**: Bun
- **LLM SDK**: Claude Agent SDK (`@anthropic-ai/claude-agent-sdk`)
- **Encryption**: AES-256-GCM + PBKDF2 (Node.js `crypto`)
- **Test Framework**: Vitest (existing)
- **Verify Commands**: `npx tsc --noEmit`, `npm run lint`, `npm test`, `npm run build`

---

## 3. UI/UX Changes

### 3.1 Components to Remove

| Component | Location | Action |
|-----------|----------|--------|
| Onboarding Wizard | `OnboardingWizard.tsx` | Delete, skip entirely |
| AI Settings Page | `AiSettingsPage.tsx` | Delete, remove from navigation |
| API Key Input | `ApiKeyInput.tsx` | Delete |
| OAuth Connect (LLM) | `OAuthConnect.tsx` | Delete LLM-specific OAuth UI |
| LLM Connection List | Settings sidebar | Remove "AI" section from settings |
| Provider selector | Onboarding/settings | Delete |
| Add Connection dialog | Settings | Delete |
| API Setup components | `apps/electron/src/renderer/components/apisetup/` | Delete entire directory (6 files) |

### 3.2 Components to Modify

| Component | Change |
|-----------|--------|
| Settings navigation | Remove "AI" / "LLM" settings section entirely |
| Main app title | "Craft Agents" → "Polo AI" |
| About dialog | Update branding |
| Status bar indicators | Show "Connected to Enterprise AI" instead of provider name |
| Error messages | Replace "API key" references with "enterprise configuration" language |
| New workspace dialog | Remove model/connection selection steps |

### 3.3 Components to Keep Unchanged

- Sources management (MCP, REST APIs)
- OAuth for external services (Slack, Google, Microsoft)
- Session management, workspace management
- Skill editor, automation rules
- Permission modes (Safe/Ask/Allow All)
- Auto-update mechanism, background tasks

---

## 4. Data Model

### 4.1 Enterprise Configuration

**File**: `~/.polo-ai/enterprise.enc` (AES-256-GCM encrypted)

**Decrypted JSON Schema**:

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

**Validation Rules**:

| Field | Rule |
|-------|------|
| `endpoint` | Required. Valid HTTPS URL (or HTTP for localhost) |
| `apiKey` | Required. Non-empty string |
| `defaultModel` | Required. Non-empty string matching model ID pattern |
| `disabledTools` | Optional. Array of valid tool name strings |

### 4.2 Internal LLM Connection

```typescript
{
  slug: 'enterprise-default',
  name: 'Enterprise AI',
  providerType: 'anthropic',
  authType: 'api_key_with_endpoint',
  baseUrl: '<endpoint from enterprise.enc>',
  defaultModel: '<defaultModel from enterprise.enc>',
}
```

- Created automatically at startup
- Not editable or deletable by users
- The only LLM connection available
- Not shown in any settings UI

### 4.3 Encryption Format

- **Algorithm**: AES-256-GCM
- **Key**: `ENTERPRISE_CONFIG_KEY` env var with hardcoded fallback
- **Key derivation**: PBKDF2 with configured key, 100,000 iterations
- **Binary file format**: Header `POLO01\0` + salt(16 bytes) + IV(12 bytes) + authTag(16 bytes) + ciphertext

### 4.4 Data Directory

All paths change from `~/.craft-agent/` to `~/.polo-ai/`. No migration needed (fresh branch).

---

## 5. API Contracts

### 5.1 LLM Proxy Interaction

- **Mechanism**: Set `ANTHROPIC_BASE_URL` to proxy endpoint, `ANTHROPIC_API_KEY` to user-specific key
- **Model list**: Dynamic fetch from proxy's `GET /v1/models` on startup
- **Model selection**: Users cannot switch models; all sessions use configured default
- **Thinking mode**: Admin default + user adjustable within session

### 5.2 Admin CLI Tool

```bash
npx polo-enterprise-encrypt \
  --endpoint "https://llm-proxy.internal.company.com" \
  --api-key "user-abc123-key" \
  --default-model "claude-sonnet-4-20250514" \
  --disabled-tools "shell,write_file" \
  --output "./enterprise.enc"

# Or from plain JSON:
npx polo-enterprise-encrypt --input config.json --output enterprise.enc
```

---

## 6. User Flows

### 6.1 Application Startup

```
App starts
  ↓
Check ~/.polo-ai/enterprise.enc exists?
  ├─ NO  → Show dialog "未检测到企业配置文件..." → Exit on dismiss
  └─ YES → Decrypt & parse
            ├─ Decrypt fails → Show "企业配置文件已损坏..." → Exit
            ├─ Parse fails  → Show "企业配置文件格式错误..." → Exit
            ├─ Missing field → Show "企业配置文件缺少必要字段 [field]..." → Exit
            ├─ Invalid URL  → Show "企业配置文件中的服务地址无效..." → Exit
            └─ Valid → Create enterprise LlmConnection → Skip onboarding → Main UI
```

### 6.2 Normal Usage

- User opens app → Directly lands on main UI (no onboarding)
- Sessions use fixed default model
- Thinking mode adjustable per session
- MCP servers, external OAuth (Slack/Google), skills all work normally
- No AI settings visible anywhere

### 6.3 Config File Lifecycle

1. Admin generates per-user `enterprise.enc` via CLI tool
2. Admin distributes via secure channel
3. User places at `~/.polo-ai/enterprise.enc`
4. App reads on startup
5. Rotation: Admin generates new file, user replaces, app re-reads on restart

---

## 7. User Stories

### Epic 1: Branch Setup & Branding
- **US-1.1**: As a developer, I want to create the `polo-enterprise` branch so all enterprise work is isolated
- **US-1.2**: As a user, I want to see "Polo AI" branding throughout the application
- **US-1.3**: As a user, I want the app to use `~/.polo-ai/` for all data storage

### Epic 2: Enterprise Configuration System
- **US-2.1**: As an admin, I want to generate encrypted per-user config files via CLI
- **US-2.2**: As the application, I want to load and validate the enterprise config at startup
- **US-2.3**: As a user, I want clear Chinese-language error messages when config is missing or invalid

### Epic 3: LLM Connection Architecture
- **US-3.1**: As the application, I want to create a single locked LLM connection from enterprise config
- **US-3.2**: As a user, I want the app to connect to the enterprise proxy without any manual setup
- **US-3.3**: As a developer, I want all non-Anthropic LLM provider code removed from the codebase

### Epic 4: Tool Blacklist
- **US-4.1**: As an admin, I want to specify which tools are disabled per config file
- **US-4.2**: As the application, I want to enforce the tool blacklist at agent initialization

### Epic 5: UI Cleanup
- **US-5.1**: As a user, I want no AI/LLM settings visible in the UI
- **US-5.2**: As a user, I want to skip onboarding entirely and go straight to the main UI
- **US-5.3**: As a user, I want external service OAuth (Slack, Google, etc.) to still work normally

---

## 8. Design Decisions

> **Reference**: `.ralph-dev/context/decisions.md`

### Key Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| Branch | Create `polo-enterprise` from `main` first | Spec requirement: independent branch |
| Test strategy | Mix: unit mock, integration real | Balance speed with confidence |
| Encryption key | ENV var `ENTERPRISE_CONFIG_KEY` with hardcoded fallback | Allows key rotation without code changes |
| Tool control | Blacklist model | Simpler than whitelist; all tools enabled unless explicitly disabled |
| Model selection | Fixed default, no user switching | Enterprise control requirement |
| Onboarding | Skip entirely | No user configuration needed |
| Error messages | Chinese language with IT contact | End users are Chinese-speaking employees |
| Data directory | `~/.polo-ai/` (no migration) | Fresh branch, no existing users |
| Non-Anthropic code | Remove entirely | Only Anthropic proxy needed |

---

## 9. Non-Functional Requirements

### 9.1 Test Strategy
- **Unit tests**: Mock all external services (proxy, crypto) for speed and isolation
- **Integration tests**: Use real proxy endpoint when available
- **Coverage target**: Enterprise config system (encryption, validation, tool filter) should have >80% coverage

### 9.2 Security
- AES-256-GCM encryption with PBKDF2 (100K iterations)
- Per-user API keys (no shared credentials)
- Admin-only config generation
- Tool blacklist prevents LLM from accessing disabled capabilities

### 9.3 Performance
- Config decryption and validation should complete in <100ms
- App startup should not be noticeably slower than current version

### 9.4 Error Handling

| Error | User Message (Chinese) |
|-------|----------------------|
| File not found | "未检测到企业配置文件，请联系 IT 部门获取配置文件并放置在 ~/.polo-ai/enterprise.enc" |
| Decryption failure | "企业配置文件已损坏，请联系 IT 重新获取" |
| JSON parse error | "企业配置文件格式错误，请联系 IT" |
| Missing required fields | "企业配置文件缺少必要字段 [field]，请联系 IT" |
| Invalid endpoint URL | "企业配置文件中的服务地址无效，请联系 IT" |
| Proxy unreachable | Existing generic API error display |

---

## Appendix A: Original Spec

> **Source**: `.prddocs/enterprise-edition-spec.md`

The full 419-line enterprise edition specification document (8-round structured interview) is preserved at `.prddocs/enterprise-edition-spec.md`. It contains all detailed implementation guidance, file paths, schemas, and architectural decisions.

## Appendix B: User Intent Record

> **Source**: `.ralph-dev/context/user-intent.md`

> Transform **Craft Agents** (codebase: `polo`) into **Polo AI**, an enterprise-internal AI agent desktop application with pre-configured API connections. Users receive a ready-to-use application without any API key setup required.

## Appendix C: Referenced Files

> **Source**: `.ralph-dev/context/files-referenced.md`

- **5 new files** to create (enterprise config, encryption, tool-filter, admin CLI, docs)
- **9+ files** to modify (main index, config, llm-connections, agent, credentials, renderer, package.json)
- **3+ files/directories** to delete (pi-agent-server, apisetup/, AiSettingsPage.tsx)
- **5 auth files** to remove (claude/chatgpt OAuth)
- **11 auth files** to keep (google, microsoft, slack, generic OAuth + infrastructure)
