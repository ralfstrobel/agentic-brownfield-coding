---
description: Codify implicit codebase knowledge as agent rules.
argument-hint: "[ explicit fact | conversation aspect ] into [ rule file or directory (optional) ]"
disable-model-invocation: true
metadata:
  hint: >
    This command is best executed mid-conversation to capture missing implicit knowledge contextually.
    Use "/rewind" to restore the previous conversation state after completion to keep your agent context window clean.
---

# Codify Implicit Knowledge

Create or update agent rule files to capture implicit knowledge about the code base.

## Phase 1: Determine What to Learn

Consider the following arguments given by the user: $ARGUMENTS

Determine the goal of this learning session based on the given user input:

**A — Conversation learning (no arguments, or arguments refine focus only):**
Reflect on the prior conversation or development session with the user:
- What was unclear, ambiguous, or required explicit user guidance?
- What implicit conventions, constraints, or gotchas were discovered?

**B — Explicit fact (arguments contain a concrete statement to codify):**
The user has stated a fact directly in: $ARGUMENTS
- Treat the argument text as the knowledge to capture.
- If the fact references specific code, use an **explorer subagent** to read that code for correct context.

If neither source yields clear content, ask the user what to capture before continuing.

## Phase 2: Place the Rule

### 2a — Determine the target rules directory

Rules always live in `.claude/rules` directories.

Respect user preferences for the **target directory** that were explicitly specified via context or arguments.
Otherwise, default to the global `<project-dir>/.claude/rules` directory.

### 2b — Check for existing related rules

1. Use an appropriate **explorer subagent** or dedicated search tools
   to search the **target directory** for existing content related to the new knowledge.
2. If relevant rule files already exist, choose the best fitting as the selected **target file(s)** and skip to 2d.

### 2c — Choose name(s) of any new rule file(s)

Skip this step if all knowledge to manifest already has appropriate target files.

1. List the subdirectories of the **target directory** and choose one if it fits semantically.
2. Choose the **target file** name using descriptive kebab-case (e.g., `api-error-handling.md`, `test-conventions.md`).

### 2d — Path scoping via frontmatter

Rules apply to files matching the `paths` glob declared in their YAML frontmatter.
Each path is relative to the parent directory of the `.claude` directory that contains the `rules/` folder.

Single matching path:
```markdown
---
paths: "src/**/*.php"
---
```

Multiple matching paths:
```markdown
---
paths:
  - "src/**/*.{ts,tsx}
  - "lib/**/*.ts"
---
```

Present the chosen target file path and a brief content outline to the user for confirmation before writing.

## Phase 3: Write the Rule

### Content Focus

The goal is to reduce friction for the next agent working in this codebase.
For each content aspect candidate, ask: does it answer one of these two questions?

1. **Navigation shortcut** — "Which files should I have read first to understand this faster?"
   → Point to those files and describe why/when they matter. Don't describe what's in them.
   Also applies when the knowledge *is* in code/docs but hard to find or easy to misread:
    - **Gotchas / non-obvious requirements** — point to a location that defines or represents correct usage.
    - **Ambiguities** — code suggests A, correct answer is B. Name a file where correct usage can be observed.
    - **Conventions / Naming** — abbreviations, domain vocabulary. Point to files that define or use them canonically.
2. **Tribal knowledge** — "What did I need to know that no amount of reading the code could reveal?"
   → State that fact. Common types:
    - **External constraints**, implicit system behavior, undocumented usage instructions
    - **Team decisions**, reasons behind architectural choices
    - **Non-functional requirements** without documentation

If an item answers neither question, discard it — the code already conveys it.

**Important:** The codebase MUST always remain the source of truth for implementation details.
Do not list specific class members, only refer to entire files or classes by name if essential.

**Note:** Improving embedded code documentation is a valid alternative to writing agent rules.

### Content Style

You are writing instructions for other AI coding agents.
Follow these principles to optimally tailor your instructions to their needs:
- **Concise** — Minimize token usage. Prefer keywords and enumeration over prose.
  No verbose introductions or concept explanations.
- **Structured** — Use compact Markdown to delineate connected aspects.
- **Actionable** — Generate concrete operational directives, not abstract guidelines.
  Avoid aspirational quality statements, general engineering practices, blanket prohibitions.
- **Referential** — Provide pointers to content agents can read rather than describing/repeating it.

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
- Consolidate new points into existing sections rather than appending
