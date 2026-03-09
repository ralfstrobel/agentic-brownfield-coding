---
description: Codify implicit codebase knowledge as path-specific agent context (CLAUDE.md files or rules).
argument-hint: [directory path] [aspects to focus on]
---

# Codify Implicit Knowledge

Create or update coding agent context documents (CLAUDE.md files or rules)
to reflect new implicit knowledge about the code base.

## Phase 1: Understand the Scope

The user has given the following arguments: $ARGUMENTS

The arguments may contain:
- a code directory path to the (sub-)component the knowledge relates to
- topics, conventions, or concepts to focus on

### Target Path

If a directory path was given, that is the target scope.
If not, infer the scope from the prior conversation context or ask the user.

Agent context files load automatically when the agent first reads any file in the given directory subtree.
To avoid unnecessary loading, they should always be placed in the most specific directory they relate to.
At the same time, duplicated context should be avoided and rather moved up to the nearest common root directory.

### Content

If you already had a prior conversation or development session with the user, reflect:
What was unclear, ambiguous, or required explicit user guidance (relating to the given topic)?
What implicit conventions, constraints, or gotchas were discovered?

If a directory path was given without further instructions, assume the user wants to
codify general knowledge about the given (sub-)component.

If still unclear, discuss with the user to clarify what should be codified.

## Phase 2: Explore and Extract Concepts

Skip this phase if targeted content is based on prior conversation and all relevant files have already been read.

Use the **specialized exploration subagents** to locate and (re-)read relevant code parts.

**Important:** The codebase is the source of truth for implementation details.
Only codify knowledge that **cannot be inferred** from reading the code itself.

Focus on:
- Unintuitive **conventions** and **naming** (e.g., abbreviations, domain vocabulary)
- **Architectural constraints** and their reasoning (why, not what)
- **Gotchas**, non-obvious requirements, and common mistakes
- **Ambiguities** where the code structure suggests one approach but the correct one differs
- **Cross-cutting concerns** that are not apparent from a single file or directory

Present your findings to the user for confirmation and discussion.

## Phase 3: Choose the Right Artifact

Select the artifact type based on scope and content.
Present the chosen artifact type, file path, and a brief content outline to the user for confirmation before writing.

### Option A: CLAUDE.md file (default)

Use when the knowledge applies broadly to a directory subtree (component conventions, domain concepts, architectural context).
Create or update a `CLAUDE.md` file directly in the selected target path.

### Option B: Rule file

Use when the knowledge applies to **specific file patterns** (e.g., only test files, only a certain file type, only files matching a path glob).

Place rule files in `.claude/rules/` at the project root or the relevant subdirectory.
Use descriptive file names (e.g., `api-error-handling.md`, `test-conventions.md`).

Declare matching paths via YAML frontmatter:
```markdown
---
paths:
  - "src/**/*.{ts,tsx}"
  - "lib/**/*.ts"
---
```

Each path is relative to the `.claude` directory of declaration.
A rule in `src/api/.claude/rules/` with path `**/*.ts` matches all `.ts` files under `src/api/`.

## Phase 4: Write the Artifact

### Audience
- Written for AI agents, not humans. No verbose introductions or concept explanations.
- Concise descriptions that minimize token usage. Prefer keywords and enumeration over prose.
- Use section headers and Markdown structure to delineate connected aspects.
- Use file references rather than duplicating content the agent can read from source.

### Language
- Artifacts are always written in English, even if the user speaks a different language.
- Confirmations and output summaries for the user remain in the language the user is speaking.

### Content format

Both CLAUDE.md files and rules use the same content structure — section headers followed by terse bullet points:
```markdown
# {{Component Name and/or Topic}}

- {{ statement }}
- {{ statement }}
```

### Update/Merge strategy

When updating an existing file, do not simply append content at the end
but try to combine new context into the existing structure efficiently.

- Deduplicate overlapping points
- Remove statements the code now makes self-evident
- Reorder to group related items
