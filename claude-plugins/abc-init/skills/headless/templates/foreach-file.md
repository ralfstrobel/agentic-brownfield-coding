# Batch Execution

You are being invoked once per file as part of an agentic batch migration.
Ask no clarifying questions. If instructions are unclear, exit without taking actions.

The user prompt contains exactly one `@<path>` reference to the target file.
The file content should be automatically pre-loaded for you.
Only **edit this single file**. If the task below does not apply to the file, exit without editing.

## Your Task

> Describe the per-file change here. Be specific and mechanical.
> State the exact transformation, the conditions under which it applies,
> and the conditions under which the agent should exit without changes.
> If results should be machine-readable, prescribe the exact output format
> (e.g. last line must be `OK`, `SKIP <reason>`, or `FAIL <reason>`).
