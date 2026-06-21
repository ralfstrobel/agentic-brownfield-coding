---
paths: "**/*.{{PROGRAMMING-LANGUAGE-FILE-EXTENSION}}"
---

# {{SUB-PROJECT-NAME}} {{SUB-PROJECT-PROGRAMMING-LANGUAGE}} code style

<!--
The sections below are EXAMPLE content, not rules to keep verbatim.
Keep entries short and example-driven, and only manifest conventions that
an autoformatter/linter does not already enforce.

## Baseline
- Base on an established style guide (e.g. PEP 8, Effective Go) and document any deviations

## Control Flow
- Prefer early return (`return`, `continue`, raise/throw) over nested `if`/`else` branches

## Error Handling
- Signal programming errors and runtime/data errors with distinct error types

## Naming
- Variables: avoid abbreviations (`count` over `cnt`); name collections in plural (`nodes` over `nodeList`)
- Booleans: read as an assertion (`hasErrors`, `isDraft`, `supportsRetry`)
- Classes: name after responsibility; avoid vague nouns like `Manager`, `Helper`, `Util`
- Methods: use a verb that describes how the result is produced (`build`, `resolve`, `parse`); reserve `get` for plain accessors

## Constants
- Extract magic literals to named constants; group related constants by a shared prefix

## Comments
- Use sparingly and explain *why*, not *what* — let names carry the *what*
- Document the public API (purpose, parameter and return types)
-->
