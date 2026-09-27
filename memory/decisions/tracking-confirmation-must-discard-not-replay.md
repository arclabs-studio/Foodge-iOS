---
title: The tracking-confirmation "No" must discard the comparison, not replay it
tags: [foodge, decision, presentation, today, regression-risk]
date: 2026-09-21
ledger: D56
---

# The tracking-confirmation "No" must discard the comparison, not replay it

## The trap

`DinnerCategoryRule.decideFromRecording(today:baseline:trackingRepresentative:)` has this guard,
for the below-`lightThreshold` branch:

```swift
guard trackingRepresentative == true else {
    return .needsTrackingConfirmation
}
```

`trackingRepresentative == true` is the *only* way past this guard. `false` and `nil` are treated
identically. That is fine for the first call — the check-in is genuinely being asked for the
first time either way — but it is a live trap for the answer.

The tempting, wrong implementation of "the user said No" is to re-call
`DinnerCategoryRule.decide(today:, baseline:, trackingRepresentative: false, selfReport: nil)`
with the same `today`/`baseline` that produced the low ratio. That re-enters
`decideFromRecording`, the guard fails again (`false != true`), and the rule hands back
`.needsTrackingConfirmation` a second time — the exact question the user just answered.
`TodayViewModel` would show the same check-in forever.

## Decision

"No" discards the recorded comparison entirely rather than replaying it with `false`:

```swift
guard reflectsToday, let comparison = pendingComparison else {
    pendingComparison = nil
    transition(to: .needsSelfReport)
    return
}
```

The per-day answer is never fed back into `DinnerCategoryRule.decide` at all when it's "No" —
the view model just moves straight to the self-report fallback, the same place a genuinely
unusable baseline goes.

## Pinned by

`TodayViewModelTests.decliningTrackingMovesToSelfReport` — asserts the stage is
`.needsSelfReport` after "No", which only holds if the implementation never re-enters
`decideFromRecording` with `trackingRepresentative: false`. If a future refactor "simplifies"
this by threading the bool straight into `decide(...)` again, this test starts failing
immediately with the wrong stage.

## See also

- [[today-viewmodel-bypasses-verdict-engine]]
- [[schema-v1-grows-tracking-representative]] — the standing flag this is *not*; this is the
  per-day one, asked fresh on every low-ratio evaluation
