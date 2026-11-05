# GitHub `gh` CLI: PR review feedback and `gh api` fallback

Load this file only for the PR review feedback workflow or a `gh api` fallback. For everything else, run `gh <command> --help` and `gh help formatting`.

## PR review feedback workflow

`gh` surfaces PR reviews and PR (issue) comments directly, but inline review comments and per-thread resolution state require `gh api`. Use the bundled scripts for this workflow.

### Read all feedback for a PR

```bash
scripts/pr_feedback.sh -R OWNER/REPO PR_NUMBER > pr-feedback.json
```

The script emits a single JSON object with `pr` (metadata + reviews + PR comments from `gh pr view`), `reviewComments` (inline comments via REST), and `reviewThreads` (GraphQL, including resolved/outdated state). It warns when any fetched set may be truncated.

Common projections:

```bash
# Review summaries
jq -r '.pr.reviews[]? | "\(.author.login)\t\(.state)\t\(.submittedAt // .createdAt // "")\t\(.url)"' pr-feedback.json

# PR (issue) comments
jq -r '.pr.comments[]? | "\(.author.login)\t\(.createdAt)\t\(.url)\n\(.body)\n"' pr-feedback.json

# Inline review comments (REST objects)
jq -r '.reviewComments[]? | "\(.user.login)\t\(.path):\(.line // 0)\t\(.html_url)\n\(.body)\n"' pr-feedback.json

# Unresolved review threads (GraphQL)
jq -r '.reviewThreads[] | select(.isResolved == false and .isOutdated == false) | "\(.id)\t\(.path):\(.line // 0)"' pr-feedback.json
```

### Reply back

Top-level PR comment:

```bash
gh pr comment -R OWNER/REPO PR_NUMBER --body "..."
```

General review comment:

```bash
gh pr review -R OWNER/REPO PR_NUMBER --comment --body "..."
```

Inline review comment (REST) — use when you have a numeric `comment_id`:

```bash
scripts/pr_review_comment_reply.sh -R OWNER/REPO PR_NUMBER COMMENT_ID --body "..."
```

Review thread (GraphQL) — preferred for thread-level replies and resolution:

```bash
thread_id="$(jq -r '.reviewThreads[] | select(.isResolved == false and .isOutdated == false) | .id' pr-feedback.json | head -n 1)"
scripts/pr_review_thread_reply.sh "$thread_id" --body "..."
scripts/pr_review_thread_resolve.sh --yes "$thread_id"
scripts/pr_review_thread_unresolve.sh --yes "$thread_id"   # reopen if needed
```

`--yes` is required for resolve/unresolve; pass it only after explicit user approval.

Creating a brand-new review thread (not a reply) has no bundled script — use the `addPullRequestReviewThread` GraphQL mutation via `gh api` (needs `path`, `body`, and a `line`/`side` or an attached review).

## `gh api` fallback (REST + GraphQL)

Use only when there is no dedicated `gh` command. Prefer read-only calls; confirm before write calls.

### REST basics

```bash
gh api -H "Accept: application/vnd.github+json" /repos/OWNER/REPO -q '{defaultBranch: .default_branch, private: .private}'
gh api --paginate /repos/OWNER/REPO/issues -q '.[] | {number: .number, title: .title, url: .html_url}'
```

### GraphQL basics

```bash
gh api graphql -f query='
  query($owner:String!, $name:String!) {
    repository(owner:$owner, name:$name) {
      nameWithOwner
      defaultBranchRef { name }
    }
  }' -F owner=OWNER -F name=REPO -q '.data.repository'
```
