---
title: Contrast is measured per surface, not per colour
tags: [foodge, decision, design, accessibility, testing]
date: 2026-10-10
ledger: D145
---

# Contrast is measured per surface, not per colour

## What happened

D134 swapped every `.secondary` text in Presentation for `appBurgundyMuted`, and D135 documented
it as "4.73:1 light". That figure was real — against a **row**, `#FFFFFF`. But a `Form` section
**footer** does not sit on a row; it sits on `systemGroupedBackground`, `#F2F2F7` in light. Old
`#A85C72` measures **4.23:1** there. Every burgundy-muted footer from WU-27 to WU-28 (the verdict
disclaimer among them) was under WCAG 1.4.3 in standard-contrast light, and two audits plus a
repo-wide grep did not see it, because each measured the colour once against one surface.

`PaletteContrastTests` (WU-29-A) found it on its first mutation run: putting the old value back to
prove the test could fail reported six failing pairs, one of them the grouped background.
(The Xcode MCP's test summary truncates to five messages — count from the full log.)

## The rule that follows

A text colour has no contrast ratio. A **pair** does. The test therefore declares pairs —
every text colour × every surface text can land on (`systemBackground`,
`systemGroupedBackground`, `secondarySystemGroupedBackground` — at the base level *and* the
elevated level a sheet is drawn at — `AppCard`, dough, and the top of each stage gradient, where
the accent wash is strongest) × four appearances — and resolves the **shipped**
colour sets through `UIColor(resource:).resolvedColor(with:)`, never a copy of their hex values.

When a new surface appears (a tinted card, a stage with a new accent), add it to the pair table
in `PaletteContrastTests` before putting text on it.

The same holds for *ordering*, not only contrast: the first card fill,
`secondarySystemGroupedBackground`, was darker than every dark stage top, so a card read as a hole
(`arc-audit-hig`). `aCardAdvancesFromTheStage` now fails on that fill.

## Why `ColorResource` and not `Color`

`DinnerCategory.tint`/`onTint` return `ColorResource` because a resource resolves through
`UIColor(resource:)` in any `UITraitCollection`, high contrast included, with no SwiftUI
environment to construct. Resolving a SwiftUI `Color` in high contrast from a test was not
attempted; `EnvironmentValues.colorSchemeContrast` is get-only, which made it the worse bet.

## See also

- [[an-auditors-fix-stops-at-its-own-diff]] — the same blind spot from the other side
- [[audit-prompts-should-target-evidence]]
