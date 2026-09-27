---
title: Ask auditors whether tests could fail, not whether they pass
tags: [foodge, decision, workflow, testing, agents]
date: 2026-09-19
---

# Ask auditors whether tests *could fail*

## The observation

Three `arc-*` auditors ran across days 18–19. All three returned **zero blockers**. All three
still found something real — and in every case the finding was about **evidence quality, not
code correctness**:

| Auditor | What it actually found |
|---|---|
| `arc-test-engineer` | A test title saying "not positive" where the spec says *nonnegative*, which would have steered the filter to `> 0` and silently broken a different test's zero-median branch. And: no fixture fed sleep intervals out of order, so an unsorted merge would have passed everything while returning 4 h 30 instead of 7 h 30 |
| `arc-constitution-review` | Two **false statements in the ledger** — a claim the string catalogue had extracted view strings when it was committed empty, and a stale note that `HKHealthStore`'s Sendability was unverified when the code already depended on it |
| `arc-audit-concurrency` | The test fixture never suspended, so a test claiming "readings cannot be shuffled onto the wrong day" would have passed against a plain serial loop |

Separately, three tests were green against stubs *by coincidence* — the category-rule stub
hardcoded the exact provisional-balanced answer two of them assert.

## Why this keeps happening

An agent is reliably worse at auditing its own claims than at writing the code. Code either
compiles and passes or it does not; a claim about code has no such check. Tests that cannot fail
and documentation that overclaims both look exactly like success.

## Decision

Every audit prompt states explicitly:

> Check whether each test could **actually fail**, and whether any comment, doc or ledger entry
> claims more than the code does.

And supplies the context needed to avoid reporting intended state as a defect: deliberate stubs,
temporary debug code, and the decisions log.

Recorded in `CLAUDE.md` under *Verification notes learned the hard way*, and in the
`foodge-verify` skill's closing checklist.

## See also

- [[2026-09-18-day-18-and-19]]
