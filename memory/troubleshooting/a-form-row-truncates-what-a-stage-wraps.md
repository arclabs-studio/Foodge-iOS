---
title: A Form row truncates what a stage wraps
tags: [foodge, troubleshooting, swiftui, dynamic-type, accessibility]
date: 2026-10-10
ledger: WU-29-F
---

# A Form row truncates what a stage wraps

The same `CategoryStampView` wraps and hyphenates on the verdict stage at AX 5 (*EQUILI-/BRADO*).
Inside a `Form` row on case detail it truncated instead, from AX 3 in Spanish (*EQUILIBRA…*), and at
AX 5 in English (*BALANC…*).

## Why

The list measured the row at one line of the `ViewThatFits`'s last choice and gave the text no more
height, so the text truncated instead of wrapping. A `ScrollView` or `VStack` on the stage proposes
no such limit.

## Fix

`.fixedSize(horizontal: false, vertical: true)` on the `Text` (or on the text block), so it takes the
height its wrapped lines need. It is applied to the stamp's name, `CategoryBadgeView`'s name and
`DishTitleView`.

## How it slipped

My own AX 3 render was English, where *BALANCED* fit. Both auditors caught it in Spanish. A
component that moves from a stage into a list needs its **longest Spanish string** rendered **inside
the list**. `SampleDecisions.longestNameDishOutcome` exists for that.

## See also

- [[a-standalone-preview-hides-scrollview-layout]]
