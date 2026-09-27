---
title: WU-21-B — the day the verdict became a screen
tags: [foodge, session, today, accessibility, hig]
date: 2026-09-21
---

# WU-21-B — the day the verdict became a screen

`Presentation/Features/Today/` went from nothing to the app's real first screen: evidence
summary, context inputs, "Give me a verdict," the verdict screen, evidence details. 126 → 142
tests. Decisions D55–D62.

## The bug a preview caught, that a passing test suite did not

`VerdictView` originally read only `vm.currentRevision` (non-`nil` for `.verdict` only). A
failed save transitions to `.saveFailed(draft, .saveFailed)` — no `SavedRevision` exists yet, so
`currentRevision` stayed `nil` forever and the screen showed an infinite `ProgressView`. Every
unit test passed the whole time: `TodayViewModelTests` asserts `stage`, never what a *View*
does with it. `RenderPreview` on the "Save failed" preview caught it in one render — a spinner
that should have been an error state with a retry button.

Fix: `TodayViewModel.Display`/`currentDisplay` resolves from either a `SavedRevision`
(`.verdict`) or a `NewRevisionDraft` (`.saveFailed`) — both carry `decision`/`dishOutcome`, so
the view renders from the union rather than assuming a save always succeeded before there's
anything to show. **A green test suite proves the view model's state machine, not what the
screen does with a state the tests never render.**

## The bug a HIG audit caught, that no preview would show

`MainTabView` called `dependencies.makeTodayViewModel()` **inside `body`**, not in `@State`.
Every re-render — any `@Query` refresh bubbling from `AppRootView`, which happens on any
`UserPreferences` write — silently handed `TodayFlowView` a brand-new `TodayViewModel`,
discarding navigation, in-progress stage, everything. Previews don't reveal this: a preview's
parent doesn't re-render the way a live `@Query` does. Fixed the same way `AppRootView` already
holds `onboarding` — `@State`, built once in a custom `init`.

**Neither of these two bugs would fail a build or a test run.** Both were genuinely real,
user-facing, and caught only by the mandated preview-render step and the HIG audit
respectively — not by the thing that closes most work: green tests.

## The trap worth remembering for the next tracking-confirmation-shaped feature

`DinnerCategoryRule.decideFromRecording`'s guard is `trackingRepresentative == true` — `false`
and `nil` are indistinguishable to it. Naively passing the user's literal "No" answer back into
`decide(...)` loops the check-in forever. See [[tracking-confirmation-must-discard-not-replay]]
for the full trap and why the fix is to discard the comparison, not replay it with `false`.

## A design note that never became code

The plan sketch considered showing calorie arithmetic in `EvidenceDetailsView` via
`CalorieProvenance.compare(_:)`, gated on an intake-completeness confirmation that doesn't exist
yet. It was never built — wiring it to a hardcoded `intakeConfirmedComplete: false` would have
been unreachable dead code, so it was left out entirely instead. `arc-constitution-review`
caught that my own summary of the unit still described it as "deliberately left unreachable," as
if the section existed and was merely gated off. **Say what's actually in the diff, not what a
design note considered** — the review process exists exactly to catch this gap between an
agent's account of its own work and the work itself.

## Practical notes

- `DishArtPlaceholderView`'s SF Symbol choices were verified to *exist* at runtime
  (`RunCodeSnippet` + `UIImage(systemName:) != nil` for all nine) rather than guessed — Apple's
  doc-search tools don't index SF Symbol names at all (confirmed: even the already-shipped
  `fork.knife.circle.fill` from `JudgeBadgeView` returns zero search results). Existence was
  verified; semantic fit to each dish family was not, and doesn't need to be — Day 24 replaces
  all of them wholesale.
- `DeviceInteractionSynthesize` was unusable this session (`"Session not found"` on every call,
  across two devices, immediately after a successful `InstallAndRun`) — a tooling gap distinct
  from D21's documented "physical device needs `RunProject` + console" constraint. Live
  tap-through verification fell back to `RenderPreview` + the unit suite; flagged explicitly
  rather than claimed as equivalent proof. Worth checking whether this recurs before relying on
  device-interaction tools for WU-22-B's verification.
- SwiftFormat (the session's own auto-format hook, not a project tool) inserts trailing commas
  into multiline collection literals; SwiftLint's default `trailing_comma` rule forbids them.
  Confirmed once more: **there is no SwiftLint gate in this project** (`CLAUDE.md` says so
  explicitly), so these hook-generated warnings are noise specific to this session's tooling,
  not a real constitution violation — don't chase them.

## See also

- [[today-viewmodel-bypasses-verdict-engine]]
- [[tracking-confirmation-must-discard-not-replay]]
- [[no-match-still-reaches-a-verdict]]
- [[audit-prompts-should-target-evidence]]
