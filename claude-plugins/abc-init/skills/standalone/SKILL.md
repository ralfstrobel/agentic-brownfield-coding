---
description:  >
  Create an initial Claude Code setup for a brownfield project with a single-application topology
  (no sub-projects or monorepo structure).
disable-model-invocation: true
user-invocable: true
---

# Claude Code Standalone Project Initialization

Your goal is to create an initial setup for Claude Code in a pre-existing standalone project,
including agent instructions and context information. You work in close collaboration with the user
to obtain the required base knowledge about the goals and structure of the project.

**Additional user arguments**: $ARGUMENTS

**Language hint**: Always create all generated document content in English,
while continuing to speak to the user in the language of their choice.

## Philosophy

Brownfield projects depend on large amounts of implicit tribal knowledge that cannot be inferred by scanning the code.
The main challenge is to codify this knowledge efficiently, so it is disclosed to the agent only exactly when needed.

- **Concise central CLAUDE.md** — This file is injected into every conversation and subagent.
  Bloating it causes priority saturation: irrelevant instructions compete for attention and degrade output quality.
  Include project identity, key vocabulary, technology overview, and pointers to tooling.
- **Rules for scoped conventions** — Rules are deterministically injected when the agent reads matching files.
  Use them for language-specific code and testing conventions rather than putting these in CLAUDE.md.
- **Explorer agent as context primer** — LLMs need task-relevant code excerpts on demand.
  A custom explorer agent navigates the codebase and returns contextualized findings,
  replacing the need for exhaustive documentation in agent instructions.
- **Code as single source of truth** — Prefer pointers to entry points over exhaustive documentation.
  Duplicating code knowledge in agent instructions leads to drift. Let the agent read the code.
- **No vague guardrails in generated content** — Do not generate aspirational quality statements,
  abstract engineering principles, or blanket prohibition lists. Only generate concrete, actionable instructions.

# Workflow

## Phase 1: Reconnaissance

1. Use the Explore agent to scan the repository and build an initial understanding of its structure
   - Top-level directory content that hints at used technologies (e.g. `package.json`, `composer.json`, `Cargo.toml`, `go.mod`, `Makefile`, `Dockerfile`)
   - Existing documentation (e.g. `README.md`, `CONTRIBUTING.md` or `docs/`)
2. Read any discovered documentation and technology manifest files
3. Check for an existing `CLAUDE.md` or `.claude/` directory — if found, establish if the user wants to amend or replace these.
4. Summarize your findings and conclusions briefly for the user and ask if they want to comment or add information.

## Phase 2: User Interview

Interview the user to establish the project's base details.
Use `AskUserQuestion` where appropriate to keep the conversation structured.
Offer pre-defined choice options if likely answers to a question are already known from context.

### Question Catalogue

1. What is the name of the project?
2. Who is the project creator and/or maintainer (company/organization)?
3. What is the overall purpose of the project (one-sentence summary)?
4. What are the main technologies used (programming language, framework, deployment...)?
5. What are key concepts or vocabulary that every developer needs to learn on their first day?
6. What are the key source directories?
7. How are automated tests organized and run?
8. Are there tools for linting or other automated code quality control?

## Phase 3: Generate Artifacts

### 3a — Claude Code Settings

1. Copy the [template](./templates/settings-template.json) to `<project-dir>/.claude/settings.json`
2. Replace `{{PLACEHOLDERS}}` with answers from the user interview.
3. Add additional `Bash` permissions for known linter or testing tool commands.

### 3b — Central CLAUDE.md

1. Copy the [template](./templates/CLAUDE-template.md) to `<project-dir>/CLAUDE.md`
2. Fill in the `{{PLACEHOLDERS}}` with answers from the user interview.
3. For placeholders that do not have corresponding answers,
   ask the user whether they want to provide an answer, generate an answer from code exploration, or omit the section.

The content is written for AI, not humans. There is no need for verbose introductions or explanations.
Keep this file as brief as possible to preserve tokens. Prefer keywords and enumeration over continuous text.
Use clear section headers and other Markdown formatting to demark connected aspects.

### 3c — Local Override Files

If a `.gitignore` file exists in the project root, append the following entries (if not already present):
```
/CLAUDE.local.md
/.claude/settings.local.json
```

### 3d — Explorer Agent

1. Copy the [template](./templates/explorer-agent.md) to `<project-dir>/.claude/agents/<project-slug>-explorer.md`
2. Fill in the `{{PLACEHOLDERS}}` with known answers from the interview.
3. Use a general purpose `Explore` agent to perform a more thorough exploration of the project's code
   and add additional context information and instructions that are helpful to navigate the code structure
   as well as common conventions and nomenclature.

### 3e — Rules

1. Create a `.claude/rules/` directory in the project root.
2. For each programming language used in the project, create a code style rule
   from the [template](./templates/rule-code-style.md) at `<project-dir>/.claude/rules/<language>-code-style.md`
    - Fill in `{{PLACEHOLDERS}}` according to the aspects of the programming language.
    - Populate the style rules from linting tool configuration if discovered in Phase 1,
      or from conventions observed during code exploration.
3. For each testing framework used in the project, create a testing rule
   from the [template](./templates/rule-testing.md) at `<project-dir>/.claude/rules/testing.md`
    - Determine a glob pattern matching only existing test files (e.g. `**/*.test.ts`, `**/*Test.php`, `**/test_*.py`, `**/*_test.go`).
    - Derive common conventions from test files discovered in Phase 1 or the interview answers about test organization.
    - Populate with concrete test conventions (file placement, naming, assertion style, setup patterns)
      discovered in Phase 1 or the interview answers about test organization.

If any of these steps seem inapplicable to the given project, skip them and note this during the summary.

## Phase 4: Review & Disclaimers

- Present a summary table of everything created (file path, artifact type, purpose).
- Explain that this is an initial scaffold, not a finished setup. Specifically:
  - **The explorer agent needs tuning.** The generated agent contains only minimal structural knowledge.
    Developers should refine known directories and output format until it reliably returns useful context.
  - **Rules are stubs.** The generated rules contain minimal conventions.
    Developers should expand them with the implicit conventions of this project over time.
  - **CLAUDE.md files can be created in any directory.** If rules seem too much overhead,
    the simplest way to inject path-based context is to create a CLAUDE.md in a directory,
    and it will be loaded whenever the agent first accesses this part of the code.
- Promote the `/abc:build` workflow example command, by explaining that agent context files alone
  are not a guarantee for reliable agent behavior and are unsuitable as enforceable constraints.
  They should be paired with concrete workflow protocol commands with explicit steps.
- Promote the `/abc:learn` workflow command, that can be used to generate
  additional agent context to manifest implicit tribal knowledge.
