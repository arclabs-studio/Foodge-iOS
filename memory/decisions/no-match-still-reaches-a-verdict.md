---
title: A no-match dish selection still reaches a verdict, honestly
tags: [foodge, decision, presentation, today]
date: 2026-09-21
ledger: D58
---

# A no-match dish selection still reaches a verdict, honestly

## The question

`DishSelection.select(...)` can return `.noMatch(blockingIngredientIDs:)` when the user's diet
and exclusions leave nothing in a category. What should `TodayViewModel` do with the *category
decision* (already ruled) when the *dish* pick comes back empty?

## Decision

The category still rules. `TodayViewModel.finish(decision:snapshot:)` records the revision
regardless of `DishSelectionOutcome`, and `PersistedDishOutcome.noMatch(...)` is a normal,
recordable case — `TodayViewModel.Stage` reaches `.verdict` either way. `VerdictView` shows the
category and an honest "no catalogue dish matched your constraints tonight" message, no invented
dish, no relaxed exclusion.

## Why

The constitution is explicit: "Never silently relax an exclusion; show an honest no-match."
Refusing to produce *any* verdict because the dish pick failed would conflate two independent
facts — "how active was today" and "what's in the catalogue for that category, given your
diet." The category answer is still true and useful even when the catalogue has nothing to
suggest.

Resolving the no-match itself (suggesting which exclusion to lift, negotiating a craving) is
explicitly WU-22-A's appeal-negotiation job — this unit only needs the honest, non-blocking
report.

## Pinned by

`TodayViewModelTests.noMatchDishSelectionStillReachesVerdict` — vegan profile plus excluding
both `rice` and `pasta` empties the balanced category entirely (`riceBowls`/`tortilla`/`pasta`
all fail); asserts the stage still reaches `.verdict` and the recorded `dishOutcome` is
`.noMatch`.

## See also

- [[the-catalogue-is-a-domain-constant-not-a-seam]]
