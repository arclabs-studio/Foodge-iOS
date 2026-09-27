---
title: Passing through a loading state to do async work destroys every @State below the switch
tags: [foodge, decision, swiftui, demonstration, accessibility]
date: 2026-09-24
ledger: D105
---

# Passing through a loading state destroys every `@State` below the switch

## The bug this is about

`FoodgeApp` renders `switch launch.state`. Changing `state` to a different case changes the view
identity of that branch, so SwiftUI tears the subtree down and rebuilds it — `AppRootView` →
`MainTabView` → `TodayFlowView`, and with them every `@State` view model `MainTabView` builds in
its `init`.

Demonstration mode was written to show `CourtLoadingView` while the in-memory container opened:

```swift
state = .loading(.demonstration)   // teardown #1
await Task.yield()
do   { state = .ready(demoSession) }   // teardown #2 — intended (D98)
catch { demonstrationFailure = …; state = .ready(live) }   // teardown #2, unintended
```

On the **success** path the teardown is the whole point: it is what stops the demo running the
live `TodayViewModel` (see [[swapping-the-container-needs-an-id-not-just-modelcontainer]]).

On the **failure** path nothing about the session changed, and the teardown did two silent harms:

1. An in-progress verdict flow — the user's entered context, their place in the check-in — was
   discarded for an attempt that changed nothing.
2. The failure became **invisible to everyone**, not just to VoiceOver. `TodayFlowView` had
   already closed the Settings sheet before starting (correct, for the success path), and the
   rebuilt instance comes back with a fresh `isShowingSettings = false`. `demonstrationFailure`
   is read in exactly two places, neither of them on screen by then.

## Decision

`startDemonstration` does the async work first and assigns `state` **only on success**. On
failure it sets the flag and nothing else, so the Settings sheet the user is still looking at
renders the message. `TodayFlowView` stopped pre-dismissing the sheet for *start* (it still does
for *exit*, which cannot fail).

## How it was found, and why no test caught it

`arc-audit-accessibility`, asked to check the failure row's WCAG 4.1.3 status message. It traced
the runtime path instead of reading the view in isolation, and found the row could never appear.

`aFailedDemonstrationStartLeavesTheLiveSessionRunning` passed the whole time and still does. It
asserts on `AppLaunch.state` and `demonstrationFailure`, both of which were always correct — the
defect lived in the view layer above the thing under test. A green unit test over the state
machine says nothing about whether anyone can see the state.

## The general lesson

Before adding a loading state around async work, ask what sits **below** the switch that renders
it. A loading case is not free: it is a full teardown of the subtree, twice, and the second one
happens even when the work failed and nothing changed. If a failure path has to leave anything on
screen — a message, a half-filled form, a navigation position — do not route it through a state
change at all.

## See also

- [[swapping-the-container-needs-an-id-not-just-modelcontainer]] — the same teardown, wanted
- [[arc-audit-agents-find-evidence-problems]]
