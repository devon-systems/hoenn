---
name: quality-code
description: Write beautiful, literate code anyone can understand. Use when implementing code changes or reviewing code. Do not use for browsing, explanation, diagnosis without implementation, generated code, or vendored code.
---

# Quality code

> **Readability first.** Write for the person who opens this file six months from now, or six minutes from now, with no context.

Write code that a maintainer can understand, change, and replace without carrying knowledge from this conversation forward.

## Honor scope and local conventions

Apply instructions in this order:

1. Explicit user requirements and repository instructions.
2. Language and repository conventions.
3. This skill.

Do not copy a local pattern that makes code unclear, couples unrelated parts, or creates a footgun. Explain why you depart from a convention.

Stay focused on the requested change. Do not restyle unrelated code. Fix an adjacent correctness problem and tell the user. If the fix materially expands the task, explain the expansion first.

## Names are the primary interface

- **Reveal intent.** Make a name answer why the symbol exists and how the code uses it.
- **Avoid abbreviations.** Write `customerAddress`, not `custAddr`. Accept established idioms such as `ctx`, `cfg`, `req`, and `err` when their meaning is obvious.
- **Avoid single-letter names.** Reserve them for universal idioms such as `i` and `j` for loop indices or `T` for a generic type parameter.
- **Reject LeetCode shortcuts.** Write `currentNode`, `previousValue`, `result`, and `answer`, not `curr`, `prev`, `res`, and `ans`.
- **Use pronounceable names.** Write `generationTimestamp` or `generation_timestamp`, not `genTs` or `gen_ts`.

Name booleans as questions or states, collections as plurals, and functions by their action. Include a unit when it prevents a mistake, such as `timeoutMs`. Name constants for domain rules, units, and policies. Keep self-evident literals inline.

Make function names disclose side effects. A query does not write, and a check does not mutate state. Expose mutation and externally visible work when callers need to know.

## Keep function contracts honest

> **A function's name and arguments are its contract.** Keep that contract easy to call correctly.

- Aim for zero to two arguments. Three can be clear. At four or more, reconsider the API. Use a named options object, a struct, or a smaller operation when positional arguments become hard to remember. Do not wrap arguments only to meet the count.
- Give each function one responsibility and one level of abstraction.
- Prefer plainly named steps to dense expressions and clever one-liners. Use early returns to keep the normal path visible.
- Extract code when the name adds meaning, the block has its own responsibility, or the code repeats. Do not hide one line in a helper.
- Treat function size and nesting as warning signs, not quotas. Bend the guideline when splitting the code would hide its real flow.

## Comment only what code cannot say

> **The code is the explanation.** Comments record the facts that code cannot.

Comment a non-obvious invariant, constraint, compatibility requirement, or design decision. Do not narrate syntax, restate identifiers, preserve chat history, or record rejected product decisions. Delete commented-out code. Never commit temporary code.

## Build parts that can change

> **Solve today's problem with tomorrow's load in mind.** Keep each part understandable without learning every part around it.

- Create clear internal and external boundaries between parts that can change or be rebuilt independently. Let callers depend on a small, explicit contract instead of implementation details.
- Give mutable or shared state one owner. The owner controls writes, lifetime, synchronization, and cleanup. Other parts use its contract instead of changing the state directly.
- Add an abstraction when a part has multiple plausible implementations, changes for different reasons than its callers, or makes its callers simpler behind a stable contract. Do not abstract an imagined future.
- Design each boundary for its real operating conditions. Consider unbounded input, concurrency, failure, cancellation, retries, timeouts, cleanup, and partial results. Add limits, pagination, streaming, batching, backpressure, or idempotency when needed. Keep these policies at the boundary.
- Make invalid states hard to represent. Validate at boundaries, define error behavior, release resources, and avoid surprising defaults.

## Work with the surrounding code

Before changing shared behavior, inspect its callers, dependencies, and relevant tests. Update every dependent file the change requires. For a local detail, inspect only enough context to make the change fit.

Make safe assumptions about small implementation details. Ask before changing product behavior, a public contract, data handling, or scope. Do not turn a one-off example, bug investigation, or rejected preference from the conversation into permanent product behavior.

Run the narrowest relevant check. Do not claim validation that you did not perform.
