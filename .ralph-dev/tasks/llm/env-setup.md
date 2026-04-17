---
id: llm.env-setup
module: llm
type: domain
priority: 1
status: pending
estimatedMinutes: 15
dependencies: [llm.connection]
---
# Set LLM Environment Variables from Enterprise Config

## Description
Implement `configureEnterpriseEnvironment(config: EnterpriseConfig)` that sets `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` environment variables from enterprise config. This ensures the Claude Agent SDK routes all requests through the enterprise proxy.

## Environment Context
- Claude Agent SDK reads ANTHROPIC_BASE_URL and ANTHROPIC_API_KEY env vars
- Key file: `packages/shared/src/agent/claude-agent.ts`
- Must run before any agent initialization

## Acceptance Criteria
1. `ANTHROPIC_BASE_URL` set to enterprise config endpoint
2. `ANTHROPIC_API_KEY` set to enterprise config apiKey
3. Both env vars available to child processes (agent server, session processes)

## Test Cases (Red Phase)
- TEST: configureEnterpriseEnvironment(config) → process.env.ANTHROPIC_BASE_URL === config.endpoint
- TEST: configureEnterpriseEnvironment(config) → process.env.ANTHROPIC_API_KEY === config.apiKey
- TEST: configureEnterpriseEnvironment overwrites existing ANTHROPIC_BASE_URL
- TEST: configureEnterpriseEnvironment overwrites existing ANTHROPIC_API_KEY
- TEST: After configure, agent SDK initialization uses proxy endpoint
