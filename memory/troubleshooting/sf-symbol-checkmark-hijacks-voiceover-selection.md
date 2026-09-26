---
title: An SF Symbol literally named "checkmark" gets its own VoiceOver "Selected" announcement, and no accessibility modifier suppresses it
tags: [foodge, troubleshooting, accessibility, swiftui, voiceover]
date: 2026-09-20
---

# `Image(systemName: "checkmark")` hijacks VoiceOver selection

## What happened

`SelectableRow` (a `Button` in a `Form`/`List` row, with a trailing `Image(systemName:
"checkmark")` shown when `isSelected`) exposed each selected row as **three** VoiceOver elements
instead of one: the row's own `Button` (correctly carrying the `.isSelected` trait), a duplicate
`StaticText` of the title, and — the actual bug — the checkmark `Image` surfacing as its own
element with **`label: 'Selected'`** and its own `.isSelected` trait.

This is not a new bug from WU-20-A — it's a regression in a component that shipped in WU-19-D
with a comment claiming it was "verified on device, twice."

## Five attempts, four of them wrong

Every fix that varied *where* a SwiftUI accessibility modifier was placed failed identically,
confirmed on device each time:

1. `.accessibilityHidden(true)` on the checkmark `Image` alone.
2. `.accessibilityElement(children: .ignore)` + `.accessibilityLabel` on the label `HStack`
   *inside* the `Button`'s closure.
3. The same modifiers moved onto the `Button` itself, chained after `.buttonStyle(.plain)`.
4. `.accessibilityElement(children: .combine)` (Apple's own first-recommended alternative to
   `.ignore`) plus, separately, `.accessibilityHidden(true)` applied directly to the leaf `Image`.

Attempt 4 is what actually diagnosed it: hiding the **leaf `Image` directly**, with nothing else
in the way, still did not suppress it. That rules out every theory about modifier placement,
composition order, or container absorption.

## The actual cause

iOS recognizes an SF Symbol **literally named `"checkmark"`** inside a `Form`/`List` row as a
system-level selection accessory (the same family of behavior as `UITableViewCell.accessoryType
= .checkmark`) and re-injects its own `"Selected"` accessibility element for it — independent of
whatever the SwiftUI accessibility tree declares. No SwiftUI-level modifier can suppress this,
because it isn't coming from the SwiftUI accessibility tree at all.

## Fix

Don't use `Image(systemName: "checkmark")` as a selection indicator inside a row that also
carries `.accessibilityAddTraits(.isSelected)`. A hand-drawn `Shape` (a stroked `Path`, no SF
Symbol identity) sidesteps the heuristic entirely:

```swift
private struct CheckmarkMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
```

Confirmed on a fifth on-device pass: the hierarchy dump no longer contains any element labelled
`"Selected"` other than the row's own trait, on both reused sites (`FavouriteFamiliesSection`,
`IngredientExclusionsView`). The glyph is still visually present — this is an accessibility-tree
change, not a visual one.

## What to do next time

- If a selected-state indicator keeps leaking its own VoiceOver announcement no matter where you
  put `.accessibilityHidden`/`.accessibilityElement`, test whether hiding the **leaf view
  directly** works at all before touching anything else. If even that fails, stop suspecting your
  own modifier placement — suspect the symbol's own system-recognized identity.
- Any SF Symbol whose *name* matches a system idiom (`"checkmark"`, and plausibly others tied to
  standard list/row accessories) is a candidate for this. A custom-drawn `Shape` has no such
  identity to trigger it.
- The evidence discipline that caught this — hierarchy dumps from real device interaction, not
  a preview or a reading of the code — is exactly [[audit-prompts-should-target-evidence]]'s
  point, and this shared component's own comment ("verified on device, twice") is a second
  instance of a claim not holding up under a later, more careful check.

## See also

- [[audit-prompts-should-target-evidence]]
