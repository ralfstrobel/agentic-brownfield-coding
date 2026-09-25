---
paths: "**/{{GLOB-PATTERN-MATCHING-ONLY-A-TEST-FILE}}"
---

# {{SUB-PROJECT-NAME}} {{TESTING-FRAMEWORK-NAME}} conventions

<!--
The sections below are EXAMPLE content, not rules to keep verbatim.
Keep entries short and example-driven, and capture conventions a contributor
must follow — how to structure, name, reuse and run this project's tests.

## Structure

- Extend the project's shared base test case; name tests after the behavior under test (e.g. `pickTemplate` → `testPickTemplate`, `testPickTemplateEmptyFallback`)

## Scope

- Prefer the lowest test level that exercises the behavior; keep fast unit tests separate from slower integration/end-to-end tests

## Durability

- Aim for **end-to-end blackbox testing** that verifies intended outcomes and can easily be modified/extended;
  avoid heavy mocking that emulates implementation details of dependencies (breaking on dependency changes is desired).
- **No absence-only tests.** An assertion that something is *not* there will not regress on a dead surface.
  Precede the absence with a liveness anchor in the same method.

## Reusability

- Prepare shared fixtures in setup hooks rather than per test; centralize repeating patterns in helpers or an abstract base test
- Prefer parameterized/data-driven cases over near-duplicate test methods; weave new coverage into existing tests where it fits

## Isolation

- Keep tests independent and deterministic — no shared mutable state, no reliance on execution order or wall-clock time

## Language

- Keep test names, data and examples in English unless language itself is the aspect under test

## Running

- Run the affected tests after changing a test or its implementation (e.g. `<test runner command>`)

-->
