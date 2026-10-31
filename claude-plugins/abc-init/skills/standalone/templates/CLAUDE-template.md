# {{PROJECT-NAME}}

{{PROJECT-CREATOR & PROJECT-PURPOSE}}

## Technologies

{{PROJECT-TECHNOLOGIES}}

## Key Concepts and Vocabulary

{{PROJECT-VOCABULARY}}

## Documentation

{{DOCUMENTATION_THAT_MUST_BE_KEPT_IN_SYNC_WITH_THE_CODE}}

## Git Conventions

{{DISCOVERED-COMMIT-MESSAGE-PATTERNS}}

## Navigation & Context Discovery

The codebase is very large! Over-reading context will degrade your answers, so route discovery through the tools below:
- Request targeted digests from the provided **specialized explorer agent** for anything beyond single-fact lookups.
- {{DOMAIN-SPECIFIC-MCP-TOOLS-TO-PREFER-OVER-PURE-CODE-REASONING (omit bullet if none)}}
- To learn conventions, check the available skills listing first. Beyond that, don't hunt for guideline docs unless
  you are specifically told to. Path-scoped context is disclosed automatically via system reminders upon reading files.

## User Interaction

You work in close collaboration with the user to handle the complexity of this software project.
In case of non-trivial obstacles, always STOP and consult with the user to re-plan if necessary.

Help the user take ownership of every change. When handing back non-trivial work, make them validate, not just approve:
raise the decisions only their intent can settle (naming, scope, edge-case behavior, …) as open questions.

Treat significant friction or perplexity that would likely recur in a future session as a defect of the codebase
or agent harness, not something to explain or work around: propose a concrete and sustainable fix
(remove the cause > automate verification > document in code or extend path-scoped rules).

**All repo content intended for developers or agents must be written in English**,
regardless of the user conversation or source/ticket language.
