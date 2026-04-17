---
id: tools.blacklist
module: tools
type: domain
priority: 1
status: pending
estimatedMinutes: 20
dependencies: [enterprise.types]
---
# Implement Tool Blacklist Enforcement

## Description
Create `packages/shared/src/enterprise/tool-filter.ts` that filters tools by name when the ClaudeAgent initializes. All tools enabled by default; only tools in the `disabledTools` array are removed. The agent never sees disabled tools, so the LLM cannot request them.

## Environment Context
- Tool identifiers: read_file, write_file, search_files, list_directory, shell, web_fetch, web_search, lsp, etc.
- Enforcement point: agent tool registration layer (before agent starts)
- Key file: `packages/shared/src/agent/claude-agent.ts`
- Test strategy: Mix (unit mock, integration real)

## Boundary Matrix
| Input | Condition | Expected Output |
|-------|-----------|----------------|
| [] | Empty blacklist | All tools passed through |
| ["shell"] | Single disabled tool | All tools except "shell" |
| ["shell", "write_file"] | Multiple disabled | All tools except both |
| ["nonexistent_tool"] | Unknown tool name | All tools passed (blacklist entry ignored) |
| undefined | No disabledTools | All tools passed through |

## Input/Output Types
```typescript
Input: tools: Tool[], disabledTools: string[] | undefined
Output: Tool[] (filtered)
```

## Acceptance Criteria
1. `filterTools(tools, disabledTools)` removes tools matching disabledTools names
2. Empty/undefined disabledTools → all tools pass through
3. Unknown tool names in blacklist → silently ignored
4. Case-sensitive matching on tool names

## Test Cases (Red Phase)
- TEST: filterTools([tool1, tool2, tool3], []) → returns all 3 tools
- TEST: filterTools([tool1, tool2, tool3], undefined) → returns all 3 tools
- TEST: filterTools([tool_shell, tool_write, tool_read], ["shell"]) → returns [tool_write, tool_read]
- TEST: filterTools([tool_shell, tool_write, tool_read], ["shell", "write_file"]) → returns [tool_read]
- TEST: filterTools([tool1, tool2], ["nonexistent"]) → returns [tool1, tool2] (no error)
- TEST: filterTools([], ["shell"]) → returns [] (empty input)
- TEST: filterTools with real tool names matching SDK identifiers → correct filtering
