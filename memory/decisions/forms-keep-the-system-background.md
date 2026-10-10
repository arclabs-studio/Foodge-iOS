---
title: Forms keep the system background
tags: [foodge, decision, design, accessibility, swiftui]
date: 2026-10-10
ledger: D148
---

# Forms keep the system background

The WU-29 stage (dough plus a tinted wash) stops at the data-entry forms. Apple Health and About you
keep `systemGroupedBackground`; Health gets the judge as a hero section instead. Every `Picker` in
the app is a `MenuPickerRow`.

## How it was decided — and the mistake on the way

I first built it this way and recorded the deviation as forced ("neither alternative can hold 4.5:1").
Two auditors showed it was not: a stage with `AppCard` row fills plus `MenuPickerRow` would have met
the floor. The approved plan said "stage behind the form", so changing it was the user's call, not
mine. I put three options to the user; on 10 Oct 2026 they chose the system background.

**Lesson:** when an approved plan line turns out awkward, measure the alternatives and *ask* before
building — do not record a preference as a necessity.

## The real reasons

- HIG: settings-style forms use `systemGroupedBackground`.
- Dark mode: the system row `#1C1C1E` is darker than the stage's tinted top, so rows read as holes
  (D145's card defect again). Against bare dough it is 1.02:1 *lighter* — the hole is only near the top.
- Cost: a stage without holes needs `AppCard` fills on every section.

## How to reverse it

Put `.scrollContentBackground(.hidden)` and `.background { StageBackground(accent: .appBurgundy) }`
on the form, **and** `.listRowBackground(Color(StageSurface.fill))` on every section. Keep
`MenuPickerRow`: system picker values on `AppCard` dark are 4.44:1.

## MenuPickerRow, briefly

- Not a `*Style`, because no style can do it: `PickerStyle` has no public requirements, and
  `MenuStyleConfiguration` has only a label and content.
- In a list it zeroes the row's vertical insets (`.listRowInsets(.vertical, 0)`), so the label is
  the row. Otherwise its 44 pt minimum sits inside the insets and the row grows about 20 pt.

## See also

- [[contrast-is-measured-per-surface-not-per-colour]]
