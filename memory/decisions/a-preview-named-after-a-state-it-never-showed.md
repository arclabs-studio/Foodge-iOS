---
title: Five previews were named after states they never showed
tags: [foodge, decision, swiftui, previews, evidence]
date: 2026-09-26
ledger: D136
---

# Five previews were named after states they never showed

`AppealSheetView` reset itself on appearance:

```swift
.onAppear { vm.beginAppeal() }     // appealStage = .choosingCraving
```

with a comment asserting that `.onAppear` "runs inline with view appearance, before any of those
async continuations get a chance to run" — meaning a caller's `.task` could safely drive the view
to a later stage afterwards. **That ordering is not guaranteed, and it did not hold.**

Five of the file's six `#Preview`s drove themselves past the craving list —
`proposeCraving(.burgers)`, `beginFreeText()`, `submitFreeText("Grandma's stew")` — and every one
of them rendered **the craving list**, because the reset landed last and wiped the stage they had
set. `#Preview("Compatible variant found")` showed a list of cravings. `#Preview("Recorded")`
showed a list of cravings.

## Why this is worse than a broken preview

`AppealCompatibleSection`, `AppealNoMatchSection`, `AppealRecordedSection` and
`AppealFreeTextSection` had **never been seen** through this file. Any ledger line that says an
appeal stage was checked in a preview was written against a screen that was not showing it.
The render is only evidence if you read what came back — the name on the preview is not evidence.
See [[arc-audit-agents-find-evidence-problems]].

## The fix, and why it is not a behaviour change

The reset moved to the **presenter**: `VerdictView`'s Appeal button sets the state, then shows the
sheet. `appealStage` already defaults to `.choosingCraving`, so a first presentation is identical,
and reopening after a recorded appeal still starts fresh. What changes is only *where* the reset
happens — a deterministic place instead of a racy one.

## The rule

**A view that resets its own state on appearance cannot be driven from outside.** If a preview or
a caller has to reach a later state, the reset belongs at the point of presentation. And when a
comment claims an ordering guarantee, render the thing and look — the auditor found two of these
by reading; the other three came out of checking the claim instead of believing it.
