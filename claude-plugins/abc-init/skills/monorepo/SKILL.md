---
description:  >
  Create an initial Claude Code setup for a brownfield project with monorepo topology
  (including hybrid submodular configurations).
disable-model-invocation: true
user-invocable: true
---

# Claude Code Monorepo Scaffolding

Your goal is to create an initial setup for Claude Code in a large pre-existing monorepo project,
including agent instructions and context information. You work in close collaboration with the user
to obtain the required base knowledge about the goals and structure of the project as well as each sub-project.

**Additional user arguments**: $ARGUMENTS

**Language hint**: Always create all generated document content in English,
while continuing to speak to the user in the language of their choice.

## Agent Content Principles

When generating content for `.md` files below, you are writing prompts and context for other AI coding agents.
Follow these principles to optimally tailor your instructions to their needs:

- **Concise**     — Minimize token usage. Prefer keywords and terse bullet points over prose.
- **Structured**  — Use compact Markdown to delineate connected aspects.
- **Actionable**  — Generate concrete operational directives, not abstract guidelines.
                    Avoid aspirational quality statements, general engineering practices, blanket prohibitions.
- **Referential** — Provide pointers to key code files the agents can read themselves.
                    Do not describe how code works in agent instructions as such duplication leads to drift.
- **Scoped**      — Context is hierarchical. The central CLAUDE.md applies to every scope and must only
                    contain core project identity and semantics. Sub-project CLAUDE.md, rules and agent instructions
                    progressively disclose domain- and task-specific knowledge.

# Workflow

1. Begin execution by creating a formal task list for progress tracking using the `TaskCreate` tool.
   Create a task for each of the following phases (##) and sub-phases (###).
   Do not duplicate the contents in the description, only reference this skill (`abc-init:monorepo`) and the workflow item.
2. Create a dependency chain between all tasks using `TaskUpdate`, setting `addBlockedBy` to the predecessor task.
3. Work through the `TaskList` using `TaskUpdate` to mark tasks as in_progress and completed as you go.

## Phase 1: Reconnaissance

1. Use the `Explore` agent to scan the repository and build an initial understanding of its structure
   - Top-level directory content that hints at used technologies (e.g. `package.json`, `composer.json`, `Cargo.toml`, `go.mod`, `Makefile`, `Dockerfile`)
   - Existing documentation (e.g. `README.md`, `CONTRIBUTING.md` or `docs/`)
2. Read any discovered documentation and technology manifest files 
3. Check for an existing `CLAUDE.md` or `.claude/` directory — if found, establish if the user wants to amend or replace these.
4. Summarize your findings and conclusions briefly for the user and ask if they want to comment or add information.

## Phase 2: User Interview

Interview the user to establish the project's base details and sub-project boundaries.
Use `AskUserQuestion` where appropriate to keep the conversation structured.
Offer pre-defined choice options if likely answers to a question are already known from context.

### General Question Catalogue 

1. What is the name of the project?
2. Who is the project creator and/or maintainer (company/organization)?
3. What is the overall purpose of the project (one-sentence summary)?
4. What is the general technological approach of the project (one-sentence summary)?
5. What are key concepts or vocabulary that every developer needs to learn on their first day (independent of sub-project)?
6. What sub-projects or applications exist in this monorepo?

### Sub-Project Question Catalogue

Go through **every** sub-project established in general question 6 and repeat these questions for each of them.

1. What is the name of the sub-project or the development team (e.g. "backend" / "frontend")?
   (If the name is more than one word, also establish a short slug to use in generated files.)
2. What are the main purposes / functions of the sub-project?
3. What are key terms or vocabulary that every developer in this sub-project needs to know?
4. What are the main technologies used (programming language, framework, deployment...)?
5. Does this sub-project live under a **dedicated root directory**?
   - If **yes**: what is the path to that directory relative to the project root?
   - If **no**: what file/path glob pattern uniquely identifies its source files? (e.g. `src/Payments/**/*.ts`)
     This is typically `<namespace-path>/**/*.<language-extension>`.
6. What are the key source directories?
7. How are automated tests organized and run?
8. Are there tools for linting or other automated code quality control?

## Phase 3: Generate Artifacts

### 3a — Claude Code Settings

1. Copy the [template](./templates/settings-template.json) to `<project-dir>/.claude/settings.json`
2. Duplicate the permissions with the `{{SUB-PROJECT-PATH}}` placeholder for each sub-project.
3. Inject `{{GITIGNORE-EXCLUSIONS}}` into the sandbox config, limiting write access to version-controlled files only.
4. Replace general `{{PLACEHOLDERS}}` with answers from the general user interview questions.

### 3b — Central CLAUDE.md

1. Copy the [template](./templates/CLAUDE-template.md) to `<project-dir>/CLAUDE.md`
2. Fill in the `{{PLACEHOLDERS}}` with answers from the general user interview questions.

The content is written for AI, not humans. There is no need for verbose introductions or explanations.
Keep this file as brief as possible to preserve tokens. Prefer keywords and enumeration over continuous text.
Use clear section headers and other Markdown formatting to demark connected aspects.

### 3c — Local Override Files

1. Copy the [template](./templates/CLAUDE-local-example.md) to `<project-dir>/CLAUDE.local.md.example`
2. If a `.gitignore` file exists in the project root, add the following entries (if not already present):
   ```
   /CLAUDE.local.md
   /.claude/settings.local.json
   ```

### 3d — Sub-Project Explorer Agents

Perform these steps for **every** established sub-project:

1. Copy the [template](./templates/sub-project-explorer-agent.md) to `<project-dir>/.claude/agents/<sub-project-slug>-explorer.md`
2. Fill in the `{{PLACEHOLDERS}}` with known answers from the respective sub-project interview questions.
3. Use a general purpose `Explore` agent to perform a more thorough exploration of the sub-project's code
   and add additional context information and instructions that are helpful to navigate the code structure
   as well as common conventions and nomenclature.

### 3e — Sub-Project Context Rules

Perform these steps for **every** established sub-project.
The approach differs depending on whether the sub-project has a dedicated root directory (interview question 5).
If any of the steps seem inapplicable to the given sub-project, skip them and note this during the summary.

#### Case A: Sub-project with a dedicated root directory

1. Copy the [template](./templates/sub-project-CLAUDE-template.md) to `<sub-project-path>/CLAUDE.md`
2. Fill in the `{{PLACEHOLDERS}}` with known answers from the respective sub-project interview questions.
3. For placeholders that do not have corresponding answers,
   ask the user whether they want to provide an answer, generate an answer from code exploration or omit the section.
4. Create a `.claude/rules/` directory inside the sub-project root.
5. For each programming language used in the sub-project, create a code style rule
   from the [template](./templates/rule-code-style.md) at `<sub-project-path>/.claude/rules/<language>-code-style.md`
    - The `paths` glob in the template uses `**/*.<ext>` — this is relative to the sub-project directory and is correct as-is.
    - Fill in `{{PLACEHOLDERS}}` according to the aspects of the programming language.
    - Populate the style rules from linting tool configuration if discovered in Phase 1,
      or from conventions observed during code exploration.
6. For each testing framework used in the sub-project, create a testing rule
   from the [template](./templates/rule-testing.md)
   at `<sub-project-path>/.claude/rules/testing.md`
    - Determine a glob pattern matching only existing test files (e.g. `**/*.test.ts`, `**/*Test.php`, `**/test_*.py`, `**/*_test.go`).
    - Derive common convention from test files discovered in Phase 1 or the interview answers about test organization.
    - Populate with concrete test conventions (file placement, naming, assertion style, setup patterns)
      discovered in Phase 1 or the interview answers about test organization.

#### Case B: Sub-project without a dedicated root directory

Use this approach when sub-project files are spread across shared directories and are identified only by a path glob pattern.
All rules go under the **project root** `.claude/rules/<sub-project-slug>/` so their `paths` globs can reference the full path from root.

1. Copy the [template](./templates/sub-project-rule-template.md) to `<project-root>/.claude/rules/<sub-project-slug>/<sub-project-slug>-development.md`
2. Set the `paths` frontmatter to the glob pattern established in interview question 5.
3. Fill in the `{{PLACEHOLDERS}}` with known answers from the respective sub-project interview questions.
4. For placeholders that do not have corresponding answers,
   ask the user whether they want to provide an answer, generate an answer from code exploration or omit the section.
5. For each programming language used in the sub-project, create a code style rule
   from the [template](./templates/rule-code-style.md) at `<project-root>/.claude/rules/<sub-project-slug>/<language>-code-style.md`
    - Set the `paths` glob to the same pattern as in step 2 (or a narrowed variant, e.g. excluding test directories).
    - Fill in `{{PLACEHOLDERS}}` according to the aspects of the programming language.
    - Populate the style rules from linting tool configuration or observed conventions.
6. For each testing framework used in the sub-project, create a testing rule
   from the [template](./templates/rule-testing.md) at `<project-root>/.claude/rules/<sub-project-slug>/testing.md`
    - Set the `paths` glob to match only test files within the sub-project pattern.
    - Populate with concrete test conventions discovered in Phase 1 or interview answers.

## Phase 4: Debriefing & Disclaimers

- Present a summary table of everything created (file path, artifact type, purpose).
- Explain that this was a long agentic workflow and that agents can be prone to skipping steps.
  So the user should carefully test everything that was created and compare it against this skill document.
- Explain that this is an initial scaffold, not a turnkey setup. Specifically:
  - **Sandboxing:** The sandbox config in the settings is untested. Call `/sandbox` to review.
    If the user is executing Claude Code in an isolated environment such as a container, sandboxing may not be required.
  - **Explorer Agents:** The generated agents contain only minimal structural knowledge.
    Developers should refine known directories and output format until they reliably return useful context.
  - **Rules:** The generated rules contain minimal conventions.
      Developers should expand them with the implicit conventions of this project over time.
- Promote the `/abc:build` workflow example command, by explaining that agent context files alone
  are not a guarantee for reliable agent behavior and are unsuitable as enforceable constraints.
  They should be paired with concrete workflow protocol commands with explicit steps.
- Promote the `/abc:learn` workflow command, that can be used to generate
  additional agent context rules to manifest implicit tribal knowledge.
