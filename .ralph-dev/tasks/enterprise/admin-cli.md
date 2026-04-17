---
id: enterprise.admin-cli
module: enterprise
type: domain
priority: 2
status: pending
estimatedMinutes: 25
dependencies: [enterprise.encryption]
---
# Admin CLI Tool: polo-enterprise-encrypt

## Description
Create `tools/enterprise-encrypt.ts` CLI tool for admins to generate encrypted `enterprise.enc` files. Supports both direct CLI arguments and reading from a JSON file. Validates input before encryption.

## Environment Context
- Run via: `npx polo-enterprise-encrypt` or `bun run tools/enterprise-encrypt.ts`
- Depends on: enterprise.encryption (encrypt), enterprise.types (validation)
- Args: --endpoint, --api-key, --default-model, --disabled-tools (comma-separated), --input (JSON file), --output
- Test strategy: Mix (unit mock, integration real)
- Test runner: `bun test`

## Acceptance Criteria
1. CLI accepts `--endpoint`, `--api-key`, `--default-model`, `--disabled-tools`, `--output` args
2. CLI accepts `--input config.json` as alternative to individual args
3. Validates config before encrypting (same rules as EnterpriseConfig validation)
4. Writes encrypted file to `--output` path
5. Prints success message with output path on completion
6. Exits with code 1 on validation error, with descriptive error message

## Test Cases (Red Phase)
- TEST: `npx polo-enterprise-encrypt --endpoint https://proxy.com --api-key key123 --default-model claude-sonnet-4-20250514 --output /tmp/test.enc` → creates file, exit 0
- TEST: Created file starts with "POLO01\0" header bytes
- TEST: `npx polo-enterprise-encrypt --input config.json --output /tmp/test.enc` → reads JSON, creates file
- TEST: `npx polo-enterprise-encrypt` (no args) → exit 1, error "missing required arguments"
- TEST: `npx polo-enterprise-encrypt --endpoint not-a-url --api-key key --default-model model --output /tmp/test.enc` → exit 1, validation error
- TEST: `npx polo-enterprise-encrypt --endpoint https://proxy.com --api-key key --default-model model --disabled-tools "shell,write_file" --output /tmp/test.enc` → creates file with disabledTools
- TEST: Decrypt output of CLI → matches input config exactly
- TEST: `npx polo-enterprise-encrypt --input nonexistent.json --output /tmp/test.enc` → exit 1, error "file not found"
