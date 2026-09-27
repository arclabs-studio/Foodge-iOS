# Close Checkpoint B: drop Pass C, then satisfy the owed verification

## Context

The energy-allowance rebuild (WU-EB) is code-complete for Passes A, B, D and E, committed and
pushed on `feature/FOODGE-energy-balance` (`8034a3a` → `1c2f3d0`). The build gate is met on both
targets, four times over (`GetBuildLog severity: "warning"` → `totalFound: 0`).

Two things stand between here and a closed work unit:

1. **The gate is half-met.** Foodge's definition of done is *zero-warning build + green tests +
   visual verification*. Only the first holds. `RunSomeTests` wedged on four consecutive attempts
   (`.xcresult` created, then 30+ min with no progress, while `BuildProject`/`GetTestList` answered
   in seconds), so **no test in this rebuild has been observed to pass** — 265 are listed, 0 run.
2. **Pass C was left undecided by design** — the plan's own droppable pass, to be called at the
   Checkpoint-B review. It is now called: **dropped.**

Intended outcome: the rebuild's owed verification is either satisfied or honestly recorded as owed,
the Pass C drop is a numbered decision rather than a silence, and the branch is left in a state the
user can submit from. ~24 h to the deadline (27 Sep 2026, 21:00 Europe/Madrid).

## Decisions taken at this review

- **Pass C is dropped.** The catalogue stays at 9 families / 27 variants. The reason is the
  verification loop, not the edit size: the pass's largest piece is `DishSelectionTests` (466 lines,
  25 tests, every fixture built on `CatalogueEntry`), and with the MCP runner wedged each red→green
  attempt costs a hand-driven ⌘U.
- **Cost accepted:** no ten-dish catalogue, no editorial `kilocalorieRange`, so dish cards keep
  showing no calorie figure — which is D50's existing, honest behaviour, not a regression.
- **Verification priority:** device walk + verdict timing, `RenderPreview` at AX5 in both
  languages, and the audit agents. The test run is attempted once more as a probe, then handed to
  the user rather than chased.

## Steps

### 1. Ledger first — D125, before anything else

`docs/implementation-tasks.md`. The project rule is that a deviation from a written decision needs a
new numbered decision, written before the work (or, here, before closing the unit).

- **D125 — Pass C dropped.** State what is *not* built, the reason (verification loop, with the
  `DishSelectionTests` figures), the cost accepted, and the alternative's cost (a catalogue collapse
  iterated blind, ~24 h out). Name **D115, D116 and D120 as decided-but-unbuilt** — they stay in the
  log as reasoning, and must not be read as describing shipped code. `DishFamily` naming debt (D120)
  therefore never arises.
- Rewrite the existing `### Pass C — not started, and recommended for the drop` block into
  `### Pass C — dropped (D125)`, so the ledger states a decision rather than a recommendation.
- Leave `CLAUDE.md`'s **Catalogue** paragraph and `DESIGN.md`'s catalogue sections **untouched** —
  they already describe the nine families that ship. This was the deliberate reason they were not
  edited during Pass B.

### 2. One test probe, timeboxed, then hand it over

- `XcodeOpenWorkspace`, then confirm the destination is `iPhone 17 Pro (27.0)`
  (`XcodeSwitchRunDestination` if not — `RunSomeTests` silently returns `notRun` on the device
  destination, and that has already cost a session here).
- `BuildProject { buildForTesting: true }` → `GetBuildLog { severity: "warning" }` → then
  **one** `RunSomeTests` against a single cheap suite: `EvidenceWindowPlannerTests` (7 tests, pure
  `Calendar` arithmetic, no simulator UI).
- **If it wedges** (no progress after a few minutes): `TaskStop`, record the fifth attempt in the
  ledger, and ask the user for a ⌘U count. Do not retry a second time — the memory note already
  says 4 attempts bought nothing.
- **If it runs**: immediately run the full curated suite list, plus `UIStringLocalizationTests` and
  `CatalogueNameLocalizationTests` **in the same session as the build** (they read the built bundle
  — plan risk 8). Expected first failures, in order of likelihood: the arithmetic expectations in
  `DemonstrationScenarioOutcomeTests` (hand-computed oracles against `SyntheticScenarios`),
  `TodayViewModelTests`, then `DemonstrationScenarioCatalogueTests`' distinct-copy check. Fix the
  **implementation**, never the test.

### 3. `RenderPreview` — four screens, two type sizes, two languages

The screens the rebuild changed or added:

- `Presentation/Features/Onboarding/BodyBasicsView.swift` (new)
- `Presentation/Features/Today/TodayView.swift` + `Components/IntakeCheckInSection.swift` (new)
- the verdict display, and `Components/AllowanceBreakdownRow.swift` (new)
- Evidence Details (`EvidenceSectionsView.swift`, which lost its baseline rows)

Render each at default and **AX5**, in `en` and `es`. `AllowanceBreakdownRow` is the risk: it is a
`LabeledContent` grid of four figures with provenance captions, and Spanish *margen restante* is
longer than "allowance left". Prefer **standalone leaf-component previews** over composed
screen previews — a composed preview driving a ViewModel through two sequential `await`s snapshots
early here (known artifact, in memory), so a blank Today preview is not evidence of a bug.

### 4. Device walk from a fresh install — the one that shows on stage

Device interaction is simulator-only in this Xcode (D21), so this needs the user's hands.

- The user **deletes the app first** — V1 was edited in place (D110), so a stale store from the
  baseline schema would carry `trackingRepresentative` and no body basics.
- `XcodeSwitchRunDestination { displayTitle: "iPhone de CR" }` → `RunProject` → user walks:
  onboarding → Health permission → **body basics** (and once with it *skipped*, which must reach the
  self-report rather than a crash) → intake check-in → verdict → evidence details → appeal.
- `GetConsoleOutput` for the `Stage` labels. **Time the `.evaluating` stage** against WU-25-A's
  ~51 s: the 15→6 HealthKit query reduction predicts a large drop, and that prediction is currently
  unmeasured. Console logging shows only whatever `Logger` calls exist — top-level `Stage`, not
  every sub-flow — so report "not logged" as not logged, never as proof.
- **Switch the destination back to `iPhone 17 Pro (27.0)` afterwards**, or the next test run returns
  `notRun` with no error.

### 5. Audit agents, in order, with the right question

`arc-audit-concurrency` → `arc-verify-ui` → `arc-audit-hig` → `arc-audit-accessibility` →
`arc-constitution-review`. Give each the decisions log and the intended-state context, and ask
explicitly:

> Check whether each test could actually fail, and whether any comment, doc or ledger entry claims
> more than the code does.

That question is where every real finding on this project has come from — a test that could not
fail, a fixture that never suspended, a comment claiming an actor serialises, two false ledger
statements. One BLOCKER from `arc-audit-hig` or `arc-constitution-review` and the unit does not
close.

### 6. Close

Fix what the audits find (expect Presentation-layer edits), then re-run the gate: `BuildProject` →
`GetBuildLog { severity: "warning" }` → `totalFound: 0`. Then:

- Ledger evidence as **actual numbers** — test counts passed/failed, the measured `.evaluating`
  duration, which previews rendered at AX5 — and anything still owed written as owed.
- Memory note for any non-obvious decision, written now rather than at session end.
- Commit (Conventional Commits) and **push** — unpushed commits exist on one machine only.

## Verification

The unit closes on all three, not on my reading of the code:

| Gate | Evidence that counts |
|---|---|
| Build | `GetBuildLog { severity: "warning" }` → `totalFound: 0`, on both targets |
| Tests | A run with pass/fail counts — from `RunSomeTests` if the probe unwedges it, otherwise the user's ⌘U count reported back. Zero warnings is **not** a test run, and the ledger says so until this lands |
| Visual | `RenderPreview` images for the four screens at default + AX5 in both languages, plus the user's device walk with the `.evaluating` timing |
| Audits | Five agents, no BLOCKER outstanding |

If the runner stays wedged, the honest close is: build green, previews green, device walk green,
audits green, **tests unrun and recorded as owed** — the same tier this project already normalised
for the physical-device gap. That is the user's call to accept, and it is stated rather than glossed.
