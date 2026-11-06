---
name: writing-prs
description: Use when writing or revising a pull request title or body.
---

# Writing PRs

Inspect the diff against the base branch, linked issues, and repository instructions. Use only rationale those sources or the user's request support. Do not invent business reasons, impact, or test results. Apply `unslop` and `technical-writing` throughout.

## Template first

Before drafting, check the target repository for `pull_request_template.md` or `PULL_REQUEST_TEMPLATE.md` in the root, `docs/`, and `.github/`. Also check `.github/PULL_REQUEST_TEMPLATE/`.

If templates exist, use the one that best fits the change instead of the fallback below. Keep its headings, questions, and checklists. Fill placeholders with facts about the change. Remove author guidance only if the template says to. Ask the user only if you cannot infer the choice and it would materially affect the body.

Repository instructions for titles or bodies override the defaults below.

## Title

Use Conventional Commit format: `type(scope): concise imperative summary`.

Choose the type for the primary change and the scope for the smallest clear component. Omit the scope if none fits. Name the concrete outcome. Prefer 72 characters or fewer, with no final period.

## Fallback description

Use the shortest description that explains the change and its rationale. Omit headings, section labels, test-plan sections, checklists, dividers, generated-by footers, commit lists, diff stats, file inventories, and pasted test output.

1. Open with one or two sentences about the current behavior, constraint, or goal and why the change is needed.
2. Describe the material changes in review order and say who or what notices a behavior change. Use bullets for distinct changes and prose for a connected sequence. Name modules, symbols, or files only when they help the reviewer navigate. Describe a material new test as a change, without a validation report.
3. Add a final short paragraph about preserved behavior, migration or rollout limits, or required follow-ups only if reviewers need it to judge the change.

Link or close issues this PR completes, using the repository's syntax. Replace vague claims such as "improve", "various", "robust", or "comprehensive" with exact effects. Do not repeat the title.

Bug fix example:

```md
fix(notifications): clear retry timer on reconnect

After a reconnect, the old retry timer remains active, so the client can receive the same notification twice.

- Clear the old retry timer before starting a new one.
- Add a regression test for duplicate notifications after a reconnect.

Notification delivery on the first connection and retry timing stay the same.
```

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
