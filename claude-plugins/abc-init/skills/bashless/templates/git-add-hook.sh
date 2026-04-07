#!/usr/bin/env bash
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
