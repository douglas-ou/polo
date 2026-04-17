---
id: llm.connection
module: llm
type: domain
priority: 1
status: pending
estimatedMinutes: 20
dependencies: [enterprise.loader]
---
# Create Enterprise LLM Connection

## Description
Implement `createEnterpriseConnection(config: EnterpriseConfig)` in the enterprise module that creates a single locked `LlmConnection` from enterprise config. This connection is created automatically at startup, is not editable/deletable by users, is the only available connection, and is not shown in settings UI.

## Environment Context
- Key file: `packages/shared/src/config/llm-connections.ts` (existing LlmConnection logic)
- LlmConnection type defined in packages/shared/src/ or packages/core/
- Claude Agent SDK: `@anthropic-ai/claude-agent-sdk`
- Test strategy: Mix (unit mock, integration real)

## Input/Output Types
```typescript
Input: EnterpriseConfig { endpoint, apiKey, defaultModel, disabledTools? }
Output: LlmConnection {
  slug: 'enterprise-default',
  name: 'Enterprise AI',
  providerType: 'anthropic',
  authType: 'api_key_with_endpoint',
  baseUrl: string,
  defaultModel: string,
  locked: true  // not editable/deletable
}
```

## Acceptance Criteria
1. `createEnterpriseConnection()` returns valid LlmConnection from EnterpriseConfig
2. Connection has slug 'enterprise-default', name 'Enterprise AI'
3. Connection is marked as locked (not editable, not deletable)
4. `providerType` is 'anthropic', `authType` is 'api_key_with_endpoint'

## Test Cases (Red Phase)
- TEST: createEnterpriseConnection(validConfig) → { slug: 'enterprise-default', name: 'Enterprise AI', providerType: 'anthropic' }
- TEST: createEnterpriseConnection returns baseUrl === config.endpoint
- TEST: createEnterpriseConnection returns defaultModel === config.defaultModel
- TEST: createEnterpriseConnection returns locked === true
- TEST: createEnterpriseConnection with different endpoints → different baseUrl values
- TEST: Connection object cannot be mutated to change slug (frozen or readonly)
