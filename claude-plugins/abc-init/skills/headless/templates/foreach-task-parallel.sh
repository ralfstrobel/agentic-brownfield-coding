#!/usr/bin/env bash
# Run a headless `claude` micro-session per unchecked task in a checklist file, using batched concurrent task execution.
#
# Example: .claude/headless/foreach-task-parallel.sh
#
# Assumptions — violating these will cause races or contention:
#   1. Per-task agents have disjoint write scopes (or are read-only).
#      Two workers editing the same file will race on filesystem state.
#   2. No PostToolUse hook contends for `.git/index.lock` (e.g. an auto `git add` post-write hook).
#   3. The API account can sustain BATCH_SIZE concurrent requests without hitting rate limits.
#   4. The tasks file uses LF line endings and no UTF-8 BOM (offset bookkeeping assumes this).

set -euo pipefail
export LC_ALL=C  # force byte semantics for ${#var} so byte-offset bookkeeping is correct

BATCH_SIZE=4

trap 'trap - INT TERM; echo "Aborted; killing workers." >&2; kill 0 2>/dev/null; exit 130' INT TERM

CLAUDE_ARGS=(
  --model sonnet                                       # override default model (sonnet|opus|haiku)
  --effort low                                         # reasoning budget per turn
  --tools "Glob,Grep,Read,Write,Edit"                  # fixed list of tools available to model
#  --allowedTools "..."                                 # whitelist of tool uses that are auto-allowed
#  --disallowedTools "..."                              # blacklist of tool uses that are auto-denied
  --permission-mode dontAsk                            # auto-deny tool use not approved via settings or allowed-tools
  --max-turns 50                                       # cap agent actions per task (safety net against logic loops)
  --no-session-persistence                             # don't pollute --resume history
  --strict-mcp-config --mcp-config '{"mcpServers":{}}' # disable all MCP servers
#  --output-format json                                 # machine-readable result
#  --bare                                               # ignore all configuration (auth/hooks/skills/MCP/CLAUDE.md)
)

dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
prompt_file="$dir/foreach-task.md"
tasks_file="$dir/foreach-task.tasks.md"

[[ -r "$prompt_file" ]] || { echo "Missing prompt file: $prompt_file" >&2; exit 1; }
[[ -r "$tasks_file" ]] || { echo "Missing tasks file: $tasks_file" >&2; exit 1; }
[[ -w "$tasks_file" ]] || { echo "Tasks file not writable: $tasks_file" >&2; exit 1; }

# Parse and map the task list once at startup. The user is expected to edit the file only while the script
# is not running, so a single snapshot is sufficient and avoids fragile search logic per iteration.
# For each checklist item we record the byte offset of the space inside `[ ]`, so we can flip the checkbox
# later by overwriting exactly one byte via dd — no rename, no inode swap.
# Single-byte writes at independent offsets don't conflict — no flock needed across workers.
regex_item='^([[:space:]]*-[[:space:]]+)\[([ x])\][[:space:]]+(.*)$'
task_offsets=() # byte offsets of the space character inside `[ ]`, used to check box
task_texts=()   # task text after the checkbox prefix
task_done=()    # "1" if already checked at startup, "0" otherwise

byte_pos=0
while IFS= read -r raw || [[ -n "$raw" ]]; do
  if [[ "$raw" =~ $regex_item ]]; then
    task_offsets+=( $(( byte_pos + ${#BASH_REMATCH[1]} + 1 )) )
    task_texts+=( "${BASH_REMATCH[3]}" )
    [[ "${BASH_REMATCH[2]}" == "x" ]] && task_done+=( 1 ) || task_done+=( 0 )
  fi
  byte_pos=$(( byte_pos + ${#raw} + 1 ))  # +1 for the LF that read consumed
done < "$tasks_file"

total=${#task_offsets[@]}
if [[ $total -eq 0 ]]; then
  echo "No checklist items in $tasks_file." >&2
  exit 1
fi

# Worker: run one task, buffer its output in memory, flip checkbox on success.
# Successful runs discard output; failed runs dump it to stderr so the user has a diagnostic.
run_task() {
  local pos="$1" offset="$2" task="$3"
  local out
  if out="$(claude -p "$task" --system-prompt-file "$prompt_file" "${CLAUDE_ARGS[@]}" 2>&1)"; then
    # Note: Exit code 0 only confirms the CLI ran cleanly, not that the agent semantically succeeded.
    echo -n x | dd of="$tasks_file" bs=1 seek="$offset" count=1 conv=notrunc 2>/dev/null
    printf '[OK]   %d/%d %s\n' "$pos" "$total" "$task"
    return 0
  else
    # Build the whole failure block, then write it in one printf — minimises interleaving
    # with concurrent workers writing to stderr at the same time.
    printf '[FAIL] %d/%d %s\n----- output -----\n%s\n----- end -----\n' \
      "$pos" "$total" "$task" "$out" >&2
    return 1
  fi
}

# Build the work queue from the startup snapshot (ensures continuous indices to pull from).
pending=()
for i in "${!task_offsets[@]}"; do
  [[ "${task_done[$i]}" == "0" ]] && pending+=( "$i" )
done

n_pending=${#pending[@]}
failures=0
batch_no=$(( (total - n_pending + BATCH_SIZE - 1) / BATCH_SIZE ))

# Run in batches of BATCH_SIZE with a full barrier between batches.
for (( start = 0; start < n_pending; start += BATCH_SIZE )); do
  batch_no=$((batch_no + 1))
  end=$(( start + BATCH_SIZE ))
  (( end > n_pending )) && end=$n_pending
  printf '\n=== batch %d: %d task(s) ===\n' "$batch_no" "$(( end - start ))"

  pids=()
  for (( k = start; k < end; k++ )); do
    i="${pending[$k]}"
    pos=$((i + 1))
    run_task "$pos" "${task_offsets[$i]}" "${task_texts[$i]}" &
    pids+=( $! )
  done

  # Barrier: wait for every worker in this batch. `|| ...` keeps set -e from aborting on a failure.
  for pid in "${pids[@]}"; do
    wait "$pid" || failures=$((failures + 1))
  done
done

if (( failures > 0 )); then
  echo
  echo "$failures task(s) failed. Re-run to retry only the unchecked ones." >&2
  exit 1
fi
