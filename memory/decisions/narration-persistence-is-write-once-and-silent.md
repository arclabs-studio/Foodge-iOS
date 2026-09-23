---
title: Narration is never persisted as a template, written once, and never reports a failure
tags: [foodge, decision, persistence, narration, history]
date: 2026-09-23
ledger: D75, D76, D77
---

# Narration: template never persisted · attach is write-once · a failed save is silent

Three rules that only make sense together.

## 1. The template is never persisted (D75)

`VerdictRevision.narrationText` stays `nil` unless a **real model line was validated**. The
reviewed template renders at display time from `DinnerCategory.flourishTemplate`.

- Persisting it would make a historical case indistinguishable from one the model actually
  narrated.
- It would freeze today's English copy into a row a Spanish reader opens later.
- Rendering at display time is what lets `CaseDetailView` show the section **unconditionally** —
  which is what closed the live gap where every case ever recorded showed no flourish at all,
  because the old code rendered the section only `if narrationText != nil`.

The template is keyed by **category only**, with no dish-name interpolation, so it also renders
correctly for a `.noMatch` night (no dish name exists) and for a historical case whose stored
`variantID` a later catalogue no longer resolves — `DishCatalogue.displayName(forVariantID:)`
falls back to the raw id, and a raw id must never reach prose.

## 2. `attachNarration(_:to:)` is write-once (D76)

A revision that already carries narration is returned **unchanged**, not overwritten.
`VerdictView`'s `.task` re-fires on every tab revisit (D69); without this, the same day would
read differently each time it was opened. The oracle in `CaseStoreTests.narrationIsWriteOnce` is
that the **first** text stands.

## 3. A failed attach is silent (D77)

The line is genuine and validated, so it stays on screen for the session via `.narrated(text)`
while the revision keeps `nil`. `stage` **never** becomes `.saveFailed`.

`.saveFailed` means "your verdict was not saved, here is a retry". Offering that for a decoration
the user never asked for would be dishonest about what actually failed. The revision staying
`nil` is consistent with the other two rules: only genuine model output is saved, and reopening
shows the template.

## See also

- [[narration-state-is-its-own-stage]] — why `stage` cannot carry this at all.
- [[case-store-schema-v1-shape]] — the column this finally writes to, unused since D54.
