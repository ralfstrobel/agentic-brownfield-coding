# Agentic Brownfield Coding

This Claude Code plugin repository provides skills to support agentic coding for large software projects in two ways:
1. Scaffolding and gradually augmenting an existing codebase with efficient and maintainable agent context.
2. Executing controlled agentic development workflows with a human-in-the-loop mindset.

## Background

The ABC project arose from a dissatisfaction with the built-in `/init` command of Claude Code,
which tries to derive agent instructions by scanning the existing repository content.
Especially for large and complex codebases, this approach generally leads to poor results,
as [summarized comprehensively](https://addyosmani.com/blog/agents-md/) by Google engineer Addy Osmani.

Details about the hypotheses and design philosophy behind the proposed solutions
can be found in the full length [background document](BACKGROUND.md).

## Installation

```bash
claude plugin marketplace add ralfstrobel/agentic-brownfield-coding

claude plugin install abc-init@agentic-brownfield-coding
claude plugin install abc@agentic-brownfield-coding
```

The separate init plugin is only required once for initialization and can be uninstalled after.
The main ABC plugin provides development workflows, which can be either used as-is or copied as templates.

## Usage

- [`/abc-init:standalone`](claude-plugins/abc-init/skills/standalone/SKILL.md) — Create initial Claude Code artifacts for single-application projects.
- [`/abc-init:monorepo`](claude-plugins/abc-init/skills/monorepo/SKILL.md) — Create initial Claude Code artifacts for monorepo-like projects.

- [`/abc:build`](claude-plugins/abc/commands/build.md) — Controlled agentic development workflow with explicit steps and human-in-the-loop checkpoints.
- [`/abc:learn`](claude-plugins/abc/commands/learn.md) — Codify implicit codebase knowlege from current conversation as agent context files.

## FAQ

### Why only Claude Code?
At the time of writing, Claude Code is the only major coding assistant to support the artifacts
that form the base of the ABC solutions, primarily custom subagents and commands.

As long as no suitable standard for these solutions is adopted by a majority of assistants,
the focus will likely remain on Claude Code due to time constraints.

## Shoutouts and Related Projects

- The official Anthropic Claude Code plugins include a powerful toolkit for [skill creation](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator) that also works for command workflows.
- [superpowers](https://github.com/obra/superpowers) is a well-known plugin for enhanced workflows.
- [GET SHIT DONE](https://github.com/gsd-build/get-shit-done) is a light-weight approach to interactive spec-driven workflows for complex development tasks.
- [BMAD-ENHANCED](https://github.com/adolfoaranaes12/BMAD-ENHANCED/tree/main/.claude/skills) provides various skills to analyze existing architecture and develop specs.

## License

This work is licensed under [Apache-2.0](LICENSE) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

Attribution via a link to this repository is appreciated.