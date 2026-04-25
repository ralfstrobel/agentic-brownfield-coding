#!/usr/bin/env bash
# PostToolUse hook — runs after every file edit (Edit or Write tool).
# Dispatches FAST, IDEMPOTENT quality checks based on file type (formatters and linters).
# Do NOT run tests here; tests are handled by the Stop hook.
# Results are fed back to the agent as structured context.
# A non-zero exit signals that corrective action is needed.
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
{ [ -z "$FILE" ] || [ ! -f "$FILE" ]; } && exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT=$(pwd)
cd "$REPO_ROOT"

REL_FILE="${FILE#"$REPO_ROOT"/}"

# Automatically try to add created files to the git index
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
if [ "$TOOL_NAME" = "Write" ]; then
    git -C "$REPO_ROOT" add -- "$REL_FILE" 2>/dev/null || true
fi

RESULTS=""
ANY_FAILURE=0
record() {
    local LABEL="$1"; shift
    local OUTPUT EXIT
    OUTPUT=$("$@" 2>&1) && EXIT=0 || EXIT=$?
    if [ $EXIT -ne 0 ]; then
        ANY_FAILURE=1
        RESULTS="$RESULTS\n=== $LABEL ===\n$OUTPUT"
    fi
}

# ---------------------------------------------------------------------------
# File type dispatching
# ---------------------------------------------------------------------------
# Add a case for each file type in this project.
# Each case should call `record` with formatters and/or linters for that file.
#
# Example (TypeScript with Prettier + ESLint):
#
#   if [[ "$FILE" == *.ts ]]; then
#       record "prettier" npx prettier --write "$REL_FILE"
#       record "eslint"   npx eslint --fix "$REL_FILE"
#
#   elif [[ "$FILE" == *.css ]]; then
#       record "stylelint" npx stylelint --fix "$REL_FILE"
#
#   else
#       exit 0
#   fi
#
# Example (PHP with PHP_CodeSniffer):
#
#   if [[ "$FILE" == *.php ]]; then
#       record "phpcbf" vendor/bin/phpcbf "$REL_FILE"
#       record "phpcs"  vendor/bin/phpcs  "$REL_FILE"
#   else
#       exit 0
#   fi
#
# Example (Python with Ruff):
#
#   if [[ "$FILE" == *.py ]]; then
#       record "ruff-format" ruff format "$REL_FILE"
#       record "ruff-check"  ruff check --fix "$REL_FILE"
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
