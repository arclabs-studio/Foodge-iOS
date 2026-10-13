---
title: A NavigationLink in a Form is a row, whatever style it is given
tags: [foodge, troubleshooting, swiftui, accessibility]
date: 2026-10-13
ledger: D150
---

# A NavigationLink in a Form is a row, whatever style it is given

WU-29-H pinned the stage's primary action on the Apple Health form and, at accessibility sizes, put
the same action inside the form as its last section (`InlinePrimaryActionSection`). Once Health had
answered, that action was `NavigationLink("Continue", value:)` with `.primaryAction()`.

Rendered at AX 2, the link was **invisible**: a list row with a disclosure chevron and the prominent
style's **white** label on the clear row background. `.buttonStyle(.glassProminent)` is ignored — a
`List`/`Form` draws its own row for a navigation link. The pinned copy, outside the form in a
`safeAreaBar`, rendered correctly, so a default-size render hid the bug.

Found only because `arc-audit-hig` asked for the inline case to be checked and a preview was written
for it; previews cannot scroll to the foot of a form, so the screen's own preview never showed it.

## Fix

A `Button` that pushes through the view model's path: `OnboardingViewModel.continueToBodyBasics()`
appends `.bodyBasics`, tested in `OnboardingViewModelTests`. `InlinePrimaryActionSection`'s doc now
says to put a `Button` in it, never a link.

## Lesson

A styled control inside a `Form` row may not be the control you styled. Render the in-form copy, not
just the pinned one — write a component preview for it when the screen's preview cannot scroll there.

## See also

- [[a-form-row-truncates-what-a-stage-wraps]]
- [[an-icon-colour-says-whether-it-acts]]
