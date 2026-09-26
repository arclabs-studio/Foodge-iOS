---
title: Narration is never persisted as a template, written once, shown not regenerated, and never reports a failure
tags: [foodge, decision, persistence, narration, history, device-caught]
date: 2026-09-23
updated: 2026-09-24
ledger: D75, D76, D77, D81
---

# Narration: template never persisted · attach is write-once · a stored line is shown, never regenerated · a failed save is silent

Four rules that only make sense together.

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

## 3. A stored line is shown, never regenerated (D81) — the one the tests missed

`narrateIfNeeded()` opens with:

```swift
if let existing = revision.narrationText {
    transitionNarration(to: .narrated(existing))
    return
}
```

**Rule 2 alone is a trap without this one.** Write-once keeps the *store* stable; it does nothing
to stop the *screen* asking the model again. Without rule 3, reopening a saved day generated a
fresh flourish, the attach silently returned the existing revision, and Today showed one line
while History showed another — for the same day, from the same code.

Every unit-test fixture seeded `narrationText: nil`, so **no test ever reopened a day that already
had a flourish** — the whole suite was green while this was live. It was caught by reading the
device console: `narration=narrating` on a case that was merely reopened. After the fix the same
reopen is `stage=verdict` → `narration=narrated`, 7 ms apart, with no model call.

The lesson generalizes past narration: a fixture that only ever seeds the *empty* shape of an
optional field cannot test the branch that field exists to create.

## 4. A failed attach is silent (D77)

The line is genuine and validated, so it stays on screen for the session via `.narrated(text)`
while the revision keeps `nil`. `stage` **never** becomes `.saveFailed`.

`.saveFailed` means "your verdict was not saved, here is a retry". Offering that for a decoration
the user never asked for would be dishonest about what actually failed. The revision staying
`nil` is consistent with the other two rules: only genuine model output is saved, and reopening
shows the template.

## See also

- [[narration-state-is-its-own-stage]] — why `stage` cannot carry this at all.
- [[case-store-schema-v1-shape]] — the column this finally writes to, unused since D54.
