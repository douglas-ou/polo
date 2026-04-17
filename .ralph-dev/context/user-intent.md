# User Intent Record

## Source
- Extracted from: `.prddocs/enterprise-edition-spec.md` (8-round structured interview)
- Timestamp: 2026-04-18

## Original Request

> Transform **Craft Agents** (codebase: `polo`) into **Polo AI**, an enterprise-internal AI agent desktop application with pre-configured API connections. Users receive a ready-to-use application without any API key setup required.

## Core Principles

1. **One LLM provider**: Internal proxy/gateway (e.g., LiteLLM Proxy) that implements Anthropic Messages API
2. **Zero user configuration for LLM**: All API credentials are pre-configured by administrators
3. **Per-user credentials**: Each employee receives a unique API key via individual config files
4. **Unified build**: Same application binary for all employees; differentiation via config files only

## Constraints

- Create an independent branch: `polo-enterprise` (separate from upstream open-source version)
- Full freedom to modify/remove code without upstream compatibility concerns
- Chinese language for error messages shown to end users (IT department contact references)
- NOT changing internal code variable names, npm package names (unless published externally)

## Codebase Reality Check
- Root package name: `craft-agent` v0.8.6
- `packages/shared/src/config/config.ts` does NOT exist (config is split across multiple files)
- `packages/shared/src/credentials/secure-storage.ts` does NOT exist (credentials module has manager.ts, backends/, etc.)
- Auth files live in `packages/shared/src/auth/` (not `src/auth/` as spec suggests)
