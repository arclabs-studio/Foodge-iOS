---
title: A standalone preview hides ScrollView layout
tags: [foodge, decision, testing, accessibility, swiftui]
date: 2026-10-10
---

# A standalone preview hides ScrollView layout

## What happened (WU-29-C)

Today's intake card rendered perfectly in its own `#Preview` at XX Large and XXX Large. On the real
screen — the same card inside Today's `ScrollView` — `arc-audit-accessibility` found a `.menu`
`Picker` reporting a one-line height while its value wrapped to two, so the second line ran across
the divider. A preview with no scroll view proposes a bounded height, and the bug only exists when
the proposal is unbounded. The reverse also bit: a card in a bounded preview *truncated* text that a
`ScrollView` would have let grow, which looked like a production defect and was not.

## The rule

- Host a card's preview the way production hosts the card: inside a `ScrollView`, with the
  `.sampleData` trait so it also gets the root's rounded face.
- A screen-level render at the problem size beats any number of component renders.
- Outside a `Form`, a `.menu` picker's target is only its value (~34 pt). For a row that opens a
  choice, make the row a `Menu`'s label and put the `Picker` inside the menu — the row becomes the
  target, and the system keeps the choice list and checkmark.

## See also

- [[a-tappable-character-must-not-move-under-the-finger]]
- [[fresh-install-walk-finds-what-tests-cannot]]
