---
title: Recorded intake is an enum, not two optional fields
tags: [foodge, memory, decision, calories, concurrency-free-design]
date: 2026-09-21
ledger: D49
---

`CalorieProvenance.compare(_:)` (WU-20-C) takes intake as `RecordedIntake?`, an enum with two
cases — `.recordedFromHealth(EnergyAggregate)` and `.manual(kilocalories:window:)` — instead of
two separate optional properties (`healthIntake: EnergyAggregate?`, `manualIntake: Double?`) on
`CalorieComparisonRequest`.

**Why:** the product rule is "a manually supplied intake total *replaces* the Health total; it is
not added to it." With two optional fields, "replaces, never adds" is a rule a caller has to
remember to honor — nothing stops a call site from populating both, and nothing stops
`compare(_:)`'s own implementation from summing them by accident in a future edit. As one enum
value, there is physically no way to hold both at once: the type system enforces the "replaces"
half of the rule, not a runtime check or a code review comment.

**How to apply:** when a manual-entry UI eventually exists (see
[[calorie-references-stand-alone-until-a-meal-picks-one]] for the sibling decision about *what*
a manual entry might reference), it constructs `.manual(kilocalories:window:)` directly — it does
not write into a Health-shaped field and does not need a "which one wins" precedence rule anywhere
downstream. Reach for this shape generally whenever a brief says "X replaces Y, never adds to it":
model X and Y as one enum's cases, not two optionals with a convention layered on top.
