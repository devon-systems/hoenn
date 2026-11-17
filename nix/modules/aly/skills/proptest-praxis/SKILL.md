---
name: proptest-praxis
description: "Build model-based property-testing suites to find correctness bugs, then reduce failures to deterministic regression tests and minimal fixes. Use for broad property-testing coverage of custom data structures and algorithms, including operation-sequence generators and independent reference models."
---

# Agents and property tests: investigation prompt

Use these instructions in the target repository. Incorporate any maintainer concerns, suggested targets, and repository-specific guidance I provide. Own the investigation and keep exploring as findings suggest new targets.

## 1. Objective and deliverables

Find correctness bugs across the repository by building and running property-testing machinery. Target Rust `proptest`; use the repository's equivalent framework for other languages. Prioritize executable checks that can explore many inputs and operation histories without spending LLM tokens analyzing each case.

Maintain a discovery branch containing reference implementations, generators, operation ASTs, invariants, and investigative tests. This suite can be large, repetitive, and unoptimized. Its correctness matters; production-level performance and polish usually don't. Run it locally and retain reproducible failures.

For each confirmed bug, produce a focused PR containing a deterministic regression test and a minimal fix, independently reviewable without the discovery suite. Bugs found through code inspection qualify too. Keep ambiguous findings separate from established contract violations.

## 2. Direct the investigation

Use the target/technique list to recognize testing opportunities from code behavior, not just names. Look for derived state, cache invalidation, incremental updates, secondary indexes, graph reachability, state transitions, aliasing, and ordering dependencies across module boundaries.

Use these lenses throughout the investigation:

- **History-dependent behavior:** identical logical contents can conceal different caches, allocation histories, sharing, and deferred work. Vary how states are reached and when they are observed.
- **Generator support and sampling distribution:** omitted interactions are unreachable; possible interactions may still be vanishingly rare. Inspect and improve the generated behavior before relying on increased run volume.
- **Oracle independence and common-mode failures:** independently express the intended behavior. Shared algorithms, production helpers, and copied assumptions can make the implementation and model agree on the same wrong answer.
- **Search feedback:** initially treat no findings as a coverage problem. Investigate missing operations, transitions, histories, and interactions; test the harness's sensitivity to plausible defects. For failures or suspicious behavior, investigate both the implementation and test assumptions, then dispatch worktree agents to explore the same mechanism in related operations and structurally similar code.

Prioritize complex implementations with simple correctness models. An optimized structure may be modeled by a Vec and linear scans; incremental metadata by full recomputation; a planner by a small interpreter or exhaustive search over small instances.

Choose and combine techniques using your own judgment. Build operation-sequence ASTs, reference models, generators, and invariant checks appropriate to each target. Consider interactions between subsystems and equivalent behavior exposed through different APIs. The list is non-exhaustive; propose additional approaches where the code suggests them.

Use maintainer concerns, implementation complexity, suspicious assumptions, and feasibility of a strong correctness check to prioritize work.

Use a strong planning agent to select targets and assess findings, an orchestration agent to coordinate work, and implementation agents to build and run tests. Combine roles where appropriate. Give each worker a bounded investigation in its own worktree, with the relevant contract, candidate techniques, and expected deliverables. Track active targets, findings, and follow-up leads so workers can explore independently without duplicating work. Consolidate useful test machinery into the discovery branch and dispatch further investigations as capacity becomes available.

**Adaptive search allocation — exploration/exploitation:** get promising harnesses running early and keep established searches executing while agents develop others. Choose among new targets, stronger oracles, broader generators, and longer runs using expected information gain relative to implementation and execution cost. Maintain breadth across independent mechanisms while deepening productive targets and investigating quiet targets' coverage gaps. Passing harnesses remain reusable search machinery. Retain runnable commands, tested revisions, observed coverage, and unresolved blind spots so investigations can be resumed and extended.

Own the technical investigation and delegation. Bring me findings, consequential ambiguities, and questions requiring repository or organizational context.

## 3. Recognize testing opportunities

Use these as starting points. Infer additional properties from the implementation's responsibilities and the relationships between APIs.

**Partial oracles and solution checking:** exploit outputs that are cheaper to validate than to compute. Check path edges, dependency ordering, preserved fields, and index consistency independently. Distinguish soundness from completeness: every emitted node being reachable does not establish that every reachable node was emitted. Combine these checks with reference models, metamorphic relations, and small-instance exhaustive oracles to cover different failure modes.

- **Custom collections, indexes, arenas, interning, deduplication — model-based differential testing:** compare against a simple Vec, map, or set model. Exercise overwrite, deletion, reinsertion, collisions, index reuse, duplicate inputs, and empty/singleton states. Check contents, lookup results, multiplicity, and relationships between primary and secondary indexes.
- **Caches, incremental summaries, derived metadata — recomputation oracles:** compare cached or incrementally maintained results with independent full recomputation. Warm caches, mutate through every relevant API, and query again. Include transitive dependencies and changes that preserve size while altering contents.
- **Graphs, traversals, dependency analysis:** compare reachability and membership with a straightforward traversal or small-instance enumeration. Generate cycles where representable, diamonds, shared descendants, disconnected components, multiple roots, redundant edges, and deletion holes. Check returned paths, dependency ordering, and preservation of payloads under graph rewrites.
- **Query planners, optimizers, AST rewrites — semantic preservation:** evaluate original and transformed forms with a small interpreter or compare plans against a simple semantic model. For small instances, enumerate candidates to check feasibility or optimality when promised. Check required dependencies, output fields, aliases, and conditional behavior; equivalent plans need not have identical structure.
- **State machines, transactions, staged builders — fault injection, failure atomicity, recovery invariants:** model state transitions and operation results. Generate failure schedules alongside operations; use test doubles to make a dependency return an error on call k. Exercise repeated transitions, rollback, retry, partial progress, and continued use after errors. Check intermediate state and recovery against the operation's actual contract, including atomicity where promised.
- **Parsers, printers, serializers, encoders — grammar-aware generation and round trips:** generate structured values for encode/decode and print/parse round trips. Generate malformed, truncated, boundary-sized, and unusual external inputs separately to seek panics and incorrect acceptance. Check semantic preservation where formatting or representation is intentionally normalized; don't normalize away meaningful differences.
- **Representation boundaries — boundary-value analysis:** exercise empty/singleton inputs, integer extrema, narrowing conversions, signedness, overflow, sentinels, and inclusive/exclusive ranges. Model intended size/offset arithmetic with checked or wider intermediates; compare range behavior against explicit sequences. For text, distinguish byte offsets, Unicode scalar values, and grapheme boundaries according to the API. Generate multibyte text, combining sequences, and escapes; check conversions and indexing at their boundaries.
- **Equality, hashing, ordering, normalization:** generate equivalent values through different construction histories and representations. Check that equal values hash equally, ordering agrees with the promised semantics, and canonicalization preserves meaning and is stable when repeated. Generate equivalent pairs deliberately; independently random pairs seldom compare equal.
- **Bulk APIs, alternate implementations, execution modes — metamorphic testing:** generate related executions with known relationships between their results. Compare batch operations with equivalent individual operations, incremental construction with rebuilding, and alternate API paths that promise equivalent results. Vary insertion order, traversal order, chunk boundaries, and configuration independently when they should not affect semantics.
- **Clone, snapshot, sharing, copy-on-write:** branch from shared state, mutate each branch, and check isolation or propagation as promised. Include nested/shared objects and mutations after reads have initialized lazy state.
- **Validators and invariant auditors:** construct a valid object, introduce a targeted defect, and check that the auditor detects it. Also verify acceptance of valid objects. Vary corruption location and surrounding structure; test the checker itself where other properties rely on it.

Use bounded exhaustive enumeration when small domains make it practical, alongside randomized generation. Randomized testing does not exhaust the full state space. Keep checks cheap enough to run extensively, and separate expensive small-instance oracles from larger stress cases.

## 4. Build effective generators and operation-sequence tests

**Model-based stateful differential testing:** represent interactions as an explicit operation enum/AST and replay shared histories against production and an independent reference model. Include mutations, reads, iteration, bulk operations, clear/reset, and clone/snapshot where relevant. Generate configuration and initial state as well as histories. Use ordinary compositional `proptest` strategies; use `proptest-state-machine` when state-dependent transitions simplify the harness.

**Constructive generation and near-valid inputs:** generate valid ASTs, graphs, and requests to reach deep behavior; derive invalid variants by selectively violating one constraint, such as a dangling reference, inconsistent length, duplicate identifier, or truncated encoding. Control depth, breadth, size, and sharing. Use `prop_recursive` for recursive trees/ASTs; generate graph references separately to control sharing and cycles. Keep unconstrained external-input tests too.

**Input-space partitioning and combinatorial interaction coverage:** define meaningful state, operand, operation, and configuration classes, then cross them deliberately. Example: overwrite × warmed cache × shared snapshot × capacity boundary. Enumerate small products or use targeted pairwise/t-way combinations as dimensions grow; inspect which combinations actually occur. Exercise values immediately below, at, and above implementation thresholds.

Generate interacting operands. Use small key/value domains to produce overwrites, repeated access, shared dependencies, and duplicate values. Mix existing, absent, previously removed, and fresh identifiers. Generate unequal replacement values deliberately so stale results remain observable. Include larger domains and sizes separately to exercise growth and capacity boundaries.

For APIs returning handles, maintain logical identities mapped to each implementation's handles. Reuse previous results in later operations, retain stale handles for targeted tests where the API permits them, and distinguish identity from allocation order. Select operands from reference state rather than allowing a defective production result to determine which cases are tested.

Combine general random histories with targeted patterns: warm → mutate → query; remove → reinsert; allocate → free → reuse; populate → clear → repopulate; snapshot → mutate either branch → inspect both; failed operation → continued use. Embed patterns in arbitrary prefixes, suffixes, and intervening operations. Generate both final structure and construction history: the same contents reached through different mutations may expose different bugs.

**Swarm testing and operation-mix diversification:** vary enabled operation subsets and weights across cases. Frequent clear/remove operations can prevent growth; frequent reads can prevent lazy state from remaining uninitialized. Include growth-heavy, mutation-heavy, read-heavy, and reuse-heavy histories where useful. Keep broad mixed histories and occasional longer traces too.

Use state-aware generation to reach interesting states efficiently. Preserve explicit coverage of missing keys, duplicate operations, malformed inputs, and rejection paths. Don't constrain tests to current caller habits or discard a failure merely because an outer layer usually avoids that input. Distinguish an actual API restriction from an incidental calling pattern; respect Rust memory-safety requirements when invoking unsafe APIs.

Design dependencies for shrinking. Prefer constructing related inputs with `prop_map`, `prop_flat_map`, or state-machine strategies over rejecting most generated cases with filters or `prop_assume!`. Account for references to objects created earlier when shrinking deletes operations. Avoid harnesses where shrinking turns most commands into silently skipped work. Keep generation and replay deterministic, including operand selection from collections; avoid hidden randomness inside the test body.

**Fault activation and observability (RIPR: reachability, infection, propagation, revealability):** detecting a defect requires reaching the faulty code, causing incorrect state, propagating it to an observable result, and checking that result. Design histories that complete this chain. Compare operation results and observable state against the model, and independently recompute invariants where useful. Treat reads as operations: they may populate caches or trigger lazy work. Ensure extra checking doesn't accidentally warm every cache or force every deferred computation; include histories with delayed reads as well as frequent reads.

**Behavioral coverage:** inspect generated traces and measure meaningful events: successful mutations, overwrites, stale-handle attempts, cache hits after mutation, size/depth reached, operation combinations, rejection rates. Look for mostly empty states, no-ops, early termination, and unexercised variants. Use code coverage when available to identify missed branches, then adjust strategies to reach them. Increasing case count won't fix a generator that rarely creates the interaction you're looking for.

**Mutation testing as harness calibration:** temporarily omit a cache invalidation, skip a secondary-index update, or mishandle an overwrite. Check that generated histories reach the affected state and that assertions detect the wrong behavior. Use surviving mutations to identify missing RIPR links: inspect generation, fault activation, propagation, and the oracle, then strengthen the harness and rerun. Revert deliberate mutations after the experiment.

Retain the initial state, configuration, operation trace, and failure location. Enable failure persistence and shrink counterexamples. Save explicit reproductions as well as seeds, since strategy changes can change what a seed generates.

## 5. Investigate failures

Reproduce each failure and identify the first divergence. Inspect both the production implementation and the oracle. Check that the model independently expresses the intended behavior and that adapters, handle mappings, normalization, and comparison logic aren't hiding or inventing differences.

Establish the concrete contract violation: stale data, lost or duplicated values, incorrect dependencies, inconsistent equality, unexpected panic, or another demonstrable defect. A data structure or algorithm violation is sufficient; an end-to-end user-input reproduction is not required. Surface genuine ambiguity for discussion instead of inventing a specification to make the test pass.

**Counterexample generalization and causal isolation:** use the minimized witness to form a hypothesis about the violated invariant. Vary suspected conditions individually and in combination: values, topology, sharing, operation ordering, intervening mutations, and prior reads. Determine when the failure appears or disappears; distinguish triggering conditions from incidental structure. Encode the resulting failure family in generators.

**Variant analysis:** inspect adjacent operations, alternate construction paths, related cached state, and structurally similar implementations for the same mechanism. Dispatch agents to test those leads, including alternate entry points that maintain the same invariant.

**Root-cause clustering:** compare findings by established mechanism and repair scope. Different traces or panic sites may share one cause; similar symptoms may have independent causes. Group counterexamples resolved by the same invariant repair, and track independent defects separately. Let this analysis determine distinct bugs and PR boundaries.

Reduce the failure to a readable deterministic unit test with explicit expected behavior. Confirm it fails against the unmodified production code for the claimed reason. A seed, timeout, or disagreement with an opaque generated model alone is not the final deliverable.

## 6. Extract reviewable fixes

**Security-sensitive findings:** bring potential security implications to me privately and use the organization's internal security process or the project's private reporting channel. Keep related reproductions, fixes, and discovery artifacts private until cleared for disclosure; do not publish them in public issues, PRs, or branches.

Use a fresh branch from the repository's main development branch for each distinct bug. Include the standalone regression test and the smallest complete fix. Keep generated models, broad property suites, exploratory scaffolding, and unrelated cleanup on the discovery branch. If fixes genuinely depend on one another, make that dependency explicit.

Verify the regression fails before the fix and passes after it. In an investigative worktree, run the original discovery property and the generalized failure-family generators against the candidate fix, including fresh generated cases. Check that the repair restores the invariant across related operations and entry points. Run relevant existing tests and repository-required checks. Keep this broader validation machinery on the discovery branch.

Write the PR around the concrete trigger, incorrect behavior, expected result, and fix. Link the discovery branch or relevant investigation for background. State validation accurately and distinguish a demonstrated contract violation from any unproven application-level impact. Make the patch understandable to a reviewer who has never seen this prompt or the generated suite.

After filing each PR, merge its validated fix branch into the discovery branch and continue searching past the resolved failure.

Keep exploring. Feed confirmed failures and suspicious patterns back into target selection, dispatch additional work, and report findings and consequential questions as they arise.
