---
paths: "**/*.{{PROGRAMMING-LANGUAGE-FILE-EXTENSION}}"
---

# {{SUB-PROJECT-NAME}} {{SUB-PROJECT-PROGRAMMING-LANGUAGE}} code style

<!--
The sections below are EXAMPLE content, not rules to keep verbatim. Adapt them to the technology at hand.
Keep entries short and example-driven, and only manifest conventions that
an autoformatter/linter does not already enforce.

## Baseline

- Base on an established style guide (e.g. PEP 8, Effective Go) and document any deviations.
- Name the linters/formatters that run automatically (e.g. via hooks).
- Name any secondary check (e.g. IDE inspections MCP tools) to run on finished files.

## File Layout

- One top-level type per file unless tightly coupled (e.g. a closed type family).
- A file hosting a family with no type of its own name is named by the family, never by one member.
- Name the affix convention for interfaces and abstract bases (if any).

## Control Flow

- Prefer early return (`return`, `continue`, raise/throw) over nested `if`/`else` branches.
- Null-propagating gates should assert the positive.

## Error Handling

- Signal programming errors and runtime/data errors with distinct error types.
- Do not spell code symbols verbatim as strings in error messages — they drift silently.

## Naming

- Classes: name after their specific responsibility. Prefer names that describe what the class *is* or *does*
  (`*Registry`, `*Factory`, `*Compiler`, …). Avoid vague roles (`*Manager`, `*Helper`)
  and reification of processes/outputs into abstract nouns (`*Resolver` over `*Resolution`).
  Class names should be uniquely findable in a global search for easy referencing.
- Methods: use a verb that describes how the result is produced (`build`, `resolve`, `parse`); reserve `get` for plain accessors
- Actions: imperative verbs hinting at side effects (`activate()` over `setActive(true)`, `registerNode()` over `addNode()`)

- Variables: avoid abbreviations (`value` over `v`); prefer names identifying exact semantics (`objectType` over `type`).
- Iteration variables: exact singular of their source (`for objectType in objectTypes`).
- Booleans: read as an assertion about the instance (`supportsRetry()` over `isRetrySupported()`).
- Scalars: Avoid type suffixes (`name` over `nameString`) unless needed for disambiguation.
- Collections: Avoid type suffixes, use plural names (`nodes` over `nodeList`);
  avoid reification: name a set by its members, not its production (`contributors` over `closure`).

## Member Order

- Order members to reflect typical execution order; place a private helper directly below its last caller.
- Extract single-use helpers only when they remove deep nesting or give complex logic a self-explanatory name.

## Constants

- Extract magic literals to named constants; group related constants by a shared prefix

## Comments

- Use very sparingly and explain *why*, not *what* — let names carry the *what*
- Document the public API (purpose, conctracts)
- Name the authority for ground-truth claims — preferably a durable, checkable reference
- Avoid content that silently goes stale:
  - reference code symbols only via the language's checked link syntax
  - no file names or line numbers of moving targets (docs, plans, data files)
  - no inventories or counts of callers/implementations; no explanation of how *other* code uses this one
  - no issue IDs redundant to the commit message
- Avoid archeology that adds nothing about the current state:
  - no process history, date stamps, or references to removed code (except to prevent re-trying rejected approaches)
  - no vacuous `(user decision)` markers — state the concrete reason instead

-->
