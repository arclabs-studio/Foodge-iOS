---
title: A failed request is not an absence
tags: [foodge, decision, health, honesty]
date: 2026-09-19
ledger: D35
---

# A failed request is not an absence

## The five states were not enough

The ledger gave `OnboardingViewModel.healthState` five cases: `idle`, `requesting`,
`connected(summary)`, `unavailable`, `noReadableData`. None of them can express *"the
authorization request itself did not complete"* — the sheet failed to present, HealthKit
errored, the request was interrupted.

## Decision

A sixth case, `.requestFailed`.

## Why the obvious alternative is wrong

Folding a failed request into `.noReadableData` would have the app assert an absence it cannot
prove. Foodge has one standing rule here: HealthKit cannot distinguish "no data" from "denied",
so the app never claims either — the wording is always *no readable data*, and that claim is
only made **after a read actually came back empty**. A request that never completed produced no
read at all. Saying "no readable data" there is the same class of lie as saying "denied".

`.requestFailed` gets its own message and a retry. `FoodgeError.healthUnavailable` still maps to
`.unavailable`, because that one *is* provable: `HKHealthStore.isHealthDataAvailable()`.

## The related trap in the same file

`healthState` is logged on device. `.connected(summary)` carries the recorded median — a Health
value — so `String(describing:)` on this enum would put a user's health data in the device log.
`HealthState.logLabel` exists for exactly this reason and returns the case name alone.

## See also

- [[schema-v1-grows-tracking-representative]]
