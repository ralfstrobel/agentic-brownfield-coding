#!/usr/bin/env bash
# MCP stdio server that exposes selected bash commands to Claude Code agents.
# Claude Code can invoke these tools directly instead of running raw Bash commands,
# providing structured input/output and better discoverability.

set -f  # disable glob expansion to prevent argument injection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Circuit breaker for oversized results. Tools that emit large output (verbose
# logs, full config/data dumps) would otherwise flood the agent's context.
MAX_RESULT_BYTES=25000

# ---------------------------------------------------------------------------
# Command execution wrappers
# Adjust/amend this section to match your project's execution environment(s).
# (Local, Remote SSH, Docker, via build tools, ...)
# ---------------------------------------------------------------------------

# Note the "</dev/null" here and in every other wrapper: this server's stdin is the
# JSON-RPC request pipe. Any child that inherits it can hang the server by blocking
# on a read (an interactive prompt, a test process reading stdin) or corrupt the
# session by consuming protocol bytes.
run_local() {
  cd "$PROJECT_ROOT" && "$@" 2>&1 </dev/null
}

# Dedicated project git runner with interaction & lock suppression and improved error output.
# This template assumes a single repository, and every git tool below therefore treats paths
# as relative to PROJECT_ROOT. If the target project is a polyrepo (multiple repos or submodules)
# add a resolution step before each git call.
run_git() {
  cd "$PROJECT_ROOT" && \
    GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=/bin/false GIT_OPTIONAL_LOCKS=0 \
    git -P "$@" 2>&1 </dev/null
}

# Serialized variant for tools that touch shared resources such as test databases.
# flock guards a lock file so concurrent agent calls cannot run the command at the same time.
# run_local_mutex() {
#   cd "$PROJECT_ROOT" && flock -w 1800 "/tmp/mcp-bash-tool-call.lock" "$@" 2>&1 </dev/null
# }

# Example for running commands inside a Docker Compose service instead of directly on the host:
# run_docker() {
#   # --progress quiet suppresses the "Container ... Creating/Created" noise on stderr
#   cd "$PROJECT_ROOT" && docker compose --progress quiet run --rm -T {{SERVICE}} "$@" 2>&1 </dev/null
# }

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
#     -- "$@" 2>&1 </dev/null
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
    "description": "Read the git working tree status. Lists tracked changes: modified, added, deleted, renamed files (untracked files are excluded).",
    "inputSchema": { "type": "object", "properties": {} }
  },
  {
    "name": "git_log",
    "description": "Search git commit history.",
    "inputSchema": {
      "type": "object",
      "properties": {
        "grep":  { "type": "string",  "description": "Filter commits whose message matches this string (case-insensitive)." },
        "file":  { "type": "string",  "description": "Limit log to commits touching this file path." },
        "limit": { "type": "integer", "description": "Maximum number of commits to return. Default: 20." }
      }
    }
  },
  {
    "name": "git_show",
    "description": "Read the metadata and changed-file list of a commit, or the contents of a specific file as of that commit.",
    "inputSchema": {
      "type": "object",
      "required": ["ref"],
      "properties": {
        "ref":  { "type": "string", "description": "A commit hash, tag, branch, or revision spec (e.g. HEAD~3, abc1234, v1.0)." },
        "file": { "type": "string", "description": "Optional file path, relative to the project root. If given, the file content at the specified commit is returned. If omitted, the commit metadata and the list of changed files are returned." }
      }
    }
  },
  {
    "name": "git_diff",
    "description": "Read changes to a single file, either between the git working tree and a commit, or between two commits. Use this to see what a past commit changed about a file: pass its parent as \"ref\" and the commit itself as \"ref_b\" (git_show reports the parent hash of a commit).",
    "inputSchema": {
      "type": "object",
      "required": ["file"],
      "properties": {
        "file":  { "type": "string", "description": "Path to the file. Required: whole-tree diffs are not supported." },
        "ref":   { "type": "string", "description": "The revision to compare from (base). Commit hash, branch, or tag. Default: HEAD." },
        "ref_b": { "type": "string", "description": "The revision to compare to (target). Omit to compare against the current working tree state." }
      }
    }
  },
  {
    "name": "git_rm",
    "description": "Delete a file or directory within the git working tree and also remove it from the index.",
    "inputSchema": {
      "type": "object",
      "required": ["path"],
      "properties": {
        "path": { "type": "string", "description": "File or directory path to remove (directories are removed recursively)." }
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
  local allow_large="false"

  case "$tool_name" in

    git_status)
      cmd_output=$(run_git status -sb -uno) || exit_code=$?
      ;;

    git_log)
      local grep_str file limit args=()
      grep_str=$(echo "$arguments" | jq -r '.grep // ""')
      file=$(echo "$arguments"     | jq -r '.file // ""')
      limit=$(echo "$arguments"    | jq -r '.limit // 20')
      args+=("--oneline" "-n" "$limit")
      [[ -n "$grep_str" ]] && args+=("--grep=$grep_str" "-i")
      if [[ -n "$file" ]]; then
        cmd_output=$(run_git log "${args[@]}" -- "$file") || exit_code=$?
      else
        cmd_output=$(run_git log "${args[@]}") || exit_code=$?
      fi
      ;;

    git_show)
      local ref file
      ref=$(echo "$arguments"  | jq -r '.ref')
      file=$(echo "$arguments" | jq -r '.file // ""')
      # A ref beginning with "-" would be parsed as an option, not a revision.
      if [[ -z "$ref" || "$ref" == -* ]]; then
        send_error "$id" -32602 "Invalid ref: \"$ref\""
        return
      fi
      if [[ -n "$file" ]]; then
        # One file at one revision is already the narrowest request this tool takes,
        # so a truncated result would leave the agent no way to obtain the rest.
        allow_large="true"
        cmd_output=$(run_git show --no-color --no-textconv "${ref}:${file}" --) || exit_code=$?
      else
        # Deliberately no patch. A full-tree "git show <commit>" is the single
        # easiest way for an agent to blow its context: a sweeping commit emits
        # megabytes, and rename detection over thousands of files is quadratic, so
        # it is also slow — all for a result the size limit then truncates anyway.
        # Metadata plus a status/path list instead. Oversized output is left to the
        # generic size limit below rather than bounded again here.
        #
        # --name-status, not --stat: --stat elides long paths to ".../tail/of/path.js"
        # to fit a column width, and an elided path is useless as a "file" argument —
        # git takes it as a pathspec, matches nothing, and the agent gets an empty
        # diff that reads as "this commit did not touch that file".
        cmd_output=$(run_git show --no-color --name-status --no-renames "$ref" --) || exit_code=$?
        if [[ "$exit_code" -eq 0 ]]; then
          # Hand back a ready-to-use git_diff invocation. The parent hash is resolved
          # here so the agent never has to reason about "^" — which fails on a root
          # commit, silently means first-parent on a merge, and is easily confused
          # with "the previous commit that touched this file".
          local parent hint
          # run_git folds stderr into stdout, so on failure (a root commit has no
          # parent) git's message would otherwise end up in $parent.
          parent=$(run_git rev-parse --short "${ref}^") || parent=""
          hint="[Patch omitted. Pass one of the paths above as \"file\" to git_show for its content at this commit"
          [[ -n "$parent" ]] && hint+=", or to git_diff with ref=\"$parent\" and ref_b=\"$ref\" for what this commit changed about it"
          cmd_output+=$'\n\n'"$hint.]"
        fi
      fi
      ;;

    git_diff)
      local file ref ref_b
      file=$(echo "$arguments"  | jq -r '.file')
      ref=$(echo "$arguments"   | jq -r '.ref // "HEAD"')
      ref_b=$(echo "$arguments" | jq -r '.ref_b // ""')
      # A single file's patch is already the narrowest request this tool takes, so a
      # truncated result would leave the agent no way to obtain the rest.
      allow_large="true"
      local -a diff_args=(diff --no-color --no-prefix --no-textconv --diff-algorithm=histogram --ignore-blank-lines)
      local -a diff_revs=("$ref")
      if [[ -n "$ref_b" ]]; then
        # Comparing two commits is a "read the history" operation, where surrounding
        # context is what makes a change intelligible. Working-tree diffs stay at
        # -U0: the agent already has the file and only needs the delta.
        diff_args+=(-U3)
        diff_revs+=("$ref_b")
      else
        diff_args+=(-U0)
      fi
      cmd_output=$(run_git "${diff_args[@]}" "${diff_revs[@]}" -- "$file") || exit_code=$?

      # An unchanged file and a path that matches nothing both produce an empty diff,
      # which the generic handler below would report as a bare "Done." — easily read
      # as "this commit did not touch it". Say both possibilities out loud instead of
      # probing the trees for which one it is.
      if [[ "$exit_code" -eq 0 && -z "${cmd_output//[$' \t\r\n']/}" ]]; then
        cmd_output="No differences. Note that a path matching no tracked file yields the same empty result, so verify \"$file\" is complete and correct if you expected changes."
      fi
      ;;

    git_rm)
      local path
      path=$(echo "$arguments" | jq -r '.path')
      # Note: Git will only remove files it tracks, effectively sandboxing the agent in the repo.
      cmd_output=$(run_git rm -rf -- "$path") || exit_code=$?
      ;;

    git_mv)
      local source destination
      source=$(echo "$arguments"      | jq -r '.source')
      destination=$(echo "$arguments" | jq -r '.destination')
      # Note: Git will only move files it tracks, effectively sandboxing the agent in the repo.
      cmd_output=$(run_git mv -- "$source" "$destination") || exit_code=$?
      ;;

    # git_commit)
    #   local message
    #   message=$(echo "$arguments" | jq -r '.message')
    #   cmd_output=$(run_git commit -a -m "$message") || exit_code=$?
    #   ;;

    # Note: run_git disables credential prompting, so a push that needs interactive
    # credentials fails with a message instead of hanging the server forever. That is
    # the intended trade-off — an MCP server has no terminal to prompt on.
    # git_push)
    #   local remote branch
    #   remote=$(echo "$arguments" | jq -r '.remote // "origin"')
    #   branch=$(echo "$arguments" | jq -r '.branch // ""')
    #   local args=("$remote")
    #   [[ -n "$branch" ]] && args+=("$branch")
    #   cmd_output=$(run_git push "${args[@]}") || exit_code=$?
    #   ;;

    # git_branch)
    #   local name
    #   name=$(echo "$arguments" | jq -r '.name')
    #   cmd_output=$(run_git branch "$name") || exit_code=$?
    #   ;;

    # git_checkout)
    #   local branch
    #   branch=$(echo "$arguments" | jq -r '.branch')
    #   cmd_output=$(run_git checkout "$branch") || exit_code=$?
    #   ;;


    {{TOOL-HANDLERS}}

    # diff_files)
    #   local file_a file_b
    #   file_a=$(echo "$arguments" | jq -r '.file_a')
    #   file_b=$(echo "$arguments" | jq -r '.file_b')
    #   # Two named files are already the narrowest request this tool takes, so a
    #   # truncated result would leave the agent no way to obtain the rest.
    #   allow_large="true"
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
  elif [[ -z "${cmd_output//[$' \t\r\n']/}" ]]; then
    # Some commands are silent on success.
    # Return an explicit confirmation so the agent is not confused by empty output.
    cmd_output="Done."
  fi

  # Truncate oversized results to a readable head and flag as error, prompting a narrower request.
  # Tools that set allow_large are exempt (see the reasons at those sites).
  local byte_count
  byte_count=$(printf '%s' "$cmd_output" | wc -c)
  if [[ "$allow_large" != "true" ]] && (( byte_count > MAX_RESULT_BYTES )); then
    is_error="true"
    # iconv -c drops a partial multi-byte char left dangling by the byte-wise head cut.
    cmd_output="$(printf '%s' "$cmd_output" | head -c "$MAX_RESULT_BYTES" | iconv -f UTF-8 -t UTF-8 -c)"$'\n\n'"[Result of $byte_count bytes exceeds the $MAX_RESULT_BYTES-byte limit; only the leading portion is shown above. Consider narrowing the request to obtain complete output — e.g. a more specific filter, file or target.]"
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
