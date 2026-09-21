---
title: TodayViewModel calls the rule and calculator directly; VerdictEngine has no conformer
tags: [foodge, decision, domain, presentation, today]
date: 2026-09-21
ledger: D55
---

# `TodayViewModel` calls the rule and calculator directly; `VerdictEngine` has no conformer

## Why the protocol doesn't fit

`Domain/Services/VerdictEngine.swift` declares `decideCategory(for snapshot:)` — a single
`EvidenceSnapshot` in, a `CategoryOutcome` out. But `ActivityBaselineCalculator.baseline(from:
trackingRepresentative:)` needs `PreferencesDraft.trackingRepresentative` — the *standing*
"may my recorded days be used at all" flag — and `EvidenceSnapshot` doesn't carry it (its own
`trackingRepresentative` field is the *per-day* check-in answer, a different thing; see
[[schema-v1-grows-tracking-representative]]). There is no way to satisfy `VerdictEngine`'s
signature without either smuggling the preferences flag into the snapshot (muddying what a
snapshot means) or growing the protocol for a caller that doesn't exist yet.

## Decision

`TodayViewModel` skips the protocol and calls `ActivityBaselineCalculator.baseline(...)` then
`DinnerCategoryRule.decide(...)` directly. `VerdictEngine` stays declared, with zero conformers,
rather than being reshaped to fit a single caller's exact needs speculatively.

## Why this is fine for now

`VerdictEngine` currently buys nothing: one call site, one set of dependencies, no test seam it
enables that `ActivityBaselineCalculator`/`DinnerCategoryRule` don't already provide directly
(both are pure, both are already unit-tested independently). A protocol earns its place when a
second, different caller or a fake implementation actually needs the seam — reshaping it now
would be guessing at that caller's future shape.

## If this needs revisiting

If a second real consumer of "decide a category from evidence" appears (narration preview,
demonstration mode re-deciding without a live view model, etc.), that's the moment to either
grow `VerdictEngine`'s signature to take the extra flag, or delete it if `TodayViewModel`'s
direct-call shape has held up. Don't let it linger unconformed indefinitely without a follow-up
decision either way.

## See also

- [[tracking-confirmation-must-discard-not-replay]]
