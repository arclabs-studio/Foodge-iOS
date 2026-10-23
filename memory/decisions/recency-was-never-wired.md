---
title: "Avoid the last three days" was tested but never wired into the app
tags: [foodge, decision, defect, catalogue, selection, testing]
date: 2026-10-23
ledger: D160
---

# Recency was never wired

## What happened

While planning catalogue packs (WU-30), reading `TodayViewModel.finish`
(`Presentation/Features/Today/TodayViewModel.swift:391`) showed it builds
`DishSelectionRequest(category:constraints:)` and never passes `recentSelections`. The
initializer defaults that argument to `[]`. So D139's third key, "avoid the last three days",
has never run in the shipped app. CLAUDE.md, the plan banner and D139 all describe it as live.

## Why nothing caught it

`DishSelectionTests` test the Domain function, and the function is correct. No test asked
whether the **caller** gave it the history. A default argument of `[]` made the omission
compile silently.

## Decision

Fix it in WU-30-0, first, before any pack widens the pool: `CaseStore` exposes the picks of
the last 3 local days and `finish` passes them. Acceptance is a Today test that **fails when
`recentSelections` is dropped** — yesterday's variant is not re-picked when an alternative
exists.

## The lesson

A tested use case is not a wired feature. When a request type has a defaulted parameter that
carries a product rule, test the call site, not just the function.

## See also

- [[rotation-is-a-continuous-day-index]]
