---
# Ralph-dev Core Principles

## CRITICAL: State-Driven Execution

**NEVER assume state from memory. ALWAYS query CLI first:**

```bash
ralph-dev state get --json      # Current phase
ralph-dev tasks next --json     # Next task to work on
ralph-dev tasks list --json     # All tasks status
```

**This is MANDATORY after context compression or session resume.**

---

## Principle 1: TDD Enforcement

Every task MUST follow Test-Driven Development:
1. **Write failing test first** - Define expected behavior
2. **Implement minimal code** - Just enough to pass
3. **Refactor** - Keep tests green
4. **Verify** - Run project's test command

**NEVER skip tests. Tests are the source of truth.**

---

## Principle 2: Fresh Agent Context

Each task implementation uses fresh agent context:
- **Why:** Prevents context pollution between tasks
- **How:** Use `Task` tool to spawn subagent
- **Benefit:** Consistent starting point for each task

---

## Task Implementation Rules

### Do NOT modify task markdown files

When implementing a task from `.ralph-dev/tasks/`, **never edit the task's `.md` file**.
Task files are the spec — treat them as read-only during implementation.

- Read the task file to understand acceptance criteria and test cases.
- Write code, tests, and configs as described in the task.
- Do **not** add notes, mark status, or change any content in the task `.md` file.
- Status updates go exclusively in `.ralph-dev/tasks/index.json` (the `status` field).

---

## Principle 3: Invocation-Scoped Healing

Error recovery is embedded within Phase 3 (implement), not a separate phase:
- **Threshold:** Max 3 healing attempts per task
- **On failure:** Healer sub-agent investigates via WebSearch, applies fix, re-runs tests
- **On max attempts:** Mark task failed, proceed to next task

**NEVER retry infinitely. Failed tasks should be logged and skipped.**

---

## Principle 4: Saga Pattern for Atomicity

Multi-step operations must be atomic:
- Each step has `execute()` and `compensate()` (rollback)
- On failure: Automatically rollback all completed steps
- Audit trail: `.ralph-dev/saga.log`

---

## Principle 5: Layered Architecture

```
Commands → Services → Repositories → Domain → Infrastructure
```

| Layer | Responsibility |
|-------|----------------|
| Commands | Parse args, format output only |
| Services | Business logic and validation |
| Repositories | Data access abstraction |
| Domain | Rich entities with behavior |
| Infrastructure | File I/O, logging, Git |

**NEVER put business logic in commands. NEVER access files directly from commands.**

---

## Principle 6: User Interaction

**In main session:** Use `AskUserQuestion` tool
- Phase 1: Requirement clarification
- Phase 2: Task approval
- Phase 4: Delivery confirmation

**In subagents:** Use bash with env config (60s timeout limit)

---

## Principle 7: Progress Tracking

**After EVERY task:**
```bash
ralph-dev tasks done <id>              # Success
ralph-dev tasks fail <id> --reason "..." # Failure
```

**For every successful task, create a dedicated git commit before marking it done:**
- Run the task's relevant tests or verification commands first
- Stage only the files related to that task
- Create exactly one commit for that task using the repository's commit style
- Only run `ralph-dev tasks done <id>` after the commit succeeds

**Update current task:**
```bash
ralph-dev state update --task <next_task_id>
```

---

## Principle 8: Quality Gates

Before delivery (Phase 4), ALL must pass:
```bash
ralph-dev detect --json  # Get verify commands
```

Then execute:
- `test` - All tests pass
- `lint` - No lint errors
- `typecheck` - No type errors
- `build` - Build succeeds

**NEVER create a task commit or delivery commit with failing gates for the work being shipped.**

---

## Quick Reference: When X, Do Y

| Situation | Action |
|-----------|--------|
| Start new task | `ralph-dev tasks start <id>` |
| Task succeeded | `ralph-dev tasks done <id>` |
| Task failed | `ralph-dev tasks fail <id> --reason "..."` |
| Tests fail | Spawn healer sub-agent, max 3 attempts |
| Heal fails 3x | Mark failed, move to next task |
| All tasks done | Transition to deliver phase |
| Context compressed | Query CLI for state, resume |
