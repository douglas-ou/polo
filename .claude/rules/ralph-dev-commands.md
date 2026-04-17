# Ralph-dev CLI Commands

## CRITICAL: Most Used Commands

```bash
# Query state (DO THIS FIRST after compression)
ralph-dev state get --json

# Get next task to work on
ralph-dev tasks next --json

# List all tasks with status
ralph-dev tasks list --json
```

---

## State Management

```bash
# Get current state
ralph-dev state get --json
# → {"phase":"implement","currentTask":"auth.login","startedAt":"...","updatedAt":"..."}

# Set phase (initialize or transition)
ralph-dev state set --phase clarify
ralph-dev state set --phase breakdown
ralph-dev state set --phase implement
ralph-dev state set --phase deliver
ralph-dev state set --phase complete

# Update specific field
ralph-dev state update --phase <phase>
ralph-dev state update --task <taskId>

# Clear state (end session)
ralph-dev state clear
```

---

## Task Management

```bash
# Create task
ralph-dev tasks create <taskId> \
  --module <moduleName> \
  --priority <1-5> \
  --description "Task description" \
  --dependencies "dep1,dep2" \
  --estimated-minutes 30

# List tasks
ralph-dev tasks list --json                    # All tasks
ralph-dev tasks list --status pending          # Filter by status
ralph-dev tasks list --status completed
ralph-dev tasks list --status in_progress
ralph-dev tasks list --status failed
ralph-dev tasks list --module auth             # Filter by module

# Get next pending task (respects dependencies)
ralph-dev tasks next --json
# → {"success":true,"task":{"id":"auth.login","status":"pending",...}}
# → {"success":true,"task":null} when no more tasks

# Get specific task
ralph-dev tasks get <taskId> --json

# Task lifecycle
ralph-dev tasks start <taskId>                 # Mark as in_progress
ralph-dev tasks done <taskId>                  # Mark as completed
ralph-dev tasks done <taskId> --duration "5m"  # With duration
ralph-dev tasks fail <taskId> --reason "..."   # Mark as failed
```

---

## Language Detection

```bash
# Detect language and framework
ralph-dev detect --json
ralph-dev detect --save    # Save to task index metadata

# Output structure:
# {
#   "success": true,
#   "data": {
#     "languageConfig": {
#       "language": "typescript",
#       "testFramework": "vitest",
#       "verifyCommands": [
#         "npx tsc --noEmit",
#         "npm run lint",
#         "npm test",
#         "npm run build"
#       ]
#     },
#     "saved": false
#   }
# }
```

---

## Status Overview

```bash
ralph-dev status --json
# → {
#     "phase": "implement",
#     "tasks": {
#       "total": 10,
#       "completed": 5,
#       "pending": 3,
#       "in_progress": 1,
#       "failed": 1
#     }
#   }
```

---

## Initialize Project

```bash
# Install workflow rules to project
ralph-dev init
ralph-dev init --force    # Overwrite existing rules
ralph-dev init --loop     # Also install Phase 3 controller loop script
ralph-dev init --json     # JSON output

# Creates:
# - .claude/rules/ralph-dev-workflow.md
# - .claude/rules/ralph-dev-principles.md
# - .claude/rules/ralph-dev-commands.md
# - .ralph-dev/ directory
# - .ralph-dev/ralph.sh (with --loop, outer controller script)
```

---

## Update CLI and Plugin

```bash
# Check for updates
ralph-dev update --check
ralph-dev update --check --json

# Update CLI and plugin cache
ralph-dev update

# Update CLI only
ralph-dev update --cli-only

# Update plugin cache only (marketplace + cache)
ralph-dev update --plugin-only

# JSON output
ralph-dev update --json
```

---

## AI-Powered Detection

```bash
# AI-powered autonomous language detection
ralph-dev detect-ai --json
ralph-dev detect-ai --save    # Save to index metadata

# Save AI detection result (used by detection skill)
ralph-dev detect-ai-save '<json-result>'
```

---

## Parse Agent Results & progress.txt

```bash
# Parse structured result from agent output
ralph-dev tasks parse-result --file /path/to/output.txt --json
ralph-dev tasks parse-result --text "status: completed..." --json

# Mark done and write Task History to .ralph-dev/progress.txt (CLI-owned)
ralph-dev tasks done <taskId> --agent-output /path/to/output.txt
ralph-dev tasks done <taskId> --healed --agent-output /path/to/output.txt

# Record heal_pattern to progress.txt after healer sub-agent
ralph-dev tasks record-healing --file /path/to/heal-output.txt
```

**Use case:** Parse Phase 3 tool output; `tasks done`, `tasks fail`, and `tasks record-healing` persist to progress.txt.

---

## Common Patterns

### Implementation Loop
```bash
while true; do
  NEXT=$(ralph-dev tasks next --json)
  TASK=$(echo "$NEXT" | jq -r '.task')

  if [ "$TASK" = "null" ]; then
    break  # No more tasks
  fi

  TASK_ID=$(echo "$NEXT" | jq -r '.task.id')
  ralph-dev tasks start "$TASK_ID"

  # ... implement task ...

  # Optional: --agent-output <file> appends Task History to .ralph-dev/progress.txt
  ralph-dev tasks done "$TASK_ID"
done
```

### Phase Transition
```bash
ralph-dev state set --phase <next_phase>
```

### Error Recovery
```bash
ralph-dev state get --json
ralph-dev tasks list --status in_progress --json
```

---

## Exit Codes

| Code | Meaning | Example |
|------|---------|---------|
| 0 | Success | Operation completed |
| 1 | General error | Unexpected error |
| 2 | Not found | Task/state not found |
| 3 | Invalid input | Bad arguments |
| 4 | Conflict | Duplicate task ID |
| 5 | System error | File system error |

---

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `RALPH_DEV_WORKSPACE` | Override workspace directory |
| `CI` | Set to `true` for CI mode |
