---
description: Multi-phase implementation workflow for complex development tasks with human in the loop.
argument-hint: describe the desired changes, goals, constraints and other guidelines
metadata:
  comment: >
    Implement phase is intentionally minimal. Plan mode may complete with a cleared or compacted context,
    so the agent executes from the plan itself. The plan phase therefore embeds execution instructions
    into the plan to ensure they survive compaction.
---

# Cooperative Development Request

The user wants to make the following complex additions / changes to the codebase: $ARGUMENTS

Adhere strictly to the following development workflow protocol.

## Phase 1: Define

1. Establish which repo components or sub-projects are target of the development (from user request or user role).
2. If available, invoke at least one **CORE skill** relevant to the development scope.
3. Ensure you have clearly understood the user's intent. Ask for clarification if instructions are vague or ambiguous.

## Phase 2: Research

1. Use the project's **specialized exploration subagents** to locate all code parts relevant to the development request.
   Launch multiple exploration agents in parallel when the request spans different components or sub-projects.
2. Pay special attention to system reminders that disclose additional context or skills upon reading files
   as such path-specific context is typically highly relevant. Invoke skills or read referenced files as suggested.
3. Ask for clarification if code research revealed new ambiguities regarding the development request.

## Phase 3: Strategize

Formulate between two and four different implementation approaches (one sentence summaries).

Think hard about this and challenge your ideas. Intentionally vary approaches along dimensions that matter most in complex codebases:
- **Invasion depth:** How much existing code is modified vs. extended or wrapped around?
- **Dependency direction:** Does new code adapt to existing structures, or does it introduce abstractions that existing code is refactored to use?
- **Change scope:** Minimal surgical change vs. addressing underlying structural issues that created the need?

Present the final approach options to the user to choose from or discuss.

## Phase 4: Plan

Use the `EnterPlanMode` tool to switch to plan mode, then develop the chosen implementation approach.

The plan must be detailed enough to survive context compaction, as the agent may lose
the original workflow instructions before execution begins. Embed all necessary guidance directly into the plan.

### 4.1 Structure

1. Break the approach into top-level tasks, each at a single level of abstraction.
2. Decompose each top-level task into ordered sub-tasks with concrete actions (file paths, function names, patterns to follow).
3. Mark sub-tasks that can be delegated to a subagent (i.e., they are self-contained and don't require full conversation context).

### 4.2 Verification

Add verification sub-tasks to **every** top-level task using one of these strategies:
1. **TDD (preferred):** The first sub-task introduces automated tests that will fail until implementation is successful.
2. **Manual verification (fallback):** The final sub-task provides the user with concrete verification steps,
   such as commands to run, URLs to check, edge cases to test.

### 4.3 Review checklist

Review each top-level task for:
- [ ] Security implications (input validation, auth, injection, ...)
- [ ] Performance impact (queries, loops, data volume, ...)
- [ ] Error handling and edge cases
- [ ] Consistency with existing patterns found during research

### 4.4 Clarity debt

If earlier phases required user clarification to understand existing code,
add a task to improve that code's self-documentation
(rename unclear identifiers, add comments explaining reason for design choices, ...).

### 4.5 Execution notes

Include these instructions at the end of the plan for the executing agent:
- Execute top-level tasks sequentially. Pause after each for user confirmation before proceeding.
- Delegate sub-tasks marked for subagent execution using the Agent tool.

## Phase 5: Implement

Execute the plan. If the plan is not present in context, ask the user to provide it or re-enter plan mode.
