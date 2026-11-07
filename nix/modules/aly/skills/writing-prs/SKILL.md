---
name: writing-prs
description: Use when writing or revising a pull request title or body.
---

# Writing PRs

Inspect the diff against the base branch, linked issues, and repository instructions. Use only rationale those sources or the user's request support. Do not invent business reasons, impact, or test results. Apply `unslop` and `technical-writing` throughout.

## Template first

Before drafting, check the target repository for `pull_request_template.md` or `PULL_REQUEST_TEMPLATE.md` in the root, `docs/`, and `.github/`. Also check `.github/PULL_REQUEST_TEMPLATE/`.

If templates exist, use the one that best fits the change instead of the fallback below. Keep its headings, questions, and checklists. Fill placeholders with facts about the change. Remove author guidance only if the template says to. Ask the user only if you cannot infer the choice and it would materially affect the body.

Repository instructions for titles or bodies take precedence over PR templates. PR templates take precedence over the fallback defaults below.

## Title

Use Conventional Commit format: `type(scope): concise imperative summary`.

Choose the type for the primary change and the scope for the smallest clear component. Omit the scope if none fits. Name the concrete outcome. Prefer 72 characters or fewer, with no final period.

Good: `fix(notifications): clear retry timer on reconnect`
Bad: `feat: improve notifications`

## Fallback description

Use the shortest description that explains the change and its rationale. Omit headings, section labels, test-plan sections, checklists, dividers, generated-by footers, commit lists, diff stats, file inventories, and pasted test output.

Lead with what changes and why it matters. Use short paragraphs and everyday words. For a small change, a few sentences are usually enough. Stop when the reviewer can understand the problem and the result.

Explain behavior before implementation. Include a file, symbol, or internal mechanism only when it helps the reviewer understand the change or a tradeoff. Leave details that are already clear in the diff there. Avoid packing several technical facts into one sentence.

Use bullets when distinct changes are easier to scan that way. Do not turn every edited component into a bullet. Add migration limits, required follow-ups, or preserved behavior only when they affect how the reviewer should judge the change. Describe a material new test only when its coverage needs explanation.

Read the draft as someone who has not seen the conversation. Replace abstract summaries with concrete effects, explain necessary jargon, and cut repeated facts. Do not repeat the title or recount the work session. Link or close issues this PR completes, using the repository's syntax.

Dense draft:

```md
fix(notifications): clear retry timer on reconnect

The reconnect lifecycle now performs explicit teardown of the prior retry timer before reinitializing notification delivery, preventing overlapping retry scheduling and duplicate notification dispatch across connection transitions. Regression coverage validates notification deduplication while preserving initial connection behavior and retry cadence.
```

Clearer version of the same change:

```md
fix(notifications): clear retry timer on reconnect

After a reconnect, the old retry timer can send the same notification twice. Clear it before starting a new timer.
```

The timer explains the fix. The test and unchanged retry timing do not need a separate report here.

New feature example:

```md
feat(orders): export filtered orders as CSV

Operators must copy rows from the orders table by hand to analyze them in a spreadsheet.

The orders page now exports the filtered results as CSV, with one row per order. Each row includes the order ID, creation date, status, and total.
```

Migration example:

```md
feat(orders): store tenant_id on orders

Orders identify their tenant only through their account, so order queries cannot enforce tenant isolation directly.

The migration adds a nullable `tenant_id` and backfills it from each order's account. Writes populate `tenant_id` for new orders. Reads, API responses, and reports still use the account link.

A follow-up will require `tenant_id` on every order and enforce tenant isolation in queries.
```
