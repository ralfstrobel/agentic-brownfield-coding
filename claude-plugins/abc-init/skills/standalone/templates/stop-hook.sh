#!/usr/bin/env bash
# Stop hook — runs once when the agent finishes its turn.
# Collects all files the agent modified during the turn, maps source files to their
# associated tests, runs the tests once (deduplicated), and either:
#  - Blocks the stop with failure output so the agent can fix the problem, OR
#  - Blocks the stop with a self-review reminder about coverage of new code paths.
set -euo pipefail

INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT=$(pwd)
cd "$REPO_ROOT"

# Only act on files the agent actually modified in this turn.
# Scans the JSONL transcript backwards from the most recent genuine user turn
# (type=user with string content, i.e. not a tool-result message) and collects
# repo-relative paths from Edit/Write tool_use entries.
CHANGED_FILES=()
if [ -f "$TRANSCRIPT_PATH" ]; then
    REPO_PREFIX="${REPO_ROOT%/}/"
    mapfile -t CHANGED_FILES < <(
        tac "$TRANSCRIPT_PATH" | jq -r '
            if .type == "user" then
                if (.message.content | type) == "string" then "STOP" else empty end
            elif .type == "assistant" then
                (.message.content // [])
                | map(select(.type == "tool_use" and (.name == "Edit" or .name == "Write")))
                | .[].input.file_path // empty
            else empty
            end
        ' 2>/dev/null \
        | awk -v prefix="$REPO_PREFIX" '
            /^STOP$/ { exit }
            index($0, prefix) == 1 && !seen[$0]++ { print substr($0, length(prefix) + 1) }
          '
    )
fi
[ ${#CHANGED_FILES[@]} -eq 0 ] && exit 0

# ---------------------------------------------------------------------------
# Phase 1: Categorize modified files by kind.
# ---------------------------------------------------------------------------
# Declare one array per source/test category the project distinguishes.
# Add and remove categories to match the project's technology stack.
#
# Example categories (TypeScript + Jest):
#   TS_SOURCE_FILES=()   # src/**/*.ts, excluding *.test.ts
#   TS_TEST_FILES=()     # src/**/*.test.ts

{{FILE-CATEGORY-ARRAYS}}

for REL_FILE in "${CHANGED_FILES[@]}"; do
    # Classify each changed file into one of the category arrays above.
    # Match test globs BEFORE source globs (test files usually also match source glob).
    #
    # Example:
    #   if   [[ "$REL_FILE" == *.test.ts ]]; then TS_TEST_FILES+=("$REL_FILE")
    #   elif [[ "$REL_FILE" == *.ts      ]]; then TS_SOURCE_FILES+=("$REL_FILE")
    #   fi

    {{FILE-CLASSIFICATION-CASES}}
done

# ---------------------------------------------------------------------------
# Phase 2: Map modified files to test commands (deduplicated).
# ---------------------------------------------------------------------------
# Associative arrays (key = test identifier) ensure each test is executed once
# even if multiple changed files map to it. Test files map to themselves; source
# files derive their associated test path from the project's layout convention.
#
# For projects with multiple source roots (e.g. a bundle layout),
# discover them dynamically from the test runner's config (e.g. parse
# `phpunit.xml` <directory> entries) and iterate over them when mapping.
#
# Example A — sibling tests (TypeScript / Jest, src/Foo.ts → src/Foo.test.ts):
#   declare -A JEST_FILES=()
#   for REL_FILE in "${TS_TEST_FILES[@]}"; do
#       JEST_FILES["$REL_FILE"]=1
#   done
#   for REL_FILE in "${TS_SOURCE_FILES[@]}"; do
#       TEST_FILE="${REL_FILE%.ts}.test.ts"
#       [ -f "$TEST_FILE" ] && JEST_FILES["$TEST_FILE"]=1
#   done
#
# Example B — parallel tree (PHP / PHPUnit, src/Foo.php → tests/FooTest.php):
#   declare -A PHPUNIT_FILES=()
#   for REL_FILE in "${PHP_TEST_FILES[@]}"; do
#       PHPUNIT_FILES["$REL_FILE"]=1
#   done
#   for REL_FILE in "${PHP_SOURCE_FILES[@]}"; do
#       TEST_FILE="tests/${REL_FILE#src/}"
#       TEST_FILE="${TEST_FILE%.php}Test.php"
#       [ -f "$TEST_FILE" ] && PHPUNIT_FILES["$TEST_FILE"]=1
#   done
#
# Example C — prefixed name (Python / pytest, pkg/foo.py → pkg/test_foo.py):
#   declare -A PYTEST_FILES=()
#   for REL_FILE in "${PY_TEST_FILES[@]}"; do
#       PYTEST_FILES["$REL_FILE"]=1
#   done
#   for REL_FILE in "${PY_SOURCE_FILES[@]}"; do
#       DIR="$(dirname "$REL_FILE")"
#       BASE="$(basename "$REL_FILE")"
#       TEST_FILE="$DIR/test_$BASE"
#       [ -f "$TEST_FILE" ] && PYTEST_FILES["$TEST_FILE"]=1
#   done

{{TEST-MAPPING}}

# ---------------------------------------------------------------------------
# Phase 3: Execute tests, collect failures.
# ---------------------------------------------------------------------------
TESTS_OUTPUT=""
TESTS_FAILED=0
record_output() {
    local LABEL="$1"; shift
    local OUTPUT EXIT
    OUTPUT=$("$@" 2>&1) && EXIT=0 || EXIT=$?
    if [ $EXIT -ne 0 ]; then
        TESTS_FAILED=1
        TESTS_OUTPUT="$TESTS_OUTPUT\n=== $LABEL ===\n$OUTPUT"
    fi
}

# Invoke the test runner for each mapped test identifier.
#
# Example (Jest):
#   for TEST_FILE in "${!JEST_FILES[@]}"; do
#       record_output "jest: $TEST_FILE" npx jest --no-coverage "$TEST_FILE"
#   done
#
# Example (PHPUnit):
#   for TEST_FILE in "${!PHPUNIT_FILES[@]}"; do
#       record_output "phpunit: $TEST_FILE" vendor/bin/phpunit "$TEST_FILE"
#   done
#
# Example (pytest):
#   for TEST_FILE in "${!PYTEST_FILES[@]}"; do
#       record_output "pytest: $TEST_FILE" pytest -q "$TEST_FILE"
#   done

{{TEST-EXECUTION}}

extend_agent_turn() {
    local REASON="$1"
    printf '%s' "$REASON" | jq -Rs '{"decision": "block", "reason": .}'
    exit 0
}

if [ $TESTS_FAILED -ne 0 ]; then
    # Tests failed: block the stop and show results so the agent can fix them.
    extend_agent_turn "$(printf '%b' "$TESTS_OUTPUT")"
fi

# ---------------------------------------------------------------------------
# Phase 4: Tests pass. Emit a self-review reminder so the agent confirms that
# new code paths are actually covered, or proposes manual verification steps.
# ---------------------------------------------------------------------------
REMINDER=""
append_reminder() {
    if [ -n "$REMINDER" ]; then
        REMINDER="$REMINDER"$'\n\n'
    fi
    REMINDER="$REMINDER$1"
}

# $1: human-readable kind label (e.g. "TypeScript")
# $2: count of modified source files in this kind
# $3..: test identifiers that were executed for this kind (may be empty)
append_test_coverage_reminder() {
    local KIND="$1"
    local SOURCE_COUNT="$2"
    shift 2
    local TESTS=("$@")
    [ "$SOURCE_COUNT" -eq 0 ] && [ ${#TESTS[@]} -eq 0 ] && return

    if [ ${#TESTS[@]} -gt 0 ]; then
        local TEST_LIST=""
        for T in "${TESTS[@]}"; do
            TEST_LIST="$TEST_LIST"$'\n'"  - $T"
        done
        append_reminder "
=== Automated $KIND Test Coverage Reminder ===
The following associated tests ran without failures:$TEST_LIST
Confirm that all new code paths you introduced are covered exhaustively by assertions. If not, amend the tests now."
    else
        append_reminder "
=== Automated Verification Reminder ===
You modified $KIND files with no associated unit tests. Verify your changes by one of these methods:
- Add a new unit test, if appropriate according to the team's testing rules.
- Locate, amend and run integration/behavioral tests relevant to your changes.
- Execute relevant code paths yourself using tool calls.
- Inform the user of required steps for manual verification."
    fi
}

# Emit one coverage reminder per kind that was touched this turn.
#
# Example:
#   append_test_coverage_reminder "TypeScript" "${#TS_SOURCE_FILES[@]}" "${!JEST_FILES[@]}"

{{COVERAGE-REMINDERS}}

if [ -n "$REMINDER" ]; then
    extend_agent_turn "$REMINDER"
fi

exit 0
