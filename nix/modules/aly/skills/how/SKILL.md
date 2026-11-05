---
name: how
description: 'Use for "how does X work", code walkthroughs before changing something, and placement / ownership / layering questions ("where should this live", "which package owns this", "is this the right layer"). Explains subsystem architecture, runtime flow, onboarding mental models. Use why for motivation.'
---

# How

Explore the codebase to answer "how does X work?" questions. Produce architectural explanations at the level of a senior engineer onboarding onto a subsystem, enough to build a working mental model, not so much that it reads like annotated source code.

## 1. Assess complexity

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

- **Inline (default).** A single module, a small utility, a narrow question such as "how does function X work", or anything you can trace by reading the relevant files yourself. Explore and answer directly, with no spawns, using the output format below. Reuse files already in context instead of paying a subagent to re-read them.
- **Parallel (exception).** A subsystem spanning multiple files or services with 2 to 4 genuinely independent angles, where parallel exploration saves real time. Go to step 2.

When in doubt, answer inline.

## 2. Explore (parallel only)

Decompose the question into 2 to 4 angles, each a distinct slice of the subsystem. Spawn all explorers in a single message, read-only, without setting `model` (inherit the parent), each with `references/explorer-prompt.md` and its angle filled in.

## 3. Synthesize (parallel only)

Synthesize the explorers' findings yourself, following the output format and communication style in `references/explainer-prompt.md`. Do not spawn a separate explainer. Check the code only to resolve contradictions or fill a gap the explorers flagged.

## 4. Present

Present the explanation. Light edits for clarity or context from the conversation are fine.

## Output format

Use the sections defined in `references/explainer-prompt.md`, dropping any that do not apply: Overview, Key Concepts, How It Works, Where Things Live, Gotchas.
