---
title: A tappable character must not move under the finger
tags: [foodge, decision, design, accessibility, motion]
date: 2026-10-10
ledger: D146
---

# A tappable character must not move under the finger

## What happened

The first `JudgeHeroView` put the quip's speech bubble **above** the judge, in the same `VStack`.
It looked right in every still preview. Two auditors found the problem from the layout alone:
inserting the bubble pushed the judge — the button just tapped — down by the bubble's height,
about 70 pt at standard sizes and ~320 pt for a five-line quip at AX 5, and by a different amount
on every tap as line counts changed. Under Reduce Motion a stack-wide `.animation(.easeInOut)`
still slid the judge across that distance, which contradicted the component's own DocC.

## The rule

- Anything that appears **because** a control was tapped goes where it cannot displace that
  control: below it in a scrolling column, or out of layout entirely. The bubble went below, tail
  up.
- Under Reduce Motion, the container gets `.animation(nil)` and the arriving view carries its own
  `.transition(.opacity.animation(...))`: the layout settles at once and only the fade animates.
  "Fade instead of move" has to be true of the *surroundings*, not just the new view.
- Motion nobody asked for stops within five seconds (WCAG 2.2.2): the idle breath is two 2.4 s
  cycles, and it never resumes after the first tap. Cycle lengths that divide the expiry let the
  `keyframeAnimator(repeating:)` flip land at rest.
- Read `accessibilityReduceMotion` inside the component and AND it with an optional override.
  A required `motion:` input leaves every call site one mistake away from ignoring the setting.

## See also

- [[contrast-is-measured-per-surface-not-per-colour]]
- [[audit-prompts-should-target-evidence]]
