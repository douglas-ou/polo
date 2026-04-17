---
id: docs.enterprise-setup
module: docs
type: domain
priority: 3
status: pending
estimatedMinutes: 20
dependencies: [enterprise.admin-cli]
---
# Enterprise Admin Setup Documentation

## Description
Create `docs/enterprise-setup.md` with comprehensive admin documentation covering: config file schema, field descriptions, example configurations for common proxy setups (LiteLLM, etc.), deployment instructions, and key rotation procedures.

## Environment Context
- Admin CLI: `npx polo-enterprise-encrypt`
- Config location: `~/.polo-ai/enterprise.enc`
- Encryption: AES-256-GCM with ENTERPRISE_CONFIG_KEY

## Acceptance Criteria
1. Config file schema documented with all fields
2. At least 2 example configurations (LiteLLM proxy, direct Anthropic)
3. Step-by-step deployment instructions
4. Key rotation procedure documented
5. Error troubleshooting section

## Test Cases (Red Phase)
- TEST: Document exists at `docs/enterprise-setup.md`
- TEST: Document covers all 4 EnterpriseConfig fields (endpoint, apiKey, defaultModel, disabledTools)
- TEST: Document includes CLI usage examples
- TEST: Document includes deployment steps
- TEST: Document includes key rotation section
