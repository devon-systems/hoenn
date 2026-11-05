---
name: gh-cli
description: Standardize all GitHub work via `gh` CLI (repos, issues, PRs, reviews, Actions, labels, releases). Trigger on any GitHub URL (incl. deep links like /pull/123, /issues/123, #issuecomment-…).
---

# GitHub `gh` CLI

Use `gh` for all GitHub work. Discover flags and `--json` fields with `gh <command> --help` and `gh help formatting` instead of guessing or loading a cookbook. Verify auth once per session, or when debugging it, with `gh auth status`.

## Operating rules (do not skip)

1. **First-class commands first.** Use `gh issue`, `gh pr`, `gh repo`, `gh run`, `gh workflow`, `gh release`, and so on. Use `gh api` only when no dedicated command exists, and say which endpoint and why.
2. **Machine-readable output.** Use `--json <fields> -q '<jq>'` instead of parsing table output. Return only the value asked for, not the full blob.
3. **Explicit repo targeting.** Prefer `-R OWNER/REPO` outside a known checkout. If you infer the repo from the directory, confirm it with `gh repo view --json nameWithOwner -q .nameWithOwner`. For repeated work in one checkout, `gh repo set-default OWNER/REPO`.
4. **Confirm state changes.** Ask before destructive or hard-to-reverse changes: closing, merging, deleting, resolving or unresolving review threads, branch protections, permissions. Routine reversible output (review reply, comment, `gh pr checkout`) needs no extra gate. Keep settings changes small and reversible.

## PR review feedback

Inline review comments and thread resolution state need `gh api`, not first-class commands. Load `references/gh-commands.md` only for that workflow or for `gh api` REST and GraphQL fallbacks.

## Tooling

Scripts live in `scripts/` relative to this skill.

```bash
scripts/gh_context.sh   # gh version/auth + active repo, for debugging targeting
scripts/pr_feedback.sh -R OWNER/REPO PR_NUMBER > pr-feedback.json
```

Reply to review feedback:

```bash
# Inline review comment (REST)
scripts/pr_review_comment_reply.sh -R OWNER/REPO PR_NUMBER COMMENT_ID --body "..."

# Review thread (GraphQL)
scripts/pr_review_thread_reply.sh PRRT_... --body "..."

# Resolve a review thread (state change; --yes required)
scripts/pr_review_thread_resolve.sh --yes PRRT_...

# Reopen a resolved thread (state change; --yes required)
scripts/pr_review_thread_unresolve.sh --yes PRRT_...
```
