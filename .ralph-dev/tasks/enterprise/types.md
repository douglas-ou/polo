---
id: enterprise.types
module: enterprise
type: domain
priority: 1
status: pending
estimatedMinutes: 15
dependencies: [setup.branch]
---
# Define EnterpriseConfig Types and Validation

## Description
Create `packages/shared/src/enterprise/config.ts` with the EnterpriseConfig TypeScript interface and a Zod validation schema. This is the foundation for all enterprise config loading and validation.

## Environment Context
- Existing deps: `zod@^4.0.0` (available for validation)
- Key deps: TypeScript strict mode, `@/*` path alias
- Test strategy: Mix (unit mock, integration real)
- Test runner: `bun test`

## Acceptance Criteria
1. `EnterpriseConfig` interface defined with `endpoint`, `apiKey`, `defaultModel`, `disabledTools?`
2. Zod schema validates all fields with proper rules
3. Exported `validateEnterpriseConfig()` function returns typed result or error details
4. Exported `ENTERPRISE_CONFIG_PATH` constant for `~/.polo-ai/enterprise.enc`

## Test Cases (Red Phase)
- TEST: validateEnterpriseConfig({ endpoint: "https://proxy.example.com", apiKey: "key123", defaultModel: "claude-sonnet-4-20250514" }) → valid
- TEST: validateEnterpriseConfig({ endpoint: "https://proxy.example.com", apiKey: "key123", defaultModel: "claude-sonnet-4-20250514", disabledTools: ["shell"] }) → valid with disabledTools=["shell"]
- TEST: validateEnterpriseConfig({ endpoint: "", apiKey: "key", defaultModel: "model" }) → error "endpoint required"
- TEST: validateEnterpriseConfig({ endpoint: "not-a-url", apiKey: "key", defaultModel: "model" }) → error "invalid endpoint URL"
- TEST: validateEnterpriseConfig({ endpoint: "https://proxy.example.com", apiKey: "", defaultModel: "model" }) → error "apiKey required"
- TEST: validateEnterpriseConfig({ endpoint: "https://proxy.example.com", apiKey: "key", defaultModel: "" }) → error "defaultModel required"
- TEST: validateEnterpriseConfig({ endpoint: "http://localhost:3000", apiKey: "key", defaultModel: "model" }) → valid (HTTP allowed for localhost)
- TEST: validateEnterpriseConfig({}) → multiple validation errors
- TEST: validateEnterpriseConfig({ ..., disabledTools: "not-array" }) → error "disabledTools must be array"
