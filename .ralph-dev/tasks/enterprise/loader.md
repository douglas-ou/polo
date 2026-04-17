---
id: enterprise.loader
module: enterprise
type: domain
priority: 1
status: pending
estimatedMinutes: 20
dependencies: [enterprise.encryption, branding.paths]
---
# Load and Validate Enterprise Config at Startup

## Description
Implement `loadEnterpriseConfig()` in `packages/shared/src/enterprise/config.ts` that reads, decrypts, and validates `~/.polo-ai/enterprise.enc`. Returns a typed `EnterpriseConfig` or throws with Chinese-language error messages for all failure modes.

## Environment Context
- Config path: `~/.polo-ai/enterprise.enc` (from branding.paths)
- Depends on: enterprise.types (validation), enterprise.encryption (decrypt)
- Error messages in Chinese (end users are Chinese employees)
- Test strategy: Mix (unit mock, integration real)
- Test runner: `bun test`

## Acceptance Criteria
1. `loadEnterpriseConfig()` returns validated `EnterpriseConfig` on success
2. File not found → throws with "未检测到企业配置文件，请联系 IT 部门获取配置文件并放置在 ~/.polo-ai/enterprise.enc"
3. Decryption failure → throws with "企业配置文件已损坏，请联系 IT 重新获取"
4. JSON parse error → throws with "企业配置文件格式错误，请联系 IT"
5. Missing required fields → throws with "企业配置文件缺少必要字段 [{field}]，请联系 IT"
6. Invalid endpoint URL → throws with "企业配置文件中的服务地址无效，请联系 IT"

## Error Codes
| Error Condition | Chinese Message |
|----------------|-----------------|
| File not found | "未检测到企业配置文件，请联系 IT 部门获取配置文件并放置在 ~/.polo-ai/enterprise.enc" |
| Decrypt failure | "企业配置文件已损坏，请联系 IT 重新获取" |
| JSON parse error | "企业配置文件格式错误，请联系 IT" |
| Missing field | "企业配置文件缺少必要字段 [{field}]，请联系 IT" |
| Invalid endpoint | "企业配置文件中的服务地址无效，请联系 IT" |

## Test Cases (Red Phase)
- TEST: loadEnterpriseConfig() with valid encrypted file → returns { endpoint, apiKey, defaultModel }
- TEST: loadEnterpriseConfig() when file does not exist → throws with "未检测到企业配置文件"
- TEST: loadEnterpriseConfig() with corrupt encrypted file → throws with "企业配置文件已损坏"
- TEST: loadEnterpriseConfig() with valid encryption but invalid JSON → throws with "企业配置文件格式错误"
- TEST: loadEnterpriseConfig() with missing endpoint field → throws with "缺少必要字段 [endpoint]"
- TEST: loadEnterpriseConfig() with invalid endpoint URL → throws with "服务地址无效"
- TEST: loadEnterpriseConfig() with empty disabledTools → returns config with disabledTools=[]
- TEST: loadEnterpriseConfig() with disabledTools=["shell","write_file"] → returns config with both disabled
