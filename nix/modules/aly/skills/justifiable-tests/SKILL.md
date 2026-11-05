---
name: justifiable-tests
description: Test code for meaningful failures that survive refactors. Use when writing or reviewing tests.
---

# Justifiable tests

Add or retain a test when it catches a plausible failure that affects required behavior. Name the behavior in the test. Add a comment only when the reason is not obvious.

- Derive expected results from requirements, documented contracts, or examples worked out independently of the implementation. Do not copy the implementation's logic into assertions.
- Test observable behavior through the narrowest interface that exposes the failure. Keep assertions valid when a refactor preserves that behavior.
- Assert exact strings, structure, or call order only when the contract requires them. Avoid checks of incidental wording or source text. Use snapshots only when the captured output is the behavior under test.
- Cover distinct failure modes. Extend existing tests before adding overlapping cases. Prioritize regressions, consequential boundaries, and error paths.
- Keep setup deterministic and readable. Reuse fixtures when they clarify the scenario. Mock external boundaries only as needed.
- Follow explicit test requirements. Otherwise, skip tests whose maintenance cost exceeds the failures they are likely to catch. Briefly explain significant behavior left untested.

If expected behavior is unclear, check existing requirements and conventions. Ask the user only when unresolved ambiguity changes what the test should assert.

For a regression, verify that the test fails for the original defect and passes with the fix when feasible.
