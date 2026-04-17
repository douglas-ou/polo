---
id: enterprise.encryption
module: enterprise
type: domain
priority: 1
status: pending
estimatedMinutes: 25
dependencies: [enterprise.types]
---
# Implement Enterprise Config Encryption

## Description
Create `packages/shared/src/enterprise/encryption.ts` with AES-256-GCM encrypt/decrypt functions for enterprise.enc files. Uses PBKDF2 key derivation with ENTERPRISE_CONFIG_KEY env var (hardcoded fallback). Binary file format: `POLO01\0` header + salt(16) + IV(12) + authTag(16) + ciphertext.

## Environment Context
- Node.js crypto module (built-in, no external dep)
- Key: ENTERPRISE_CONFIG_KEY env var with hardcoded fallback
- Algorithm: AES-256-GCM
- Key derivation: PBKDF2, 100,000 iterations
- Test strategy: Mix (unit mock, integration real)
- Test runner: `bun test`

## Acceptance Criteria
1. `encryptEnterpriseConfig(json: object): Buffer` produces correctly formatted binary
2. `decryptEnterpriseConfig(buffer: Buffer): object` recovers original JSON
3. Round-trip: encrypt → decrypt produces identical data
4. File format: `POLO01\0` + salt(16 bytes) + IV(12 bytes) + authTag(16 bytes) + ciphertext
5. Key sourced from `ENTERPRISE_CONFIG_KEY` env var, with hardcoded fallback

## Boundary Matrix
| Input | Condition | Expected Output |
|-------|-----------|----------------|
| Valid JSON | Happy path | Encrypted Buffer with POLO01 header |
| Empty object {} | Empty config | Encrypted Buffer (valid, though config validation will reject) |
| Large JSON (10KB) | Large disabledTools list | Encrypted Buffer, decrypts correctly |
| Truncated buffer | Missing bytes | DecryptionError |
| Invalid header | Buffer starts with "WRONG01\0" | DecryptionError "invalid file header" |
| Tampered ciphertext | Modified byte in ciphertext | DecryptionError "authentication failed" |

## Input/Output Types
```typescript
Input (encrypt): object → Buffer
Input (decrypt): Buffer → object
Errors: DecryptionError (header invalid, auth failed, parse failed)
```

## Test Cases (Red Phase)
- TEST: encryptEnterpriseConfig({ endpoint: "https://proxy.com", apiKey: "key", defaultModel: "model" }) → Buffer starting with "POLO01\0"
- TEST: Buffer header bytes → salt(16 bytes at offset 7) + IV(12 bytes at offset 23)
- TEST: decryptEnterpriseConfig(encryptEnterpriseConfig(data)) → deep equals original data
- TEST: decryptEnterpriseConfig(Buffer.from("WRONG01\0" + ...)) → throws DecryptionError "invalid file header"
- TEST: decryptEnterpriseConfig(validBuffer with 1 byte flipped) → throws DecryptionError "authentication failed"
- TEST: decryptEnterpriseConfig(Buffer.alloc(0)) → throws DecryptionError
- TEST: decryptEnterpriseConfig(truncated valid buffer) → throws DecryptionError
- TEST: Round-trip with large object (1000 disabledTools) → decrypts correctly
- TEST: ENTERPRISE_CONFIG_KEY env var override → uses env var key, not fallback
