---
title: CLAUDE.md is local-only, and the history was rewritten to keep it that way
tags: [foodge, decision, git, workflow]
date: 2026-09-19
---

# CLAUDE.md is local-only

## Decision

`CLAUDE.md` is gitignored. It is agent working context, not part of the hackathon submission.

Because it had already been committed in five local commits, gitignoring alone was not enough —
the blob would still have travelled to GitHub on the first push of `develop`. `develop` had
never been pushed (only `origin/main` existed, with the initial commit), so the history was
rewritten rather than merely patched at the tip:

```
git branch backup/pre-claude-md-purge
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f \
  --index-filter 'git rm -q --cached --ignore-unmatch CLAUDE.md' -- <initial>..HEAD
```

Verified with `git log develop -- CLAUDE.md` returning nothing. All nine work commits survive
with new hashes. `backup/pre-claude-md-purge` still holds the originals.

## The cost

Any commit hash written down before the rewrite is now wrong. The ledger deliberately refers to
"the commit that closes Day 18" rather than a hash, for exactly this reason — a self-referential
hash in a file that is itself part of the commit can never be right anyway.

## Trade-off worth knowing

The repo no longer carries its own agent instructions. A fresh clone gets `docs/foodge-plan.md`,
`DESIGN.md`, `docs/implementation-tasks.md` and `memory/` — enough to work from — but not the
condensed rules. Keep a copy somewhere durable; losing this file loses real context.

## See also

- [[filter-branch-deletes-the-working-file]]
