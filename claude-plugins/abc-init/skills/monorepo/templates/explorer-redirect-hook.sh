#!/usr/bin/env bash
# PreToolUse hook — denies codebase exploration by the main agent
# and redirects to the specialized sub-project explorer subagents.
# Blocks Grep/Glob on source directories, the built-in Explore agent, and Bash search commands.

INPUT=$(cat)
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty')

if [[ "$AGENT_TYPE" =~ ^[a-z-]+-explorer$ ]]; then
    # Explorer subagents themselves (*-explorer) are exempt and can use all tools.
    exit 0
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')

case "$TOOL_NAME" in
    Grep|Glob)
        PATH_ARG=$(echo "$INPUT" | jq -r '.tool_input.path // empty')
        # Normalise absolute paths to relative by stripping the project root prefix
        if [[ "$PATH_ARG" == "$CLAUDE_PROJECT_DIR" ]]; then
            PATH_ARG=""
        else
            PATH_ARG="${PATH_ARG#"${CLAUDE_PROJECT_DIR}/"}"
        fi
        if [[ -z "$PATH_ARG" ]]; then
            echo '{"decision":"block","reason":"Use of Grep/Glob tools on the entire project is prohibited due to code base size. Use appropriate sub-project explorer agents, or use Bash ls on the project root first to identify relevant directories to search."}'
        elif [[ "$PATH_ARG" =~ {{SOURCE-PATH-REGEX}} ]]; then
            echo '{"decision":"block","reason":"Use of Grep/Glob tools is prohibited for sub-project search. Delegate your search to the appropriate sub-project explorer agent."}'
        fi
        ;;
    Agent)
        SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')
        if [[ "$SUBAGENT_TYPE" == "Explore" ]]; then
            echo '{"decision":"block","reason":"General purpose explorer agent is disabled. Invoke an appropriate sub-project explorer agent or use the Grep/Glob tools outside of source directories."}'
        fi
        ;;
    Bash)
        COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
        if [[ "$COMMAND" =~ ^[[:space:]]*(grep|rg|find|glob)[[:space:]] ]]; then
            echo '{"decision":"block","reason":"Bash search commands are prohibited. Invoke an appropriate sub-project explorer agent or use the Grep/Glob tools outside of source directories."}'
        fi
        ;;
esac

exit 0
