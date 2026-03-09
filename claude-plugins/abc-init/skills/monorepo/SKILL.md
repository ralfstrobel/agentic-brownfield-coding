---
description:  >
  Create an initial Claude Code setup for a brownfield project with monorepo topology
  (including hybrid submodular configurations).
disable-model-invocation: true
user-invocable: true
---

# Claude Code Monorepo Initialization

Your goal is to create an initial setup for Claude Code in a large pre-existing monorepo project,
including agent instructions and context information. You work in close collaboration with the user
to obtain the required base knowledge about the goals and structure of the project as well as each sub-project.

**Additional user arguments**: $ARGUMENTS

**Language hint**: Always create all generated document content in English,
while continuing to speak to the user in the language of their choice.

## Philosophy

Brownfield projects depend on large amounts of implicit tribal knowledge that cannot be inferred by scanning the code.
The main challenge is to codify this knowledge efficiently, so it is disclosed to the agent only exactly when needed.

- **Minimal central CLAUDE.md** — This file is injected into every conversation and subagent.
  Bloating it causes priority saturation: irrelevant instructions compete for attention and degrade output quality.
  Use it only as a brief router (project identity, sub-project index, pointers to tooling).
  Never put detailed conventions, workflows, or sub-project specifics here.
- **Path-specific context over monolithic instructions** — Knowledge requirements in codebases align
  with the filesystem hierarchy. Create per-sub-project skills, rules, and explorer agents so that
  domain-specific context is only loaded when the agent is actually working in that area.
- **Explorer agents as context primers** — LLMs need task-relevant code excerpts on demand.
  Explorer agents solve this by navigating the codebase and returning contextualized findings,
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
5. What are the key source directories?
6. How are automated tests organized and run?
7. Are there tools for linting or other automated code quality control?

## Phase 3: Generate Artifacts

### 3a — Claude Code Settings

1. Copy the [template](./templates/settings-template.json) to `<project-dir>/.claude/settings.json`
2. Duplicate the block of permissions with the `{{SUB-PROJECT-PATH}}` placeholder for each sub-project.
3. Replace general `{{PLACEHOLDERS}}` with answers from the general user interview questions.
4. Add additional `Bash` permissions for known linter or testing tool commands.

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

### 3e — Sub-Project Core Skills

Perform these steps for **every** established sub-project:

1. Copy the [template](./templates/sub-project-development.md) to `<project-dir>/.claude/skills/<sub-project-slug>-development/SKILL.md`
2. Fill in the `{{PLACEHOLDERS}}` with known answers from the respective sub-project interview questions.
3. For placeholders that do not have corresponding answers,
   ask the user whether they want to provide an answer, generate an answer from code exploration or omit the section.
4. Ask the user whether they would like to add stubs for supplementary instruction files to the skill
   such as a style guide or detailed testing workflow instructions, that the agent can load on demand.
   If created, these files must be referenced in the main skill file via a Markdown link,
   with an explicit instruction to the agent explaining when to read the file.

### 3f — Sub-Project Context Stubs

Perform these steps for **every** established sub-project that lives in a distinct sub-project directory:

1. Copy the [template](./templates/sub-project-CLAUDE-template.md) to `<sub-project-path>/CLAUDE.md`
2. Fill in the `{{PLACEHOLDERS}}` with known answers from the respective sub-project interview questions.
3. Create a `.claude/rules/` directory inside the sub-project root.
4. For each programming language used in the sub-project, create a code style rule
   from the [template](./templates/rule-code-style.md) at `<sub-project-path>/.claude/rules/<language>-code-style.md`
    - Fill in `{{PLACEHOLDERS}}` according to the aspects of the programming language.
    - Populate the style rules from linting tool configuration if discovered in Phase 1,
      or from conventions observed during code exploration.
5. For each testing framework used in the sub-project, create a testing rule
   from the [template](./templates/rule-testing.md)
   at `<sub-project-path>/.claude/rules/testing.md`
    - Determine a glob pattern matching only existing test files (e.g. `**/*.test.ts`, `**/*Test.php`, `**/test_*.py`, `**/*_test.go`).
    - Derive common convention from test files discovered in Phase 1 or the interview answers about test organization.
    - Populate with concrete test conventions (file placement, naming, assertion style, setup patterns)
      discovered in Phase 1 or the interview answers about test organization.

If any of these steps seem inapplicable to the given sub-project, skip them and note this during the summary.

## Phase 4: Review & Disclaimers

- Present a summary table of everything created (file path, artifact type, purpose).
- Explain that this is an initial scaffold, not a finished setup. Specifically:
  - **Explorer agents need tuning.** The generated agents contain only minimal structural knowledge.
    Developers should refine known directories and output format until they reliably return useful context.
  - **Use of core skills should be weighed up against use of rules.** This workflow generates core skills
    because they allow the agent to load in domain knowledge about sub-projects on demand prior to file access.
    This can be beneficial for architectural planning or answering general questions.
    But if mandatory context injection for strict guidelines is needed, a `.claude/rules` file is more reliable.
    So developers should consider which mechanism is best suited to place which context information.
- Promote the `/abc:build` workflow example command, by explaining that agent context files alone
  are not a guarantee for reliable agent behavior and are unsuitable as enforceable constraints.
  They should be paired with concrete workflow protocol commands with explicit steps.
- Promote the `/abc:learn` workflow command, that can be used to generate
  additional agent context to manifest implicit tribal knowledge.
