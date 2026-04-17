#!/usr/bin/env bash
#
# Ralph-dev: multi-iteration AI loop (stateless Claude/amp invocations).
# Assumes Clarify + Breakdown are done; runs Implement → Heal → Deliver until phase is complete.
#
# Install: ralph-dev init --loop   (copies this file to .ralph-dev/ralph.sh)
# Run from project root: ./.ralph-dev/ralph.sh [--tool claude|amp] [--no-prd-context] [max_iterations]
# Default max iterations: (task count from ralph-dev tasks list) + 5. Override with trailing number.
#
# Env:
#   RALPH_DEV_WORKSPACE     Project root (default: parent of .ralph-dev when script lives there, else $PWD)
#   RALPH_LOOP_PRD_MAX_BYTES      Max bytes of .ralph-dev/prd.md to inject (default: 65536)
#   RALPH_LOOP_CONTEXT_MAX_BYTES  Max bytes per file under .ralph-dev/context/*.md (default: 32768)
#   RALPH_LOOP_NO_OUTPUT_LOG=1    Do not write per-iteration tool output under .ralph-dev/loop-runs/
#

set -euo pipefail

TOOL="claude"
USER_MAX_ITERATIONS=""
NO_PRD_CONTEXT=0
PRD_MAX_BYTES="${RALPH_LOOP_PRD_MAX_BYTES:-65536}"
CTX_MAX_BYTES="${RALPH_LOOP_CONTEXT_MAX_BYTES:-32768}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    --no-prd-context)
      NO_PRD_CONTEXT=1
      shift
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        USER_MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

if [[ "$TOOL" != "amp" && "$TOOL" != "claude" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp' or 'claude'." >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required (brew install jq / apt install jq)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(basename "$SCRIPT_DIR")" == ".ralph-dev" ]]; then
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
  PROJECT_ROOT="${RALPH_DEV_WORKSPACE:-$(pwd)}"
fi
export RALPH_DEV_WORKSPACE="$PROJECT_ROOT"

RALPH_DEV_DIR="$PROJECT_ROOT/.ralph-dev"
PROGRESS_FILE="$RALPH_DEV_DIR/progress.txt"
PRD_FILE="$RALPH_DEV_DIR/prd.md"
CTX_DIR="$RALPH_DEV_DIR/context"

if ! command -v ralph-dev &>/dev/null; then
  echo "Error: ralph-dev CLI not found on PATH. Install: npm install -g ralph-dev" >&2
  exit 1
fi

TASK_TOTAL_FOR_CAP=""
if [[ -n "$USER_MAX_ITERATIONS" ]]; then
  MAX_ITERATIONS="$USER_MAX_ITERATIONS"
else
  TASK_TOTAL_FOR_CAP=$(ralph-dev tasks list --json --limit 1 2>/dev/null | jq -r '.data.total // 0')
  [[ "$TASK_TOTAL_FOR_CAP" =~ ^[0-9]+$ ]] || TASK_TOTAL_FOR_CAP=0
  MAX_ITERATIONS=$((TASK_TOTAL_FOR_CAP + 5))
fi

append_progress() {
  local line="$1"
  mkdir -p "$RALPH_DEV_DIR"
  printf '%s\n' "$line" >>"$PROGRESS_FILE" 2>/dev/null || true
}

read_capped() {
  local file_path="$1"
  local max_bytes="$2"
  local label="$3"
  [[ -f "$file_path" ]] || return 0
  local size
  size=$(wc -c <"$file_path" | tr -d ' ')
  if [[ "$size" -le "$max_bytes" ]]; then
    cat "$file_path"
  else
    head -c "$max_bytes" "$file_path"
    printf '\n\n[%s truncated: file is %s bytes, cap %s]\n' "$label" "$size" "$max_bytes"
  fi
}

build_prd_block() {
  [[ "$NO_PRD_CONTEXT" -eq 1 ]] && return 0
  [[ -f "$PRD_FILE" ]] || return 0
  echo "## PRD (.ralph-dev/prd.md)"
  echo
  read_capped "$PRD_FILE" "$PRD_MAX_BYTES" "PRD"
  echo
}

build_context_block() {
  [[ "$NO_PRD_CONTEXT" -eq 1 ]] && return 0
  [[ -d "$CTX_DIR" ]] || return 0
  local found=0
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    found=1
    local base
    base=$(basename "$f")
    echo "## Context: $base"
    echo
    read_capped "$f" "$CTX_MAX_BYTES" "context/$base"
    echo
  done < <(find "$CTX_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | LC_ALL=C sort)
}

extract_phase() {
  local json="$1"
  echo "$json" | jq -r '.data.phase // .phase // "none"'
}

initial_phase_check() {
  local state_json
  state_json=$(ralph-dev state get --json 2>/dev/null) || state_json='{}'
  local phase
  phase=$(extract_phase "$state_json")
  if [[ "$phase" == "none" || "$phase" == "null" || -z "$phase" ]]; then
    echo "Error: No active ralph-dev session. Run clarify/breakdown first, then set phase to implement." >&2
    exit 2
  fi
  if [[ "$phase" == "clarify" || "$phase" == "breakdown" ]]; then
    echo "Error: Phase is '$phase' (interactive). Complete Clarify and Breakdown in Claude Code first; this loop starts at implement/heal/deliver." >&2
    exit 3
  fi
  if [[ "$phase" == "complete" ]]; then
    echo "Nothing to do: phase is already complete."
    exit 0
  fi
}

if [[ -n "$USER_MAX_ITERATIONS" ]]; then
  echo "ralph-dev loop — project: $PROJECT_ROOT — tool: $TOOL — max iterations: $MAX_ITERATIONS (explicit)"
else
  echo "ralph-dev loop — project: $PROJECT_ROOT — tool: $TOOL — max iterations: $MAX_ITERATIONS (tasks ${TASK_TOTAL_FOR_CAP}+5)"
fi
append_progress "[ralph.sh] Loop started at $(date -Iseconds 2>/dev/null || date) tool=$TOOL max=$MAX_ITERATIONS tasks=${TASK_TOTAL_FOR_CAP:-na}"

initial_phase_check

# Each iteration's claude/amp stdout+stderr is also saved here (same bytes as shown in terminal).
LOOP_RUN_DIR=""
if [[ "${RALPH_LOOP_NO_OUTPUT_LOG:-0}" != "1" ]]; then
  LOOP_RUN_TS=$(date +%Y%m%d-%H%M%S 2>/dev/null || date +%s)
  LOOP_RUN_DIR="$RALPH_DEV_DIR/loop-runs/$LOOP_RUN_TS"
  mkdir -p "$LOOP_RUN_DIR"
  echo "Tool output (claude/amp print) → $LOOP_RUN_DIR/iteration-*.txt" >&2
fi

# ── Controller contract helpers ──────────────────────────────────────

CONSECUTIVE_NULLS=0

# Determine whether the loop should continue based on lastOutcome.
# Returns 0 = continue, 1 = stop, 2 = null outcome.
should_continue() {
  local outcome="$1"
  case "$outcome" in
    task_completed|task_stalled)
      echo "  ↳ Outcome: $outcome (continuable)"
      return 0
      ;;
    blocked_dependencies)
      echo "  ↳ Stopped: blocked dependencies"
      return 1
      ;;
    attention_required)
      echo "  ↳ Stopped: attention required"
      return 1
      ;;
    moved_to_deliver)
      echo "  ↳ Phase moved to deliver"
      return 3
      ;;
    null|"")
      return 2
      ;;
    *)
      echo "  ↳ Stopped: unknown outcome '$outcome'"
      return 1
      ;;
  esac
}

# Print task summary for logging context.
print_task_summary() {
  local tasks_json
  tasks_json=$(ralph-dev tasks list --limit 999 --json 2>/dev/null || echo '{}')
  local total done pending stalled failed
  total=$(echo "$tasks_json" | jq -r '.data.total // 0')
  done=$(echo "$tasks_json" | jq '.data.tasks // [] | map(select(.status == "completed")) | length')
  pending=$(echo "$tasks_json" | jq '.data.tasks // [] | map(select(.status == "pending")) | length')
  stalled=$(echo "$tasks_json" | jq '.data.tasks // [] | map(select(.status == "stalled")) | length')
  failed=$(echo "$tasks_json" | jq '.data.tasks // [] | map(select(.status == "failed")) | length')
  echo "  Tasks: $done/$total completed, $pending pending, $stalled stalled, $failed failed"

  # Show next-task hint if available
  local active_json
  active_json=$(ralph-dev tasks active --json 2>/dev/null || echo '{}')
  local next_task
  next_task=$(echo "$active_json" | jq -r '.data.task.id // "none"')
  if [[ "$next_task" != "none" ]]; then
    echo "  Next task: $next_task"
  fi
}

# ── Main loop ────────────────────────────────────────────────────────

for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo ""
  echo "==============================================================="
  echo "  Ralph-dev iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "==============================================================="

  # Pre-iteration state check
  STATE_JSON=$(ralph-dev state get --json 2>/dev/null || echo '{}')
  PHASE=$(extract_phase "$STATE_JSON")

  if [[ "$PHASE" == "complete" ]]; then
    echo "All phases complete."
    append_progress "[ralph.sh] Complete at iteration $i ($(date -Iseconds 2>/dev/null || date))"
    exit 0
  fi

  if [[ "$PHASE" == "deliver" ]]; then
    echo "Phase is deliver — stopping loop."
    append_progress "[ralph.sh] Deliver phase reached at iteration $i"
    exit 0
  fi

  # Task summary for context
  print_task_summary

  # Clear lastOutcome before invoking Phase 3
  ralph-dev state update --last-outcome null 2>/dev/null || true

  # Build prompt for Phase 3 invocation
  PRD_BLOCK=""
  CTX_BLOCK=""
  if [[ "$NO_PRD_CONTEXT" -eq 0 ]]; then
    PRD_BLOCK=$(build_prd_block || true)
    CTX_BLOCK=$(build_context_block || true)
  fi

  PROMPT="$(cat <<EOF
You are one iteration of an autonomous ralph-dev loop.
Follow .claude/rules/ralph-dev-*.md for workflow, TDD, and CLI usage.

## Workflow snapshot (confirm with ralph-dev state get --json)
Phase: $PHASE

$PRD_BLOCK
$CTX_BLOCK

Do as much as you can this turn, then exit cleanly (no waiting for user input).
When the workflow is fully finished (phase complete), output the line: <ralph>COMPLETE</ralph>
EOF
)"

  OUTPUT=""
  if [[ "$TOOL" == "amp" ]]; then
    OUTPUT=$(echo "$PROMPT" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
  else
    OUTPUT=$(echo "$PROMPT" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true
  fi

  # Save iteration output
  if [[ -n "$LOOP_RUN_DIR" ]]; then
    LOG_FILE="$LOOP_RUN_DIR/iteration-$(printf '%03d' "$i").txt"
    {
      echo "=== ralph-loop iteration $i / $MAX_ITERATIONS tool=$TOOL ==="
      echo "=== $(date -Iseconds 2>/dev/null || date) ==="
      echo
      printf '%s\n' "$OUTPUT"
    } >"$LOG_FILE"
  fi

  # Read lastOutcome from state
  POST_STATE=$(ralph-dev state get --json 2>/dev/null || echo '{}')
  OUTCOME=$(echo "$POST_STATE" | jq -r '.data.lastOutcome // .lastOutcome // "null"')
  POST_PHASE=$(extract_phase "$POST_STATE")

  append_progress "[ralph.sh] Iteration $i done — outcome=$OUTCOME phase=$POST_PHASE ($(date -Iseconds 2>/dev/null || date))"

  # Check for completion signal from tool output
  if echo "$OUTPUT" | grep -q "<ralph>COMPLETE</ralph>"; then
    if [[ "$POST_PHASE" == "complete" ]]; then
      echo "Detected completion signal and phase is complete."
      exit 0
    fi
    echo "Completion signal present; verify state with: ralph-dev state get --json"
  fi

  # Apply controller contract
  CONT_RET=0
  should_continue "$OUTCOME" || CONT_RET=$?
  case "$CONT_RET" in
    0)
      # Continuable
      CONSECUTIVE_NULLS=0
      ;;
    2)
      # Null outcome
      CONSECUTIVE_NULLS=$((CONSECUTIVE_NULLS + 1))
      echo "  ↳ Null outcome ($CONSECUTIVE_NULLS consecutive)"
      if [[ $CONSECUTIVE_NULLS -ge 3 ]]; then
        echo "  ↳ Stopped: 3 consecutive null outcomes"
        append_progress "[ralph.sh] Stopped: 3 consecutive null outcomes at iteration $i"
        exit 1
      fi
      ;;
    3)
      # moved_to_deliver — normal successful end
      append_progress "[ralph.sh] Deliver reached at iteration $i"
      exit 0
      ;;
    *)
      # Stopped: blocked_dependencies, attention_required, unknown
      append_progress "[ralph.sh] Stopped at iteration $i — outcome=$OUTCOME"
      exit 1
      ;;
  esac

  sleep 2
done

echo "" >&2
echo "Reached max iterations ($MAX_ITERATIONS) without phase complete." >&2
echo "Check: ralph-dev state get --json  and  $PROGRESS_FILE" >&2
exit 1
