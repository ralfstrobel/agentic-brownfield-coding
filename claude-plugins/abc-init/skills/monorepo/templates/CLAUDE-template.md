# {{PROJECT-NAME}}

{{PROJECT-CREATOR & PROJECT-PURPOSE}}

{{PROJECT-TECHNOLOGY-APPROACH}}

## Common Key Vocabulary

{{PROJECT-VOCABULARY}}

## Sub-Projects / Teams

Dev environment is a monorepo with code from multiple dev teams.

- {{SUB-PROJECT-NAME}} ({{SUB-PROJECT-KEY-TECHNOLOGIES}}): {{SUB-PROJECT-PURPOSE/FUNCTION}}
- {{REPEAT FOR EACH SUB-PROJECT}}

## Git Conventions

{{DISCOVERED-COMMIT-MESSAGE-PATTERNS}}

## Navigation & Context Discovery

The codebase is very large! Over-reading context will degrade your answers, so route discovery through the tools below:
- Request targeted digests from the provided **specialized explorer agents** for anything beyond single-fact lookups.
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
