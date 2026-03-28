---
description: Mini spec-first development workflow for complex implementation tasks with human in the loop.
argument-hint: describe the desired changes, goals, constraints and other guidelines
metadata:
  inspiration1: "https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md#what-works-even-better-frequent-intentional-compaction"
  inspiration2: "https://addyosmani.com/blog/ai-coding-workflow/"
  related: "https://github.com/gsd-build/get-shit-done/blob/main/get-shit-done/workflows/quick.md"
  background: "https://arxiv.org/html/2602.00180v1"
  comment: >
    The Implement phase is intentionally minimal. Context may be cleared or compacted before or during implementation.
    The plan phase therefore embeds execution instructions directly into the plan to ensure they survive compaction.
    Verification steps are part of the plan. Code review needs be executed as a separate workflow before submission.
---

# Cooperative Development Request

The user wants to make the following complex additions / changes to the codebase: $ARGUMENTS

Adhere strictly to the following development workflow protocol.

## Phase 1: Define

1. Establish which repo components or sub-projects are target of the development (from user request or user role).
2. Invoke any skills relevant to the development scope.
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
the original workflow instructions before execution begins.
Embed all necessary guidance directly into the plan.
Quote or summarize the original user arguments in the introduction of the plan.

### 4.1 Structure

1. Break the approach into top-level tasks at the same level of abstraction.
   Each top-level task must leave the code in a state that executes without errors.
   Each top-level task must be independently verifiable, either by automated tests, manually or via debugger.
2. Present the top-level tasks to the user for review and approval.
3. Decompose each top-level task into ordered sub-tasks with concrete actions (file paths, function names, patterns to follow).

### 4.2 Verification

Add a verification sub-task to **every** top-level task using one of these strategies (ranked most to least preferred):
1. **TDD:** Insert a sub-task **before** all other sub-tasks, which introduces automated tests
   for the new logic that will fail until implementation is successful.
2. **Agentic verification**: Given suitable API/CLI access, add a sub-task **after** all other sub-tasks
   in which the agent autonomously confirms that the implemented logic functions correctly, including all edge cases.
3. **User verification:** Add a sub-task **after** all other sub-tasks, which instructs the user to perform
   concrete verification steps (commands to run, URLs to check) and discusses relevant edge cases interactively.

Note: Do not create a dedicated verification top-level task. Final approval testing is up to the user.

### 4.3 Review checklist

Review each top-level task for:
- [ ] Security implications (input validation, auth, injection, ...)
- [ ] Performance impact (queries, loops, data volume, ...)
- [ ] Error handling and edge cases
- [ ] Consistency with existing patterns found during research

### 4.4 Clarity debt

If earlier phases required user clarification to understand existing code,
add a tasks (either top-level or sub-task) to improve that code's self-documentation
(rename unclear identifiers, add comments explaining reason for design choices, ...).

### 4.5 Execution notes

Include these instructions verbatim at the end of the plan for the executing agent:
- Begin execution by creating a formal task list for progress tracking using the `TaskCreate` tool.
  Each formal task should reference the plan file and its specific plan item in the description.
  Create a dependency chain between all tasks using `TaskUpdate`, setting `addBlockedBy` to the predecessor task.
- Work through the `TaskList` sequentially using `TaskUpdate` to mark tasks as in_progress and completed as you go.
- **Pause after each top-level task** for user confirmation before proceeding.

## Phase 5: Implement

Execute the plan. If the plan is not present in context, ask the user to provide it.
