---
id: llm.remove-cloud-auth
module: llm
type: domain
priority: 2
status: pending
estimatedMinutes: 15
dependencies: [setup.branch]
---
# Remove Cloud Provider Auth Types

## Description
Remove Bedrock IAM credentials (`authType: 'iam_credentials'`) and GCP Vertex service account (`authType: 'service_account'`) from LlmConnection types and related code. Enterprise uses a single proxy endpoint, not cloud provider auth.

## Environment Context
- Update: LlmConnection type definitions in packages/shared or packages/core
- Remove: any Bedrock/Vertex-specific connection creation code
- Test strategy: Mix (unit mock, integration real)

## Acceptance Criteria
1. `authType: 'iam_credentials'` removed from types
2. `authType: 'service_account'` removed from types
3. Related Bedrock/Vertex connection code removed
4. `bun run build` succeeds

## Test Cases (Red Phase)
- TEST: `grep -r "iam_credentials" packages/shared/src/ packages/core/src/` → 0 matches
- TEST: `grep -r "service_account" packages/shared/src/ packages/core/src/` → 0 matches (except unrelated contexts)
- TEST: `grep -r "authType.*bedrock\|authType.*vertex" --include="*.ts"` → 0 matches
- TEST: `bun run build` → succeeds
