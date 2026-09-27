---
title: filter-branch takes the working copy with it
tags: [foodge, troubleshooting, git]
date: 2026-09-19
---

# `filter-branch` takes the working copy with it

## Symptom

After purging `CLAUDE.md` from history with an index filter, the file was gone from disk too:

```
ls: CLAUDE.md: No such file or directory
```

## Why

`git filter-branch --index-filter` rewrites the commits and then moves the branch. The file is
no longer in `HEAD`, so the checkout that follows removes it from the working tree. This is
correct behaviour and it is not what you expect when your intent was "stop tracking it, keep
using it".

## What saved it

A copy taken before the rewrite:

```bash
cp CLAUDE.md "$SCRATCHPAD/CLAUDE.md.backup"
git branch backup/pre-claude-md-purge
```

Restoring was then a `cp` back. Without the copy, the content would have been recoverable from
`backup/pre-claude-md-purge`, which is the second reason to make that branch.

## The rule

Before any history rewrite: **copy the file out, and branch.** Both, not either. The branch
protects the commits; the copy protects the working tree. Add the path to `.gitignore` *before*
restoring it, so the restored file comes back already ignored rather than showing up untracked.
