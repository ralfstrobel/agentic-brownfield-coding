#!/usr/bin/env bash
# Run a headless `claude` micro-session per unchecked task in a checklist file.
#
# Example: .claude/headless/foreach-task.sh
#
# Reads the sibling `foreach-task.tasks.md`, iterates over lines matching `- [ ] <task>`,
# runs one isolated invocation per unchecked task, and flips the checkbox to `- [x]` after success.
# The system prompt with the instructions to perform comes from the sibling `foreach-task.md`.

set -euo pipefail
export LC_ALL=C  # force byte semantics for ${#var} so byte-offset bookkeeping is correct

trap 'echo "Aborted." >&2; exit 130' INT TERM

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
# later by overwriting exactly one byte via dd — no rename, no inode swap, safe under concurrent writers.
# Assumes LF line endings and no UTF-8 BOM. Multi-byte task text is fine (LC_ALL=C makes ${#var} byte-count).
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

# Iterate the in-memory snapshot; flip checkboxes in the file on the fly for crash durability.
for i in "${!task_offsets[@]}"; do
  [[ "${task_done[$i]}" == "1" ]] && continue
  pos=$((i + 1))
  task="${task_texts[$i]}"
  printf '\n==> [%d/%d] %s <==\n' "$pos" "$total" "$task"

  if claude -p "$task" --system-prompt-file "$prompt_file" "${CLAUDE_ARGS[@]}"; then
    # Note: Exit code 0 only confirms the CLI ran cleanly, not that the agent semantically succeeded.
    # If stricter detection is needed, instruct the prompt to return "FAIL" on last line or use json output.
    echo -n x | dd of="$tasks_file" bs=1 seek="${task_offsets[$i]}" count=1 conv=notrunc 2>/dev/null
  else
    echo "Task failed; leaving unchecked. Re-run to retry." >&2
    exit 1
  fi
done
