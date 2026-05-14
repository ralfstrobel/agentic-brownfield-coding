#!/usr/bin/env bash
# foreach-line.sh — run a headless `claude` micro-session per line of stdin.
#
# Examples: gh pr list --json number -q '.[].number' | .claude/headless/foreach-line.sh
#           cat ticket-ids.txt | .claude/headless/foreach-line.sh
#
# Each non-empty non-comment line of stdin becomes the user prompt of one isolated invocation.
# The system prompt with the instructions to perform comes from the sibling `foreach-line.md`.

set -euo pipefail

trap 'echo "Aborted." >&2; exit 130' INT TERM

CLAUDE_ARGS=(
  --model sonnet                                       # override default model (sonnet|opus|haiku)
  --effort low                                         # reasoning budget per turn
  --tools "Glob,Grep,Read,Write,Edit"                  # fixed list of tools available to model
#  --allowedTools "..."                                 # whitelist of tool uses that are auto-allowed
#  --disallowedTools "..."                              # blacklist of tool uses that are auto-denied
  --permission-mode dontAsk                            # auto-deny tool use not approved via settings or allowed-tools
  --max-turns 50                                       # cap agent actions per file (safety net against logic loops)
  --no-session-persistence                             # don't pollute --resume history
  --strict-mcp-config --mcp-config '{"mcpServers":{}}' # disable all MCP servers
#  --output-format json                                 # machine-readable result
#  --bare                                               # ignore all configuration (auth/hooks/skills/MCP/CLAUDE.md)
)

dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
prompt_file="$dir/foreach-line.md"

[[ -r "$prompt_file" ]] || { echo "Missing prompt file: $prompt_file" >&2; exit 1; }

# Drain stdin upfront so the loop body doesn't compete with `claude` for it,
# then reattach stdin to the TTY so Ctrl+C reaches both `claude` and this script.
mapfile -t lines
exec < /dev/tty 2>/dev/null || true

if [[ ${#lines[@]} -eq 0 ]]; then
  echo "No input lines received on stdin." >&2
  exit 1
fi

i=0
for line in "${lines[@]}"; do
  # Skip blanks and comments.
  [[ -z "${line//[[:space:]]/}" ]] && continue
  [[ "${line#\#}" != "$line" ]] && continue

  i=$((i + 1))
  printf '\n==> [%d] %s <==\n' "$i" "$line"
  claude -p "$line" --system-prompt-file "$prompt_file" "${CLAUDE_ARGS[@]}"
done
