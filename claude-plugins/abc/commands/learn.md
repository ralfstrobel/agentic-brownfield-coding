---
description: Codify implicit codebase knowledge as agent rules.
argument-hint: [fact, concept or topic]
---

# Codify Implicit Knowledge

Create or update rule files to capture implicit knowledge about the code base.

## Phase 1: Understand the Scope

1. Consider the following arguments given by the user: $ARGUMENTS
   Arguments may contain knowledge facts to learn, topics, conventions, or concepts to focus on.
2. If you already had a prior conversation or development session with the user, reflect:
    - What was unclear, ambiguous, or required explicit user guidance (relating to the given topic)?
    - What implicit conventions, constraints, or gotchas were discovered?
3. If target knowledge content still unclear, discuss with the user to clarify what should be codified.

## Phase 2: Explore and Extract Concepts

This phase is only relevant if the user has referenced specific parts of the code base
that were not already part of a prior conversation. Skip this phase otherwise.

Use an appropriate **explorer subagent** to locate and read relevant code parts.

Present your findings to the user for confirmation and clarification.

## Phase 3: Place the Rule

### 3a — Determine the owning rules directory

Rules always live in `.claude/rules` directories.

Respect location preferences for creating new rules that were explicitly specified via context or user arguments.
Otherwise, default to the global `<project-dir>/.claude/rules` directory.

### 3b — Check for existing related rules

1. Use an appropriate **explorer subagent** (or native filesystem tools if non-available)
   to search the owning rules directory for existing content related to the new knowledge.
2. If relevant rule files already exist, choose the best fitting one as the selected **target file** and skip to 3d.

### 3c — Choose file name and subdirectory

If creating a new rule:
1. List the subdirectories of the owning rules directory and choose one as the **target directory** if it fits semantically.
2. Choose the **target file** name using descriptive kebab-case (e.g., `api-error-handling.md`, `test-conventions.md`).

### 3d — Path scoping via frontmatter

Rules apply to files matching the `paths` glob declared in their YAML frontmatter.
Each path is relative to the `.claude` directory that contains the `rules/` folder.

Single matching path:
```markdown
---
paths: "src/**/*.php"
---
```

Multiple matching paths:
<!-- Array syntax not working due to bug: https://github.com/anthropics/claude-code/issues/17204 -->
```markdown
---
paths: "src/**/*.{ts,tsx},lib/**/*.ts"
---
```

Present the chosen target file path and a brief content outline to the user for confirmation before writing.

## Phase 4: Write the Rule

### Content Focus

**Important:** The codebase is subject to change and must remain the source of truth for implementation details.
Only codify knowledge that **cannot be inferred** from reading the code itself to avoid drift.
Do not list specific class members, only refer to entire files or classes by name if essential.

Focus on:
- Unintuitive **conventions** and **naming** (e.g., abbreviations, domain vocabulary)
- **Architectural constraints** and their reasoning (why, not what)
- **Gotchas**, non-obvious requirements, and common mistakes
- **Ambiguities** where the code structure suggests one approach but the correct one differs
- **Cross-cutting concerns** that are not apparent from a single file or directory

### Content Style

You are writing instructions for other AI coding agents.
Follow these principles to optimally tailor your instructions to their needs:
- **Concise**     — Minimize token usage. Prefer keywords and terse bullet points over prose.
  No verbose introductions or concept explanations.
- **Structured**  — Use compact Markdown to delineate connected aspects.
- **Actionable**  — Generate concrete operational directives, not abstract guidelines.
  Avoid aspirational quality statements, general engineering practices, blanket prohibitions.
- **Referential** — Provide pointers to code files the agents can read themselves rather than describing the code.

### Language

- Rules are always written in English, even if the user speaks a different language.
- Confirmations and output summaries for the user remain in the language the user is speaking.

### Format

Section headers followed by terse bullet points:
```markdown
# {{Component Name and/or Topic}}

- {{ statement }}
- {{ statement }}
```

### Update/Merge strategy

When updating an existing file, do not simply append content at the end
but combine new context into the existing structure efficiently.

- Deduplicate overlapping points
- Remove statements the code now makes self-evident
- Reorder to group related items
