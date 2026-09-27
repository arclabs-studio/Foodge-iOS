---
title: The unrepresentative mark has to survive a relaunch
tags: [foodge, decision, swiftdata, schema, health]
date: 2026-09-19
ledger: D32
---

# The unrepresentative mark has to survive a relaunch

## The gap

`markUnrepresentative(_:)` was in WU-19-D's action list. But the only place that flag existed
was `EvidenceSnapshot.trackingRepresentative` — a value computed per evaluation and never
stored. A user who said "my recorded days do not reflect how I usually live" would have been
asked again on the next launch, and `ActivityBaselineCalculator` would have used the fortnight
they had just disowned.

## Decision

`UserPreferences` (schema V1) grows `var trackingRepresentative: Bool = true`.
`versionIdentifier` stays `1.0.0`.

D10 already settled the precedent: the schema is unreleased, so growing V1 before submission is
a **dev reinstall, not a migration**. The practical cost is real and worth naming — any device
or simulator holding a WU-19-C store must have the app deleted, or `ContainerFactory.makeLive()`
throws and the app shows `StoreUnavailableView`, which reads exactly like a bug in the new
launch code.

## Why the default is `true`

Unasked means "use my data". A user who skipped the Health step entirely never sees the
question, and defaulting them to `false` would mean their pattern is refused for a reason they
were never given.

## The distinction that is easy to lose

Two different questions share similar wording:

- **Standing** (this flag): may the recorded fortnight be used as a baseline *at all*? This is
  exactly `ActivityBaselineCalculator`'s `trackingRepresentative` parameter, and the answer
  belongs in preferences.
- **Per-day** (Day 21, D12): does *today's* low reading reflect today? That is the
  `needsTrackingConfirmation` branch of the category rule — a forgotten watch looks exactly like
  a quiet day — and it is asked fresh each evaluation.

Collapsing them into one stored flag would let a single forgotten-watch day permanently disable
a user's baseline.

## See also

- [[metric-preference-and-failure-reporting]] — what the baseline does with the answer
- [[exclusions-screen-waits-for-the-catalogue]]
