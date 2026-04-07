# Agentic Brownfield Coding

This Claude Code plugin repo assists complex software projects in their first steps towards agentic coding:
1. Scaffolding and gradually augmenting an existing codebase with an efficient harness setup.
2. Learning controlled agentic development workflows with a human-in-the-loop mindset.

## Background

The ABC project arose from a dissatisfaction with the built-in `/init` command of Claude Code,
which tries to derive agent instructions by scanning the existing repository content.
Especially for large and complex codebases, this approach generally leads to poor results,
as [summarized comprehensively](https://addyosmani.com/blog/agents-md/) by Google engineer Addy Osmani.

Another major inspiration was Dexter Horthy's work on [AI in Complex Codebases](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md)
which has become known for the RPI workflow. Together with co-founder Kyle Mistele, he promotes disciplined [harness engineering](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents)
and controlled interactive workflows to rein in the non-determinism of coding agents.

Details about the concrete hypotheses and design philosophy behind the ABC solutions
can be found in the full length [background essay](BACKGROUND.md).

## Installation

```bash
claude plugin marketplace add ralfstrobel/agentic-brownfield-coding

claude plugin install abc-init@agentic-brownfield-coding
claude plugin install abc@agentic-brownfield-coding
```

The separate init plugin is only required once for scaffolding and can be uninstalled after.

## Usage

### Scaffolding

These commands should be run using Opus as they require complex code base reasoning.

- [`/abc-init:standalone`](claude-plugins/abc-init/skills/standalone/SKILL.md) – Create initial Claude Code artifacts for single-application projects.
- [`/abc-init:monorepo`](claude-plugins/abc-init/skills/monorepo/SKILL.md) – Create initial Claude Code artifacts for monorepo-like projects.

- [`/abc-init:bashless`](claude-plugins/abc-init/skills/bashless/SKILL.md) – (Optional) Create MCP tool wrappers for relevant CLI commands
  and disable the `Bash` tool to prevent the agent from being attracted to inefficient shell access (particularly when indexed code search is available).

As even frontier models sometimes struggle to follow long workflows,
you may want to read the skill yourself and compare it against your output.
Also note that the result is not a turnkey solution and requires thorough testing for every new code base.

### Workflows

These commands provide basic examples for agentic workflows during code development.

- [`/abc:build`](claude-plugins/abc/commands/build.md) – Controlled agentic development workflow with explicit steps and human-in-the-loop checkpoints.
- [`/abc:learn`](claude-plugins/abc/commands/learn.md) – Codify implicit codebase knowledge from current conversation as agent context files.

While the commands can be used productively, their main purpose is to be illustrative.
You are encouraged to use them as templates to create your own custom workflows for your needs.
The references section below further links to various sources for more advanced workflow skills.

## FAQ

### Why only Claude Code?

At the time of writing, Claude Code is the only major coding assistant to support all artifacts
that form the base of the ABC solutions – primarily custom subagents, commands and hooks.

As long as no suitable standard for these solutions is adopted by a majority of assistants,
the focus will likely remain on Claude Code due to time constraints.

## Shoutouts and Related Projects

- The official Anthropic Claude Code plugins include a powerful toolkit for [skill creation](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator) that also works for workflow commands.
- [superpowers](https://github.com/obra/superpowers) is a well-known plugin for enhanced workflows.
- [GET SHIT DONE](https://github.com/gsd-build/get-shit-done) is a light-weight spec-driven approach for iterative development.
- [BMAD-ENHANCED](https://github.com/adolfoaranaes12/BMAD-ENHANCED/tree/main/.claude/skills) provides various skills to analyze existing architecture and develop specs.
- [The Delivery Gap](https://github.com/brennhill/Delivery-Gap-Toolkit) book and companion repo provide actionable approaches for agentic coding in production.

## License

This work is licensed under [Apache-2.0](LICENSE) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

Attribution via a link to this repository is appreciated. Feedback and contributors are welcome.
