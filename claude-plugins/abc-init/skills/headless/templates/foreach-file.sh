#!/usr/bin/env bash
# foreach-file.sh — run a headless `claude` micro-session per file matching a glob expression.
#
# Example: .claude/headless/foreach-file.sh 'src/**/*.ts'
#
# Each matched file becomes the user prompt of one isolated invocation
# via `@<absolute-path>` so its content is pre-loaded for the agent.
# The system prompt with the instructions to perform comes from the sibling `foreach-file.md`.

set -euo pipefail
shopt -s globstar nullglob

trap 'echo "Aborted." >&2; exit 130' INT TERM

CLAUDE_ARGS=(
  --model sonnet                                       # override default model (sonnet|opus|haiku)
  --effort low                                         # reasoning budget per turn
  --tools "Read,Edit"                                  # fixed list of tools available to model
#  --allowedTools "..."                                 # whitelist of tool uses that are auto-allowed
#  --disallowedTools "..."                              # blacklist of tool uses that are auto-denied
  --permission-mode dontAsk                            # auto-deny tool use not approved via settings or allowed-tools
  --max-turns 50                                       # cap agent actions per file (safety net against logic loops)
  --no-session-persistence                             # don't pollute --resume history
  --strict-mcp-config --mcp-config '{"mcpServers":{}}' # disable all MCP servers
#  --output-format json                                 # machine-readable result
#  --bare                                               # ignore all configuration (auth/hooks/skills/MCP/CLAUDE.md)
)

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 '<glob>'" >&2
  exit 64
fi

dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
prompt_file="$dir/foreach-file.md"

[[ -r "$prompt_file" ]] || { echo "Missing prompt file: $prompt_file" >&2; exit 1; }

# Internal glob expansion (so '**' works regardless of caller shell state).
# Intentional unquoted expansion of $1 with globstar+nullglob enabled above.
# shellcheck disable=SC2206
files=( $1 )

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No files matched: $1" >&2
  exit 0
fi

total=${#files[@]}
i=0
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  i=$((i + 1))
  abs="$(realpath -- "$f")"
  printf '\n==> [%d/%d] %s <==\n' "$i" "$total" "$f"
  claude -p "@$abs" --system-prompt-file "$prompt_file" "${CLAUDE_ARGS[@]}"
done
