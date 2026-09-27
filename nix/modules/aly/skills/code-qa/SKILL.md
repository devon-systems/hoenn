---
name: code-qa
description: Review handwritten source code against the quality-code standards. Use only when the user explicitly invokes $code-qa. Do not infer use from an ordinary request to review, inspect, or explain code.
disable-model-invocation: true
user-invocable: true
---

# Review code by impact

Follow repository instructions and language conventions before this skill.

Review only the requested change or scope. Inspect callers, tests, and surrounding code when needed to judge an issue. Do not edit files unless the user also asks for fixes.

## Apply the shared standards

Load the installed `$quality-code` skill. Treat it as the single source of truth for naming, function design, comments, boundaries, shared state, operating load, and what belongs in permanent code.

Check every applicable standard. Also check behavior, edge cases, failure paths, and tests. Report every meaningful problem, including style problems. Do not manufacture findings to fill the review.

## Rank findings by impact

- **Blocking.** Correctness, security, data loss, broken contracts, or unsafe normal use.
- **Important.** Coupled boundaries, interfaces that are easy to misuse, unbounded work, or code that is hard to understand or change.
- **Suggestion.** Naming, comments, structure, or style that reduces clarity without threatening behavior.

List findings from highest to lowest impact. For each finding, give the location, problem, consequence, and smallest useful fix. Keep the summary brief and place it after the findings.

If no findings remain, say so. Name any residual risk or validation gap that still matters.
