---
title: A disabled Continue and a hidden Skip must not flip on the same keystroke
tags: [foodge, decision, onboarding, ux, accessibility]
date: 2026-09-25
ledger: D126
---

# A disabled Continue and a hidden Skip must not flip on the same keystroke

`BodyBasicsView` (Pass B, D117/D124) had two conditions that looked independent and were not:

```swift
NavigationLink("Continue", value: .preferences)
    .disabled(vm.hasStartedBodyBasics && vm.bodyBasicsFromInputs == nil)

if !vm.hasStartedBodyBasics {                      // ← the bug
    NavigationLink("Skip for now", value: .preferences)
}
```

Both keyed on `hasStartedBodyBasics`, in opposite directions. The **first keystroke** therefore
disabled Continue *and* removed Skip at the same instant. A user who gives a sex and an age and
will not give a weight has no way forward — while the section footer still reads "Skipping is
fine. On a day Health records no resting energy, Foodge will ask how your day went instead."

It was recoverable: `hasStartedBodyBasics` is computed, so clearing all four fields — including
setting the picker back to "Not given" — brings Skip back. Nothing on screen said so, and no user
would guess it.

## The fix

Key the escape hatch on the **answer**, not on whether typing has begun:

```swift
var canSkipBodyBasics: Bool { bodyBasicsFromInputs == nil }
```

Skipping already discards a partial answer — `applyBodyBasics()` assigns
`bodyBasicsFromInputs`, which is `nil` in exactly that state — so the partial input needs no
special handling.

## Why no test caught it

**The rule lived in the View.** This project has no UI-test bundle (D2), so a `.disabled()`
argument and an `if` around a `NavigationLink` are unreachable by the suite — 265 tests, none of
which could fail on this. The condition now lives on the ViewModel as `canSkipBodyBasics`, and
`aHalfAnsweredStepIsStillSkippable` fails against the old condition.

## The lesson

**A visibility rule and an enablement rule over the same state are one rule, and belong in one
testable place.** The general shape — every exit from a screen disabled at once — is the
dead-end class the UX auditors look for, and it is cheap to reason about only when both
conditions are readable side by side on the ViewModel.

Found by `RenderPreview` on the "Half answered" preview in `es` — a rendered screen showed a
greyed Continue with nothing under it. See [[recorded-hand-walk-as-evidence]]: rendering the
state, rather than reading the code, is what surfaced it.
