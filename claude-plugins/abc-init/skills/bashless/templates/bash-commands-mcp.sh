#!/usr/bin/env bash
# MCP stdio server that exposes selected bash commands to Claude Code agents.
# Claude Code can invoke these tools directly instead of running raw Bash commands,
# providing structured input/output and better discoverability.

set -f  # disable glob expansion to prevent argument injection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ---------------------------------------------------------------------------
# Command execution wrappers
# Adjust/amend this section to match your project's execution environment(s).
# (Local, Remote SSH, Docker, via build tools, ...)
# ---------------------------------------------------------------------------

run_local() {
  cd "$PROJECT_ROOT" && "$@" 2>&1
}

# Important: Use a sandbox approach for executing arbitrary commands with potential security risks.
# Example for a simple read-only no-network sandbox using bubblewrap under Linux:
# run_local_sandboxed() {
#   bwrap \
#     --ro-bind "$PROJECT_ROOT" "$PROJECT_ROOT" \
#     --ro-bind /usr /usr \
#     --ro-bind /bin /bin \
#     --ro-bind /lib /lib \
#     --symlink /usr/lib64 /lib64 2>/dev/null \
#     --die-with-parent \
#     --chdir "$PROJECT_ROOT" \
#     -- "$@" 2>&1
# }

# ---------------------------------------------------------------------------
# Tool definitions (MCP tool list)
# ---------------------------------------------------------------------------
# Each entry needs: name, description, inputSchema (JSON Schema for parameters).
# Basic git read tools are pre-defined below, with additional tools as example comments.
# Add project-specific tools as required.

TOOLS_JSON='[
  {
    "name": "git_status",
    "description": "Read the git working tree status. Lists modified, added, deleted, renamed, untracked files.",
    "inputSchema": { "type": "object", "properties": {} }
  },
  {
    "name": "git_diff",
    "description": "Read changes to a file in the git working tree compared to a commit.",
    "inputSchema": {
      "type": "object",
      "required": ["file"],
      "properties": {
        "file": { "type": "string",  "description": "Path to the file." },
        "ref":  { "type": "string",  "description": "Commit hash, branch, or tag to compare against. Default: HEAD." }
      }
    }
  },
  {
    "name": "git_rm",
    "description": "Delete file(s) within the git working tree and also remove them from the index.",
    "inputSchema": {
      "type": "object",
      "required": ["paths"],
      "properties": {
        "paths":     { "type": "array", "items": { "type": "string" }, "description": "File or directory paths to remove." },
        "recursive": { "type": "boolean", "description": "Allow recursive removal when a directory is given (-r). Default: false." }
      }
    }
  },
  {
    "name": "git_mv",
    "description": "Move or rename a file within the git working tree.",
    "inputSchema": {
      "type": "object",
      "required": ["source", "destination"],
      "properties": {
        "source":      { "type": "string", "description": "Current path of the file." },
        "destination": { "type": "string", "description": "Target path or directory." }
      }
    }
  },

  {{TOOL-DEFINITIONS}}
]'

# ---------------------------------------------------------------------------
# Git history inspection tool examples:
#
#  {
#    "name": "git_log",
#    "description": "Read the git commit history of a file.",
#    "inputSchema": {
#      "type": "object",
#      "required": ["file"],
#      "properties": {
#        "file":  { "type": "string",  "description": "File to show history for." },
#        "count": { "type": "integer", "description": "Number of commits to show. Default: 20." },
#        "since": { "type": "string",  "description": "Show commits after this date or ref (e.g. \"2 weeks ago\", \"v1.0\")." }
#      }
#    }
#  },
#  {
#    "name": "git_show_file",
#    "description": "Read the content of a file at a specific git commit.",
#    "inputSchema": {
#      "type": "object",
#      "required": ["file", "ref"],
#      "properties": {
#        "file": { "type": "string", "description": "Path to the file." },
#        "ref":  { "type": "string", "description": "Commit hash, tag, or branch name." }
#      }
#    }
#  },
#
# ---------------------------------------------------------------------------
# Git write tool examples:
#
#  {
#    "name": "git_commit",
#    "description": "Create a git commit.",
#    "inputSchema": {
#      "type": "object",
#      "required": ["message"],
#      "properties": {
#        "message": { "type": "string", "description": "Commit message." }
#      }
#    }
#  },
#  {
#    "name": "git_push",
#    "description": "Push git commits to the remote repository.",
#    "inputSchema": {
#      "type": "object",
#      "properties": {
#        "remote": { "type": "string", "description": "Remote name. Default: origin." },
#        "branch": { "type": "string", "description": "Branch name. Default: current branch." }
#      }
#    }
#  },
#  {
#    "name": "git_branch",
#    "description": "Create a new git branch from the current HEAD.",
#    "inputSchema": {
#      "type": "object",
#      "required": ["name"],
#      "properties": {
#        "name": { "type": "string", "description": "Name of the new branch." }
#      }
#    }
#  },
#  {
#    "name": "git_checkout",
#    "description": "Switch to an existing git branch.",
#    "inputSchema": {
#      "type": "object",
#      "required": ["branch"],
#      "properties": {
#        "branch": { "type": "string", "description": "Branch name to switch to." }
#      }
#    }
#  },
#
# ---------------------------------------------------------------------------
# Sandboxed filesystem tool example (requires run_local_sandboxed):
#
#  {
#    "name": "diff_files",
#    "description": "Compare two files in the project working tree using unified diff.",
#    "inputSchema": {
#      "type": "object",
#      "required": ["file_a", "file_b"],
#      "properties": {
#        "file_a": { "type": "string", "description": "Path to the first file (relative to project root)." },
#        "file_b": { "type": "string", "description": "Path to the second file (relative to project root)." }
#      }
#    }
#  },
#
# ---------------------------------------------------------------------------
# Project tool example:
#
#  {
#    "name": "test",
#    "description": "Run project tests. Omit file to run the full suite.",
#    "inputSchema": {
#      "type": "object",
#      "properties": {
#        "file": { "type": "string", "description": "Path to a specific test file." }
#      }
#    }
#  },
#

# ---------------------------------------------------------------------------
# Tool handler (dispatch tool calls to CLI commands)
# ---------------------------------------------------------------------------
handle_tool_call() {
  local id="$1" tool_name="$2" arguments="$3"
  local cmd_output=""
  local exit_code=0

  case "$tool_name" in

    git_status)
      cmd_output=$(run_local git -P status -sbu) || exit_code=$?
      ;;

    git_diff)
      local file ref
      file=$(echo "$arguments" | jq -r '.file')
      ref=$(echo "$arguments"  | jq -r '.ref // "HEAD"')
      cmd_output=$(run_local git -P diff --no-color --no-prefix -U0 --diff-algorithm=histogram --ignore-blank-lines "$ref" -- "$file") || exit_code=$?
      ;;

    git_rm)
      local recursive
      recursive=$(echo "$arguments" | jq -r '.recursive // false')
      mapfile -t paths < <(echo "$arguments" | jq -r '.paths[]')
      local args=()
      [[ "$recursive" == "true" ]] && args+=("-r")
      # Note: Git will only remove files it tracks, effectively sandboxing the agent in the repo.
      cmd_output=$(run_local git rm -f "${args[@]}" -- "${paths[@]}") || exit_code=$?
      ;;

    git_mv)
      local source destination
      source=$(echo "$arguments"      | jq -r '.source')
      destination=$(echo "$arguments" | jq -r '.destination')
      # Note: Git will only move files it tracks, effectively sandboxing the agent in the repo.
      cmd_output=$(run_local git mv -- "$source" "$destination") || exit_code=$?
      ;;

    # git_log)
    #   local file count since
    #   file=$(echo "$arguments"  | jq -r '.file')
    #   count=$(echo "$arguments" | jq -r '.count // 20')
    #   since=$(echo "$arguments" | jq -r '.since // ""')
    #   local args=("--format=%H %cs %s" "-n" "$count")
    #   [[ -n "$since" ]] && args+=("--since=$since")
    #   args+=("--" "$file")
    #   cmd_output=$(run_local git -P log "${args[@]}") || exit_code=$?
    #   ;;

    # git_show_file)
    #   local file ref
    #   file=$(echo "$arguments" | jq -r '.file')
    #   ref=$(echo "$arguments"  | jq -r '.ref')
    #   cmd_output=$(run_local git -P show "${ref}:${file}") || exit_code=$?
    #   ;;

    # git_commit)
    #   local message
    #   message=$(echo "$arguments" | jq -r '.message')
    #   cmd_output=$(run_local git commit -a -m "$message") || exit_code=$?
    #   ;;

    # git_push)
    #   local remote branch
    #   remote=$(echo "$arguments" | jq -r '.remote // "origin"')
    #   branch=$(echo "$arguments" | jq -r '.branch // ""')
    #   local args=("$remote")
    #   [[ -n "$branch" ]] && args+=("$branch")
    #   cmd_output=$(run_local git push "${args[@]}") || exit_code=$?
    #   ;;

    # git_branch)
    #   local name
    #   name=$(echo "$arguments" | jq -r '.name')
    #   cmd_output=$(run_local git branch "$name") || exit_code=$?
    #   ;;

    # git_checkout)
    #   local branch
    #   branch=$(echo "$arguments" | jq -r '.branch')
    #   cmd_output=$(run_local git checkout "$branch") || exit_code=$?
    #   ;;


    {{TOOL-HANDLERS}}

    # diff_files)
    #   local file_a file_b
    #   file_a=$(echo "$arguments" | jq -r '.file_a')
    #   file_b=$(echo "$arguments" | jq -r '.file_b')
    #   cmd_output=$(run_local_sandboxed diff -U0 --color=never --ignore-blank-lines "$file_a" "$file_b") || exit_code=$?
    #   # diff exits 1 when files differ — that's expected, not an error
    #   [[ "$exit_code" -eq 1 ]] && exit_code=0
    #   ;;

    # Project tool example (uncomment and adapt):
    #
    # test)
    #   local file
    #   file=$(echo "$arguments" | jq -r '.file // ""')
    #   if [[ -n "$file" ]]; then
    #     cmd_output=$(run_local npx jest --no-coverage "$file") || exit_code=$?
    #   else
    #     cmd_output=$(run_local npx jest --no-coverage) || exit_code=$?
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
        "serverInfo": {"name": "Bash Commands", "version": "1.0.0"}
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
