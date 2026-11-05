---
name: leaving-pr-comments
description: Use whenever leaving comments on GitHub.
---

# Leaving PR comments

Prefix agent-authored GitHub comments on the user's behalf with this callout:

```md
> [!NOTE]
> 🤖 **<model> responding on behalf of <user>**

Actual comment starts here.
```

Use the verified public model name and the user's name or GitHub login.
If the model name is unavailable, use the harness name. Do not guess.

Keep attribution inside the note and the reply outside it. Add no separator, heading,
footer, or duplicate attribution.

Use this format for top-level comments, inline reviews, replies, and explanations
before resolving or dismissing feedback. Exclude PR descriptions, commit messages,
and text the user explicitly asks to post verbatim without attribution.

Apply `unslop` and the sentence-level guidance in
`technical-writing`. Reuse them if already loaded.
Skip Diátaxis and document structure rules for comments.

Lead with the conclusion or requested change. Cite the relevant code, behavior,
check, or reproduction, and distinguish verified facts from judgment. Include only
the context the reviewer needs to act. Omit canned thanks and status narration.

Before posting, check the whole comment, quotes, and attachments for secrets and
private details. Preview the Markdown to check quoting and blank lines. After
posting, verify that GitHub returned the comment or review URL. Resolve a review
thread only after its response posts successfully.
