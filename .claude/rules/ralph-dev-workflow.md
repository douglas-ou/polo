# Ralph-dev Workflow Rules

## CRITICAL: Recovery After Context Compression

**If you're unsure of current state, ALWAYS do this FIRST:**

```bash
# Step 1: Query current phase
ralph-dev state get --json

# Step 2: Check task progress
ralph-dev tasks list --json

# Step 3: Get next task (if in implement phase)
ralph-dev tasks next --json
```

**Then resume based on phase:**
| Phase | Action |
|-------|--------|
| `clarify` | Use Skill tool: `skill: "ralph-dev:phase-1-clarify"` |
| `breakdown` | Use Skill tool: `skill: "ralph-dev:phase-2-breakdown"` |
| `implement` | Use Skill tool: `skill: "ralph-dev:phase-3-implement"` |
| `deliver` | Use Skill tool: `skill: "ralph-dev:phase-5-deliver"` |
| `none` | Initialize: `ralph-dev state set --phase clarify` |

---

## Phase State Machine

```
CLARIFY → BREAKDOWN → IMPLEMENT → DELIVER → COMPLETE
```

**Valid Transitions:**
- `clarify` → `breakdown`
- `breakdown` → `implement`
- `implement` → `deliver` (all tasks done)
- `deliver` → `complete`

---

## Phase 1: CLARIFY

- **Skill:** `ralph-dev:phase-1-clarify`
- **Goal:** Generate PRD from user requirements
- **Input:** Natural language requirement
- **Output:** `.ralph-dev/prd.md`
- **Transition:** `ralph-dev state set --phase breakdown`

---

## Phase 2: BREAKDOWN

- **Skill:** `ralph-dev:phase-2-breakdown`
- **Goal:** Decompose PRD into atomic tasks (<30 min each)
- **Input:** `.ralph-dev/prd.md`
- **Output:** `.ralph-dev/tasks/*.md` + `index.json`
- **Create tasks via CLI:**
  ```bash
  ralph-dev tasks create --id <id> --module <mod> --priority <n> --description "..."
  ```
- **REQUIRES:** User approval before transition
- **Transition:** `ralph-dev state set --phase implement`

---

## Phase 3: IMPLEMENT

- **Skill:** `ralph-dev:phase-3-implement`
- **Goal:** Implement all tasks with TDD and embedded healing
- **Loop (CRITICAL):**
  1. `ralph-dev tasks next --json` → Get next task
  2. `ralph-dev tasks start <id>` → Mark as started
  3. Write failing test first (TDD)
  4. Implement minimal code to pass
  5. Create a dedicated git commit for that task
  6. `ralph-dev tasks done <id>` → Only after the commit succeeds
  7. On failure → Spawn healer sub-agent (max 3 attempts per task)
  8. Repeat until no pending tasks
- **Fresh context:** Each task uses fresh agent (Task tool)
- **Embedded healing:** On failure, Phase 3 spawns a healer sub-agent with compacted error context (root cause investigation → pattern analysis → hypothesis → fix)
- **Task specs are read-only:** Read `.ralph-dev/tasks/*.md` for requirements, but do not edit task markdown files during implementation; update status only through the CLI/index.
- **Transition:** `ralph-dev state set --phase deliver`

---

## Phase 4: DELIVER

- **Skill:** `ralph-dev:phase-5-deliver`
- **Goal:** Run final verification and create PR
- **Steps:**
  1. Run quality gates: `ralph-dev detect --json` → get verify commands
  2. Execute: test, lint, typecheck, build
  3. Create a final git commit only if delivery-specific changes remain uncommitted
  4. Create pull request
- **Transition:** `ralph-dev state set --phase complete`

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Tests fail | Spawn healer sub-agent (max 3 attempts) |
| Heal fails 3x | `ralph-dev tasks fail <id>`, continue |
| No tasks left | Transition to deliver phase |
| State not found | `ralph-dev state set --phase clarify` |
| Unknown phase | Query CLI: `ralph-dev state get --json` |
