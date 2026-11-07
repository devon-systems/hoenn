---
name: quality-code
description: Use when implementing code changes or reviewing code. Do not use for browsing, explanation, diagnosis without implementation, generated code, or vendored code.
---

# Quality code

**Readability first.** Write code that a maintainer can understand, change, and replace with no context from this conversation.

## Honor scope and local conventions

Explicit user requirements and repository instructions outrank language and repository conventions, which outrank this skill.

Do not copy a local pattern that makes code unclear, couples unrelated parts, or creates a footgun. Explain why you depart from a convention.

Stay focused on the requested change. Do not restyle unrelated code. Fix an adjacent correctness problem and tell the user. If the fix materially expands the task, explain the expansion first.

## Names are the primary interface

- **Reveal intent.** Make a name answer why the symbol exists and how the code uses it.
- **Avoid abbreviations and LeetCode shortcuts.** Write pronounceable full words: `customerAddress`, `currentNode`, `previousValue`, and `generationTimestamp`, not `custAddr`, `curr`, `prev`, and `genTs`. Accept established idioms such as `ctx`, `cfg`, `req`, and `err` when their meaning is obvious.
- **Avoid single-letter names.** Reserve them for universal idioms such as `i` and `j` for loop indices or `T` for a generic type parameter.

Name booleans as questions or states, collections as plurals, and functions by their action. Include a unit when it prevents a mistake, such as `timeoutMs`. Name constants for domain rules, units, and policies. Keep self-evident literals inline.

Make function names disclose side effects. A query does not write, and a check does not mutate state. Expose mutation and externally visible work when callers need to know.

## Keep function contracts honest

A function's name and arguments are its contract. Keep that contract easy to call correctly.

- Aim for zero to two arguments. Three can be clear. At four or more, reconsider the API. Use a named options object, a struct, or a smaller operation when positional arguments become hard to remember. Do not wrap arguments only to meet the count.
- Give each function one responsibility and one level of abstraction.
- Prefer plainly named steps to dense expressions and clever one-liners. Use early returns to keep the normal path visible.
- Extract code when the name adds meaning, the block has its own responsibility, or the code repeats. Do not hide one line in a helper.
- Treat function size and nesting as warning signs, not quotas. Bend the guideline when splitting the code would hide its real flow.

## Comment only what code cannot say

Comment a non-obvious invariant, constraint, compatibility requirement, or design decision. Do not narrate syntax, restate identifiers, preserve chat history, or record rejected product decisions. Delete commented-out code. Never commit temporary code.

## Build parts that can change

Solve today's problem with tomorrow's load in mind.

- Do not build implicit state machines. Make state and event logic explicit.
- Create clear internal and external boundaries between parts that can change or be rebuilt independently. Let callers depend on a small, explicit contract instead of implementation details.
- Give mutable or shared state one owner. The owner controls writes, lifetime, synchronization, and cleanup. Other parts use its contract instead of changing the state directly.
- Add an abstraction when a part has multiple plausible implementations, changes for different reasons than its callers, or makes its callers simpler behind a stable contract. Do not abstract an imagined future. Count a verified fake as a plausible second implementation. Do not count an interface created only to mock one concrete dependency.
- Design each boundary for its real operating conditions. Consider unbounded input, concurrency, failure, cancellation, retries, timeouts, cleanup, and partial results. Add limits, pagination, streaming, batching, or backpressure when needed. Keep these policies at the boundary.
- Make invalid states hard to represent. Validate at boundaries, release resources, and avoid surprising defaults.
- Keep decision logic callable without I/O. Make parsing, calculation, and policy take values and return values or typed errors. Keep effects at the boundary. Put inverse operations such as parse/format and encode/decode behind one contract. Give value types real equality and make ordering deterministic.
- Pass clocks, random sources, ID generators, and external services in at the boundary. Supply real implementations through production wiring. Keep core code from reading ambient time, randomness, environment, or process globals.
- Give errors callers must act on a typed kind instead of a message string. Validate before mutating so failed calls can leave state unchanged. Make retryable operations idempotent.
- Parse untrusted input into a typed value or typed error. Never panic. Separate storage and wire types from domain types. Keep decoders for older versions when formats change.

## Work with the surrounding code

Before changing shared behavior, inspect its callers, dependencies, and relevant tests. Update every dependent file the change requires. For a local detail, inspect only enough context to make the change fit. Reuse existing types, contracts, and styles within the coedebase where possible.

Make safe assumptions about small implementation details. Ask before changing product behavior, a public contract, data handling, or scope. Do not turn a one-off example, bug investigation, or rejected preference from the conversation into permanent product behavior.

Run the narrowest relevant check. Do not claim validation that you did not perform.
