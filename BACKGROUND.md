# Agentic Brownfield Coding - Background

This document details perceived pitfalls and antipatterns in the way agent instructions are integrated
into (large) code repositories, as well as the alternatives and solutions proposed by the ABC project.

## Antipattern: Documentation as Agent Instructions

The reflexive approach taken by many developers when writing agent instructions is to structure them 
like classical internal software documentation or even feed existing documentation to the coding agent.
However, documentation is written to address the needs and limitations of humans, which are very different from those of LLM agents.

The primary need addressed by documentation is the fact that humans struggle to read through an entire codebase and understand it.
This is due to both limited reading speed but also the small "context window" of the brain.
Humans can only absorb [around seven chunks](https://en.wikipedia.org/wiki/The_Magical_Number_Seven,_Plus_or_Minus_Two) of information at once to reason about,
though they make up for this by their ability to retrain their neural pathways while reasoning,
integrating more and more information into complex domain knowledge.
This is why human documentation typically begins with very brief overview summaries and introduction of basic principles,
before systematically introducing more details, with the purpose of slowly building the required long-term memory structures.

LLMs are capable of ingesting tens of thousands of text tokens in a short time, detecting and replicating common patterns,
and reasoning about the entire content at once, albeit at a much more superficial level.
They hardly benefit from a structured introduction, nor do they retain acquired concepts long-term.
If the provided documentation is not correctly tailored to each task at hand,
agent performance can suffer due irrelevant instructions competing for attention (priority saturation).

Hence, simply reading from the codebase as the primary source of truth is advisable here –
especially since this approach also avoids the common problem of [documentation drift](https://gaudion.dev/blog/documentation-drift).

### Alternative: Explorer Agents as Context Primers

The challenge is to feed the agent with the right codebase excerpts that are relevant to each task.
Loading irrelevant sections leads not only to wasted compute resources
but also worse outcomes [due to a noisier context window](https://arxiv.org/abs/2510.05381).

Claude Code comes with a built-in solution in the form of the general-purpose "[Explore](https://code.claude.com/docs/en/sub-agents#built-in-subagents)" subagent,
which can navigate the filesystem, read files, and search for patterns on behalf of the primary agent.
Developers can lean into this concept by defining custom explorer agents tailored to the structure of their codebase.
This way the agent already knows which directories to look in, how to interpret naming conventions,
and which structural aspects of a component are most relevant to return.
This also removes the need for such navigational information in the central CLAUDE.md,
keeping the primary context window clean and focused on the task.

Advanced explorer agents can be instructed to enrich and contextualize their findings,
much like a senior developer would brief a colleague before handing off a task. Such a primer may include:
which parts of the codebase need to be modified, where similar solution patterns already exist,
what vocabulary and conventions are in use, and which tests should be run to validate changes.

## Antipattern: Intransparent Automatic Memory

Large, organically grown codebases are notorious for being understood only by the engineers who have
accumulated years of tribal knowledge (conventions, past architectural decisions, implicit constraints).
In the context of AI agent, the term [Context Debt](https://medium.com/@more.emanuel/standardizing-the-context-for-ai-agents-in-software-development-a-controlled-reproducible-and-d17dce563a11) has been coined to describe 
this lack of implicit knowledge that prevents agents to work autonomously with a codebase.

Developers working with a coding agent need to pay this debt by providing explicit explanations and corrections.
The natural desire is for the agent to retain such knowledge beyond the current session context,
as well as any hot memory mechanisms such as plans or task lists.

Claude Code includes a built-in automatic cold memory feature where the agent can write observations
to persistent files that are loaded into every following session.
More sophisticated solutions involve external knowledge bases or RAG-based retrieval systems.

All of these mechanisms are generally inadvisable for large coding projects for several reasons:
1. They are not coupled to the code and tend to drift out of sync similar to documentation as the project evolves.
2. They add persistent noise to the agent's context, as entire memories or indexes are loaded unconditionally,
   contributing to priority saturation and [anchoring bias](https://arxiv.org/abs/2412.06593).
3. Their automatically accumulated content is often intransparent and challenging to evaluate or iterate upon.
4. Solutions without a shared memory storage require redundant effort between team members
   and lead to inconsistent agent behavior.

### Alternative: Path-Specific Codified Context

Means to embed context directly into the codebase are already part of common programming best practices,
such as descriptive naming, consistent structure, and code comments that preserve the reasoning behind chosen solutions.
Investing in code clarity should always be preferred over using memory mechanisms as a crutch.
Agents tend to mimic existing code style, so given an intuitively readable codebase,
they will also produce output that is easier for humans to read and understand.

Implicit knowledge that cannot be expressed through code alone can still be [codified](https://arxiv.org/abs/2602.20478)
as a variety of different artifacts that Claude Code provides. Knowledge manifested in this way
is shared directly alongside the code and subject to the same version-control and review processes.

The naive approach for this is a central CLAUDE.md file at the project root.
However, for large code bases, this approach does not scale well and leads to significant context waste,
as this file is injected into every conversation and subagent. While it is possible to offload content
into supplemental files via Markdown links for progressive disclosure, this introduces an element of
non-determinism, as the agent must actively decide to read the referenced file.

A better strategy is to take advantage of the fact that knowledge requirement in codebases is typically aligned
with the hierarchy of the file system. Few global conventions apply project-wide,
while most domain-specific knowledge is limited to particular subsystems.
Claude Code provides several mechanisms to define context for dedicated scopes:
- [CLAUDE.md](https://code.claude.com/docs/en/memory#how-claude-md-files-load) files can be placed
  at any level of the directory tree, not just at the project root.
  This is the easiest way to define context that is automatically injected into the agent
  only when it first reads a file from a given namespace.
- [Rules](https://code.claude.com/docs/en/memory#path-specific-rules) offer even more precision:
  they can be scoped to load when the agent reads specific file paths (`src/auth/**/*`) or types (`**/*.ts`).
  Like the CLAUDE.md, a `.claude/rules` directory can also be placed in any subdirectory.
- [Skills](https://code.claude.com/docs/en/skills#automatic-discovery-from-nested-directories) can be defined
  for subdirectories in the same way, although this will only inform the agent of the newly available skill
  upon first read access. It is then still up to the agent to invoke it, again introducing non-deterministic behavior.
- [Subagents](https://code.claude.com/docs/en/sub-agents) can also be designed as carriers of specific context,
  such as in the previously discussed explorer agents. This is once more a non-deterministic approach
  that may require significant instruction tuning to ensure agents are used reliably for a given subsystem task.

While these artifacts are effective at reducing context debt, it requires continuous developer discipline to curate them.
This can be partially offset by incorporating their creation into automated workflows (see next section).

## Antipattern: CLAUDE.md With Vague Guardrails

Adding instructions to the central CLAUDE.md is often the first way developers learn to modify agent behavior.
In an attempt to keep these files brief, a common pitfall is to simply include broad directives,
such as aspirational statements about code quality and engineering standards. Another commonly observed
pattern is the degeneration into blanket prohibition lists against previous undesired behavior,
such as scope creep, code duplication, or incomplete testing.

These practices reflect a tendency to humanize the LLM due to its ability to communicate in natural language.
The underlying assumption is that the agent will meticulously check each action against every stated rule,
much as a conscientious developer can be inspired to internalize a team's engineering mindset.
In practice, however, these directives are merely token sequences in the model context window
that exert a diffuse, probabilistic influence on the agent output. They do not function as enforceable constraints,
especially if they require a deep and intuitive understanding of human value concepts not shared by LLMs.

However, it is easy to fall into the trap of believing that such directives are indeed working, because they can
significantly influence the communication style and vocabulary of the agent. Any general rules given to a model tend
to make it more verbose in justifying its decisions, framed in the language the developer used.
But this is not necessarily proof that the agent is actually making meaningfully better decisions.
In fact, a growing volume of abstract rules contributes once again to priority saturation,
potentially drowning out the specific, actionable instructions that could positively influence outcomes.

From a technical perspective it should also be noted that adding concrete behavioral modifiers to CLAUDE.md
will often be unsuccessful. The reason is that its content is [specifically prefaced](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
to the model in a way that declares it as contextual information, not instructions,
so that it does not interfere with the actual user prompt.

### Alternative: Workflows With Explicit Steps

A proven way to produce reliable and verifiable results even from LLMs is explicit procedural instruction.
Current models have become highly capable at following concrete, step-by-step protocols in the user prompt text.

In Claude Code, this is achieved through [commands and skills](https://code.claude.com/docs/en/skills) –
version-controlled prompt templates that can also incorporate user-given arguments.
A development workflow, for example, can reframe an informal user request into a controlled process 
including requirement engineering, research, planning, implementation, and verification stages.
The human developer can remain in the loop at defined checkpoints, maintaining control over architectural choices.

Unlike abstract guardrails, concrete protocols are empirically testable and can be iterated upon
if they produce poor results under certain conditions. They also tend to remain consistent when
switching between different LLM models of equal quality and can be backtested on new model generations.

This shift in strategy reflects a necessary general change in how agentic systems are understood.
The approachable natural-language interface invites the expectation that an agent can be treated
as a general problem solver that only requires an objecive and will autonomously find its way to a good solution.
In practice, these systems are best used as highly sophisticated workflow automation.
They excel at executing well-defined processes and making well-defined decisions with precision and speed,
but they do not (yet) replace the need for a human to decompose problems, define approaches, and evaluate outcomes.
