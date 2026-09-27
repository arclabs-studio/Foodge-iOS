---
title: The demo evidence provider merges the caller's context; PreviewEvidence's verbatim return would kill a demo step
tags: [foodge, decision, demonstration, data, today]
date: 2026-09-24
ledger: D101
---

# The demo evidence provider merges the caller's context

## Why copying `PreviewEvidence` would have been wrong

`PreviewEvidence` (in `PreviewDependencies.swift`) ignores every argument and returns its scripted
snapshot verbatim. That is correct for a preview, which has no user typing into it. It is wrong
for a demonstration, because of where `TodayViewModel` reads the context back from:

```
finish() → DishSelectionRequest(context: snapshot.context, …)
```

Not the caller's `DailyContext` — the **snapshot's**. `NarrationPrompt` reads the note from the
same place. So a provider that returns its snapshot verbatim discards the craving, the energy
level and the note the presenter just entered, and the ritual's second step ("review today → add
optional context → request a verdict") is visibly dead on stage while looking like it works.

## Decision

`DemonstrationEvidenceProvider.snapshot(at:calendar:context:constraints:)` returns the scenario's
snapshot with the caller's `DailyContext` **merged over** the scenario's — each non-nil caller
field wins, the scenario fills the gaps — and the caller's `constraints`, keeping
`isSynthetic: true` and every Health aggregate exactly as the scenario wrote them.

Merge rather than replace, because `shortSleep` ships a deliberate `context: DailyContext(energyLevel: .low)`
that is part of what the scenario demonstrates. A replace would erase it the moment anyone touched
any other field.

## How it is kept honest

`DemonstrationEvidenceProviderTests`: asking `shortSleep` with `.normal` energy plus a note returns
both, keeps the scenario's own aggregates, and stays synthetic; asking with a field left empty
keeps the scenario's `.low`.

## See also

- [[demo-preferences-must-be-seeded-from-the-scenario]]
