#!/usr/bin/env bash
# PostToolUse hook — runs after every file edit (Edit or Write tool).
# Dispatches linters, formatters, and associated tests based on file type.
# Results are fed back to the agent as structured context.
# A non-zero exit signals that corrective action is needed.
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
{ [ -z "$FILE" ] || [ ! -f "$FILE" ]; } && exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT=$(pwd)
REL_FILE="${FILE#"$REPO_ROOT"/}"

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Automatically try to add created files to the git index
if [ "$TOOL_NAME" = "Write" ]; then
    git -C "$REPO_ROOT" add -- "$REL_FILE" 2>/dev/null || true
fi

RESULTS=""
ANY_FAILURE=0
record() {
    local LABEL="$1"; shift
    local OUTPUT EXIT
    OUTPUT=$("$@" 2>&1) && EXIT=0 || EXIT=$?
    [ $EXIT -ne 0 ] && ANY_FAILURE=1
    RESULTS="$RESULTS\n=== $LABEL ===\n$OUTPUT"
}

# ---------------------------------------------------------------------------
# File type dispatching
# ---------------------------------------------------------------------------
# Add a case for each file type in this project.
# Each case should call `record` with the relevant quality tools.
#
# Pattern:
#   1. Match test files first (most specific glob), run formatter + linter + test directly.
#   2. Match source files, run formatter + linter + derive and run the associated test.
#   3. Fall through to `exit 0` for file types that have no quality tooling.
#
# Example (TypeScript with ESLint and Jest):
#
#   if [[ "$FILE" == *.test.ts ]]; then
#       record "eslint" npx eslint --fix "$REL_FILE"
#       record "jest"   npx jest --no-coverage "$REL_FILE"
#
#   elif [[ "$FILE" == *.ts ]]; then
#       record "eslint" npx eslint --fix "$REL_FILE"
#       TEST_FILE="${FILE%.ts}.test.ts"
#       if [ -f "$TEST_FILE" ]; then
#           record "jest" npx jest --no-coverage "${TEST_FILE#$REPO_ROOT/}"
#       fi
#
#   else
#       exit 0
#   fi

{{FILE-TYPE-CASES}}

# ---------------------------------------------------------------------------
# Output — do not modify below this line
# ---------------------------------------------------------------------------
if [ -n "$RESULTS" ]; then
    printf '%b' "$RESULTS" | jq -Rs \
        '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": .}}'
fi
exit $ANY_FAILURE
