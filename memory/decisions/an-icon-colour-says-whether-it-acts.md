---
title: An icon's colour says whether it acts
tags: [foodge, decision, design, hig, accessibility]
date: 2026-10-13
ledger: D150, D151
---

# An icon's colour says whether it acts

WU-29-H gave the form screens symbols. Before building, every suggestion was checked against the HIG
and Apple's documentation (the user asked for that). Two results changed the plan, one dropped an item.

## The colour rule (D151)

HIG *Color*: "Avoid using the same color to mean different things … if you use your brand color to
indicate that a borderless button is interactive, using the same or similar color to stylize
noninteractive text is confusing." In Foodge burgundy is the tint, so:

- a row that **acts** (Settings) gets a filled tile in `appBurgundy` with an `appOnBurgundy` glyph —
  a pair `PaletteContrastTests` already measures;
- a symbol that only **informs** (evidence sources, verdict reasons) is monochrome `appBurgundyMuted`,
  the colour every non-interactive header and footer already uses;
- tomato, cheese and basil never decorate a symbol that is not about the category — they *are* the
  categories.

## The gauge that does not exist on iOS

`LinearGaugeStyle` — the bar with a marker — is **watchOS only**. On iOS the choices are
`.linearCapacity` and the `accessory*` styles (meant for Lock Screen widgets). *Left for dinner* uses
`.linearCapacity` with a current-value label and 0 % / 100 % bounds, because the HIG *Gauges* page asks
for "succinct labels that describe the current value and both endpoints". Those labels are plain
`Text` around a bare gauge: the gauge's own label slots truncated at AX 5 in Spanish, and
`.labelsHidden()` does not hide a `.linearCapacity` label. The gauge's VoiceOver value is set to the
true share, so a negative day is not read as the bar's clamped 0 %. A negative share is clamped
for the bar only; the figure stays negative.

## The dropped badge

Showing each demonstration scenario's verdict badge failed: the outcome is computed by running the
rule (see `DemonstrationScenarioOutcomeTests`), and *No readable Health data* depends on the check-in
answer. A fixed badge would copy the rule into a view or lie about a scenario.

## The onboarding action (D150)

Apple Health and About you now end on the stage's `primaryAction()`, pinned exactly as on Welcome, and
About you gets the tappable judge. D148 still holds — the forms keep the system background; only the
action and the judge cross over.

## See also

- [[forms-keep-the-system-background]]
- [[contrast-is-measured-per-surface-not-per-colour]]
