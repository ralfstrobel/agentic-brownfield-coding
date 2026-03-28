#!/usr/bin/env bash
# MCP stdio server that exposes project CLI tools to Claude Code agents.
# Claude Code can invoke these tools directly instead of running raw Bash commands,
# providing structured input/output and better discoverability.
#
# Configure in .mcp.json:
#   { "mcpServers": { "{{PROJECT-SLUG}}": { "type": "stdio", "command": ".claude/mcp/project-cli.sh" } } }

set -f  # disable glob expansion to prevent argument injection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ---------------------------------------------------------------------------
# Tool definitions (MCP tool list)
# ---------------------------------------------------------------------------
# Define each CLI tool the agent should have access to.
# Each entry needs: name, description, inputSchema (JSON Schema for parameters).
#
# Common candidates:
#   - Test runners (pytest, jest, phpunit, go test, ...)
#   - Linters and formatters (eslint, ruff, phpcs, ...)
#   - Build commands (make, gradle, cargo build, ...)
#   - Database or migration tools
#   - Framework-specific CLIs (manage.py, artisan, rails, ...)

TOOLS_JSON='[
  {{TOOL-DEFINITIONS}}
]'

# Example tool definition (uncomment and adapt):
#
# TOOLS_JSON='[
#   {
#     "name": "test",
#     "description": "Run project tests",
#     "inputSchema": {
#       "type": "object",
#       "properties": {
#         "file": {
#           "type": "string",
#           "description": "Path to a specific test file. Omit to run all tests."
#         }
#       }
#     }
#   }
# ]'

# ---------------------------------------------------------------------------
# Command wrapper
# ---------------------------------------------------------------------------
# Adjust this to match your project's execution environment.
# Examples:
#   Direct:         run_cmd() { cd "$PROJECT_ROOT" && "$@" 2>&1; }
#   Docker Compose: run_cmd() { cd "$PROJECT_ROOT" && docker compose run --rm app "$@" 2>&1; }
#   Makefile:       run_cmd() { cd "$PROJECT_ROOT" && make "$@" 2>&1; }

run_cmd() {
  cd "$PROJECT_ROOT" && "$@" 2>&1
}

# ---------------------------------------------------------------------------
# Tool handler (dispatch tool calls to CLI commands)
# ---------------------------------------------------------------------------
handle_tool_call() {
  local id="$1" tool_name="$2" arguments="$3"
  local cmd_output=""
  local exit_code=0

  case "$tool_name" in
    {{TOOL-HANDLERS}}

    # Example handler (uncomment and adapt):
    #
    # test)
    #   local file
    #   file=$(echo "$arguments" | jq -r '.file // ""')
    #   if [[ -n "$file" ]]; then
    #     cmd_output=$(run_cmd npx jest --no-coverage "$file") || exit_code=$?
    #   else
    #     cmd_output=$(run_cmd npx jest --no-coverage) || exit_code=$?
    #   fi
    #   ;;

    *)
      send_error "$id" -32601 "Unknown tool: $tool_name"
      return
      ;;
  esac

  local is_error="false"
  if [[ "$exit_code" -ne 0 ]]; then
    is_error="true"
    cmd_output="Exit code: $exit_code"$'\n'"$cmd_output"
  fi

  send_response "$id" "$(jq -cn --arg text "$cmd_output" --argjson isError "$is_error" \
    '{content:[{type:"text",text:$text}],isError:$isError}')"
}

# ===========================================================================
# MCP protocol boilerplate — no changes needed below this line
# ===========================================================================

send_response() {
  local id="$1" result="$2"
  printf '%s\n' "$(jq -cn --argjson id "$id" --argjson result "$result" \
    '{jsonrpc:"2.0",id:$id,result:$result}')"
}

send_error() {
  local id="$1" code="$2" message="$3"
  printf '%s\n' "$(jq -cn --argjson id "$id" --argjson code "$code" --arg message "$message" \
    '{jsonrpc:"2.0",id:$id,error:{code:$code,message:$message}}')"
}

while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  method=$(echo "$line" | jq -r '.method // ""')
  id=$(echo "$line" | jq '.id // null')

  case "$method" in
    initialize)
      send_response "$id" '{
        "protocolVersion": "2024-11-05",
        "capabilities": {"tools": {}},
        "serverInfo": {"name": "{{PROJECT-SLUG}}-cli", "version": "1.0.0"}
      }'
      ;;

    notifications/*)
      ;; # no response for notifications

    tools/list)
      send_response "$id" "$(jq -cn --argjson tools "$TOOLS_JSON" '{tools:$tools}')"
      ;;

    tools/call)
      tool_name=$(echo "$line" | jq -r '.params.name')
      arguments=$(echo "$line" | jq -c '.params.arguments // {}')
      handle_tool_call "$id" "$tool_name" "$arguments"
      ;;

    *)
      if [[ "$id" != "null" ]]; then
        send_error "$id" -32601 "Method not found: $method"
      fi
      ;;
  esac
done
