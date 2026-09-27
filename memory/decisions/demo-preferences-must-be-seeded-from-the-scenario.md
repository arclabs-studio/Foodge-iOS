---
title: A demonstration scenario only demonstrates itself if the store is seeded from its snapshot
tags: [foodge, decision, demonstration, presentation, persistence]
date: 2026-09-24
ledger: D100
---

# A demonstration scenario only demonstrates itself if the store is seeded from its snapshot

## The trap

`SyntheticScenario` carries an `EvidenceSnapshot`, and a snapshot carries `constraints` and
`trackingRepresentative`. It is entirely natural to assume that feeding that snapshot to the app
is enough to demonstrate the scenario. It is not. Two of those fields are read from somewhere
else entirely on the live path:

- **`snapshot.constraints` is never read by dish selection.** `TodayViewModel.requestVerdict()`
  loads `draft = await preferences.preferences()` and passes `draft.constraints` *into*
  `evidence.snapshot(...)` (`TodayViewModel.swift:214`, `:230`); `finish()` then builds the
  `DishSelectionRequest` from `draft.constraints` and `draft.favouriteFamilies` (`:331`). The
  snapshot's own `constraints` field is carried for the record, not consulted.
- **`snapshot.trackingRepresentative` drives nothing in production.** The value that reaches
  `ActivityBaselineCalculator` is `draft.trackingRepresentative` (`:241`). Both fields ask the
  same *standing* question — "do the recorded days reflect my usual days?" — and the snapshot's
  copy is simply read by nothing. The **per-day** check-in is a third thing again, asked fresh on
  every low-ratio evaluation and stored in no field at all (D32); see
  [[schema-v1-grows-tracking-representative]] and
  [[tracking-confirmation-must-discard-not-replay]].

So a demonstration that only swaps the evidence provider would show `noCompatibleDish` — whose
entire point is the vegan + rice/pasta no-match (D58) — recommending an ordinary pasta dish, and
`partialTracking`'s "this doesn't reflect my day" would be silently inert.

## Decision

`DemonstrationSessionFactory.seededPreferences(for:)` derives a `PreferencesDraft` from the
scenario's own snapshot and writes it into the in-memory container before the session is handed
over: `dietProfile` and `excludedIngredientIDs` from `snapshot.constraints`,
`trackingRepresentative` from `snapshot.trackingRepresentative`, `onboardingCompletedAt` from the
scenario's `FixedClock` (so onboarding is skipped through D9's single source of truth rather than
a second flag), `favouriteFamilies` left empty.

`favouriteFamilies: []` is deliberate and was put to the user: seeding a favourite would make the
favourites priority step visible on stage, at the cost of biasing every Treat pick by a preference
the audience never set.

## How it is kept honest

`DemonstrationScenarioOutcomeTests` builds a real `TodayViewModel` from the factory's own
dependencies and drives it end to end. Two cases fail specifically if this seeding is dropped:
`.noCompatibleDish` must reach `.noMatch(blockingIngredientIDs: [rice, pasta])`, and
`.partialTracking` must reach `.needsSelfReport`. The oracle is `CLAUDE.md`'s category decision
table and D58 — written long before this code.

## The general lesson

When a value exists in two places, find out which copy the production path actually reads before
assuming the other one is wired. Grepping for the field name is not enough; follow the call that
consumes it.

## See also

- [[demo-evidence-must-merge-the-callers-context]]
- [[today-viewmodel-bypasses-verdict-engine]]
- [[schema-v1-grows-tracking-representative]]
