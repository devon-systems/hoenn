---
name: justifiable-tests
description: Test code for meaningful failures that survive refactors. Use when writing or reviewing tests.
---

# Justifiable tests

Add or retain a test when it catches a plausible failure that affects required behavior. Name the behavior in the test. Add a comment only when the reason is not obvious.

- Derive expected results from requirements, documented contracts, or examples worked out independently of the implementation. Do not copy the implementation's logic into assertions.
- Test observable behavior through the narrowest interface that exposes the failure. Keep assertions valid when a refactor preserves that behavior.
- Assert exact strings, structure, or call order only when the contract requires them. Avoid checks of incidental wording or source text. Use snapshots only when the captured output is the behavior under test.
- Cover distinct failure modes. Extend existing tests before adding overlapping cases. Prioritize regressions, consequential boundaries, and error paths. For a regression, verify that the test fails for the original defect and passes with the fix when feasible.
- Keep setup deterministic and readable. Inject or fake the clock and random seed; never sleep to await async work. Log seeds on failure so randomized failures reproduce from logs alone. Reuse fixtures when they clarify the scenario. Mock external boundaries only as needed.
- Follow explicit test requirements. Otherwise, skip tests whose maintenance cost exceeds the failures they are likely to catch. Briefly explain significant behavior left untested.

## When examples are weak

Reach for these only when their maintenance cost still passes the rule above.

- Prefer property tests over more examples when you can state a property without copying the implementation's logic: parse/print or encode/decode round-trips, idempotence, order-independence, invariant preservation, monotonicity. Favor empty, single, duplicate, unsorted, max-size, and Unicode inputs. Commit shrunk counterexamples as example regressions; generators may miss them later. Use an existing property library. Never add a dependency for one test.
- When direct assertions are hard, compare against a reference too simple to share the bug: brute-force scans for optimized queries, trivial cache models, or the old implementation during refactoring.
- For caches, queues, state machines, and other lifecycle code, compare random operation sequences against a simple model, such as a map. Catch ordering and interleaving bugs that single-operation examples miss.
- When storage backends, API clients, or fakes must agree, run one parametrized conformance suite against all implementations. Prefer a fake verified by the real implementation's tests to a mock.
- Assert error postconditions, not just failure: unchanged state, no partial writes, idempotent retries. Check error kinds or codes rather than messages.
- For storage and wire formats, commit payloads from old versions and verify current code reads them. Never regenerate compatibility fixtures with current code; that tests the code against itself.
- Fuzz parsers, decoders, and deserializers that accept untrusted input. Assert they neither crash nor hang. Seed the corpus with past regressions.

If expected behavior is unclear, check existing requirements and conventions. Ask the user only when unresolved ambiguity changes what the test should assert.
