# WU-29-H — the form screens get their own character

**Approved by the user on 13 Oct 2026** ("Go ahead with suggestions. Validate all of them using HIG
and Apple skills and MCPs"), after five of six suggestions were put to them. Branch
`feature/WU-29-playful-redesign`. Follows WU-29-G, whose simulator walk is still open; the walk now
covers this unit too, so it is taken once over the final screens.

## Why

WU-29 gave the four stage screens colour, the judge and the dishes. The form screens kept the system
background (D148, approved by the user) and gained only `appBurgundyMuted` captions, so Settings,
Diet, About you, Evidence details and Demonstration read as rows of plain text. The user: "a bit
bland in some screens".

## What is not changing

D148 stands — no form gets a stage background. No product rule changes: nothing here reaches the
category, the dish, the diet or the store. Gold stays decoration only. No custom picker, no glass
card. Fonts on system chrome stay deferred by the user.

## Validation (HIG, Apple documentation, the doctrine skills)

| # | Suggestion | Source checked | Result |
|---|---|---|---|
| 1 | Icon tiles on the Settings rows | HIG *Lists and tables* ("a small image in the leading end of a row, followed by a brief explanatory label"; iOS Settings is Apple's own example of a list hierarchy), HIG *Color*, `swiftui-doctrine` rule 1 (a `*Style` on a native control), SF Symbols skill | **Pass.** Written as a `LabelStyle`. Tiles only on rows that *act*, in the tint — the HIG's *Color* rule ("avoid using the same color to mean different things … if you use your brand color to indicate that a borderless button is interactive, using the same color to stylize noninteractive text is confusing"). The tile pairs `appOnBurgundy` on `appBurgundy`, a pair `PaletteContrastTests` already measures. Category colours stay off the tiles: they mean Treat, Balanced and Light. |
| 2 | *Left for dinner* leads Evidence details, with a gauge | HIG *Gauges*; `Gauge`, `LinearCapacityGaugeStyle` docs | **Pass, amended.** The marker style (`LinearGaugeStyle`) is **watchOS only**; iOS gets `.linearCapacity` (iOS 16+), a fill that stops at today's share. The HIG asks for "succinct labels that describe the current value and both endpoints of the range", so the bar carries a current-value label and 0 % / 100 % bounds — drawn as plain text around a bare gauge after the gauge's own label slots truncated at AX 5 (`arc-audit-accessibility`). A negative share is clamped to 0 for the bar only; the figure beside it stays the true, negative value. The fill takes the verdict's category tint; cheese under 3:1 as a shape is D145's accepted exception, because the share and the band are also text. |
| 3 | Case detail matches the verdict: the judge and the speech bubble, and a symbol per reason | HIG *Color*, SF Symbols skill (monochrome for a tinted icon), `swiftui-doctrine` platform rule 7 (componentise an atom used twice) | **Pass, amended.** Reason symbols are not interactive, so they take `appBurgundyMuted`, not the tint (the HIG *Color* rule above). One `ReasonLabel` view serves the verdict card and case detail. |
| 4 | Onboarding ends on the stage's primary action; the judge heads About you | HIG *Onboarding* ("fast, fun"), HIG *Buttons*, `PinnedPrimaryActionModifier`'s contract | **Pass; needs D150** (below). The forms keep the system background (D148); only the action and the judge cross over. |
| 5 | History grouped by month | HIG *Lists and tables* (the grouped style "uses headers, footers, and additional space to separate groups of data") | **Pass.** Native `Section` headers. No streaks or counts: scoring days of eating is the guilt framing D118 bans. |
| 6 | Each demonstration scenario shows the badge of the verdict it leads to | `DemonstrationScenarioOutcomeTests`, `DemonstrationScenarioID` | **Fails; dropped.** The outcome is computed by running the rule over the scenario, and *No readable Health data* depends on the check-in answer. A fixed badge would either copy the rule into the view or misstate a scenario. |

## Decisions

- **D150 — The onboarding forms end on the stage's primary action, and the judge heads About you.**
  *Connect Apple Health* (then *Continue*) and *Save and finish* become `primaryAction()` pinned with
  `pinnedPrimaryAction`, inline at accessibility sizes, exactly as on Welcome. Secondary actions
  (*Continue without Health*, *Finish without the figures*) stay form rows. About you gets the same
  tappable judge hero as Apple Health (`StageArtworkSize.formJudge`). Alternative: keep plain
  text-button rows — the flow then drops from Welcome's prominent button to a text row on the two
  screens that finish onboarding.
- **D151 — Symbols on form screens: interactive in the tint, informative in the muted colour.**
  Settings rows that act get a filled tile (`SettingsIconLabelStyle`); evidence sources and verdict
  reasons get a monochrome symbol in `appBurgundyMuted`. Category colours never decorate a symbol that
  is not about the category.

## Work

1. Tests first (`arc-test-engineer`): month grouping of saved cases; every symbol name a view reads
   from a model extension resolves (`UIImage(systemName:)` — a misspelt name compiles and renders
   nothing); the gauge's clamped value.
2. `SettingsIconLabelStyle` + Settings rows (Diet, Evening reminder, Judge's flourish, Demonstration,
   Delete keeps its red).
3. `HealthKind.symbolName`, `ReasonCode.symbolName`; `ReasonLabel`; symbols on `ProvenanceRow`.
4. `AllowanceHeadlineRow` (figure, *Estimated*, gauge) at the head of the allowance section;
   `EvidenceSectionsView` takes the category.
5. `NarrationSection` → judge + `SpeechBubble`.
6. Health connection and About you: pinned primary action, inline at AX sizes; judge on About you.
7. History months: `HistoryMonth`, built by the view model on load; `Section` per month.
8. New strings through `StringCatalogEdit` sub-agents only.
9. Gate: zero-warning build, suite, renders (en/es, light/dark, AX 5); `arc-audit-hig`,
   `arc-audit-accessibility`, `arc-constitution-review`; ledger, DESIGN.md, memory; commit, push.
