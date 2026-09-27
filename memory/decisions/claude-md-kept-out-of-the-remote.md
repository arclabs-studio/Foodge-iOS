---
title: CLAUDE.md is tracked, and names no local paths
tags: [foodge, decision, git, workflow, privacy]
date: 2026-09-19
---

# CLAUDE.md is tracked, and names no local paths

## How this ended up being decided twice

First decision: gitignore `CLAUDE.md`, because it referenced an internal studio folder by name
and absolute path, and the repository is public. It was purged from history with `filter-branch`
while `develop` was still unpushed.

That was aimed at the wrong file. A later audit — `git grep` across every commit, not just the
working tree — found the same reference in **`docs/foodge-plan.md`**, which is the product brief
and had been pushed to a public repository. Also in `docs/implementation-tasks.md` and a session
note. Hiding `CLAUDE.md` had achieved nothing for the actual goal.

## Decision

Two changes, in this order:

1. **Neutralise the reference everywhere**, not just in one file. Internal material is described
   by role — "the studio's engineering constitution, kept outside this repository" — and never by
   name or path. History and commit messages were rewritten and force-pushed.
2. **Track `CLAUDE.md` again.** Once it names no path, there is nothing to hide, and keeping it
   in the repo removes the single-copy risk that gitignoring it created.

## The lesson

The instinct was "which file mentions this?" The right question was **"grep every commit,
including messages, for the thing itself."** A secret is not in a file, it is in the repository;
and a working-tree grep says nothing about what has already been pushed.

Checks worth keeping:

```bash
git grep -n -i -E "<term>" $(git rev-list --all) --      # every tree, every commit
git log --all --format='%B' | grep -i -E "<term>"         # every message
```

## Residual risk

Force-pushing removes the objects from the branch, but GitHub may keep unreachable commits
reachable by direct SHA URL until it garbage-collects. Guaranteed removal would have meant
deleting and recreating the repository, which was judged not worth losing the creation date on a
hackathon entry. Recorded so the trade-off is visible rather than forgotten.

## See also

- [[filter-branch-deletes-the-working-file]]
