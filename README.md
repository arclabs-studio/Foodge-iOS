# Foodge

**Foodge turns your day into a dinner verdict.**

It reads what Apple Health actually recorded today, applies a transparent arithmetic rule, and has a
playful food judge propose one dinner — **Treat**, **Balanced** or **Light**. You can inspect the
reasoning line by line, add context, or appeal with a craving.

Built for the ACoding Hackathon 2026. iPhone only, iOS 26+, Apple frameworks only, everything on
device.

> Foodge is a prototype product heuristic, not nutritional advice. The app says so on the screen
> that shows the numbers.

## The ritual

```
review today → add optional context → request a verdict → see dinner and reasoning → optionally appeal
```

| Step | What happens |
|---|---|
| **Today** | The evidence Health could read today, optional context (dinner time, energy, craving, a note) and the *eaten so far* check-in |
| **Verdict** | A category, one dish with its artwork, the deterministic explanation, and an optional on-device AI flourish |
| **Evidence details** | Every component of the allowance, each line labelled *recorded* or *estimated*, with its source and window |
| **Appeal** | Name a craving; Foodge offers a compatible dish inside the same category, or says honestly that nothing matched |
| **History** | One case per local day, preserving the evidence, dish and rule version used at the time |

## The rule, in full

No black box. Tonight's category comes from today's **energy allowance** as a share of today's
maintenance (rule version **2.0.0**):

```
maintenance = resting energy + active energy
allowance   = maintenance − intake
share       = allowance / maintenance
```

| Evidence | Category |
|---|---|
| `share >= 0.35` | Treat |
| `0.20 <= share < 0.35` | Balanced |
| `share < 0.20`, negative included | Light |
| No allowance possible, and the user reports more / usual / less activity | Treat / Balanced / Light, labelled self-reported |
| Nothing at all, check-in skipped | Provisional Balanced |

Design decisions that matter more than they look:

- **The allowance is never floored at zero.** A negative allowance is a valid answer, it is shown as
  a negative figure, and it never suppresses a dinner suggestion.
- **Missing data stays missing.** An absent Health sample never becomes a zero, and Foodge never
  claims permission was "denied" — HealthKit cannot tell an app the difference between a refusal and
  an absence, so the wording is always *no readable data*.
- **Six named refusals, never a sentinel:** `missingActiveEnergy`, `noRestingBasis`, `noIntakeBasis`,
  `nonPositiveMaintenance`, `windowTooShort` (under 90 minutes since local midnight),
  `windowMismatch`. Each one routes to the self-report check-in instead of inventing a number.
- **Resting energy** comes from Health `basalEnergyBurned`; failing that, from Mifflin–St Jeor over
  the body basics you entered, **prorated by the local day's real length** — 23 hours on the morning
  Spain springs forward, never a fixed 86,400 seconds.
- **Intake** comes from Health `dietaryEnergy`; failing that, from a three-meal check-in whose
  buckets are editorial. A recorded total *replaces* an estimate, never adds to it. An unanswered
  slot is not a zero.
- **Sleep, steps and workouts only ever append a reason code.** Active energy already contains
  workout and step energy, so adding either would double-count.
- Health aggregation uses HealthKit statistics over calendar-aware windows, and sleep is the
  **union** of asleep intervals, never their sum.

## The catalogue

Nine dish families, three per category, 27 variants in total:

| Category | Families |
|---|---|
| Treat | Burgers · pizza · tacos |
| Balanced | Rice bowls · tortilla · pasta |
| Light | Lentil salad · vegetable soup · vegetable wraps |

Selection order is fixed and auditable: exclusions → category → craving and convenience → avoid the
last three days → favourites → stable order rotated by date. **An exclusion is never silently
relaxed** — if nothing matches, Foodge says so.

Calories are shown for a dish only where a real `CalorieReference` backs the figure. Editorial
ranges are never rendered as verified values.

## The judge's voice

Witty, encouraging, concise. It jokes about the case, never about a person's body, discipline or
worth. Cheat-meal framing is allowed in English; Spanish says *capricho*, never *comida trampa*.
Banned in both languages: "you earned this", "burn it off", guilt framing, any instruction to skip a
meal, and any medical or nutritional authority.

The optional on-device flourish may name the category and the dish and **may never state a number**.
Allowance figures appear only in deterministic copy, next to the arithmetic that produced them. A
validator enforces this before any generated line reaches the screen; anything it refuses falls back
to a reviewed bilingual template, silently.

## Privacy

- Everything is local. There is **no network code in the app at all** — no analytics, no accounts,
  no backend.
- Health data is read on the device and never written back.
- Health values, user notes and model prompts are **never logged**. Diagnostic logging emits state
  labels only.
- The local store is excluded from backup and file-protected (`.completeUnlessOpen`).
- Settings has a **delete local data** action that actually empties the store, and a labelled
  **demonstration mode** that runs entirely on an in-memory container so a demo can never touch or
  read your own data.
- Optional AI runs on-device through Apple's Foundation Models. The app is fully functional with it
  switched off, and on hardware that has no model at all.

## Running it

```
Xcode 27.0 · Swift 6 language mode · iOS 26 minimum · iPhone only
open Foodge/Foodge.xcodeproj      # scheme: Foodge
```

- Tests: **⌘U** (`FoodgeTests`, Swift Testing). Run them on a **simulator** —
  `UIStringLocalizationTests` reads the String Catalog through the build machine's own path and
  cannot pass on a physical device by construction.
- The build gate is a zero-warning build (`SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`, complete strict
  concurrency). The last **recorded** full run was 268 tests across 33 suites with 0 failures on
  iPhone 17 Pro (27.0); test functions have been added since, so `docs/implementation-tasks.md`
  rather than this line is the place where each run's real numbers are kept.
- No dependency resolution step: there are no third-party packages.
- Nothing to configure. On a simulator Health has no data, which is a supported path — Foodge falls
  through to the self-report check-in.
- **Settings → Demonstration** is the fastest way to see every category without waiting for a real
  day to produce them.

## How it is built

Clean Architecture with MVVM, one-way dependencies:

```
Foodge/Foodge/App/          composition root, entry point, session switching
Foodge/Foodge/Domain/       entities, use cases, service protocols, catalogue — Foundation only
Foodge/Foodge/Data/         Health, persistence, narration, sample and synthetic data
Foodge/Foodge/Presentation/ Features/<Screen>/{View, ViewModel, Components}
Foodge/FoodgeTests/         mirrors Domain and Data, Swift Testing
```

- `@Observable` view models, explicitly `@MainActor`; module default isolation is `nonisolated`.
- Swift 6 language mode with **complete** strict concurrency. No `@unchecked Sendable`, no
  `nonisolated(unsafe)`, no `@preconcurrency`, no GCD, no force unwraps.
- SwiftData schema V1; a single `@ModelActor` write point.
- Native SwiftUI controls and navigation throughout — `NavigationStack`, typed routes, no custom
  router.
- English and Spanish are equal experiences, both in `Localizable.xcstrings`.

## Documentation

| What | Where |
|---|---|
| Product specification and rules | `docs/foodge-plan.md` |
| Screens, visual identity, voice | `DESIGN.md` |
| Work units, evidence and the numbered decisions log | `docs/implementation-tasks.md` |
| Engineering rules for this repository | `CLAUDE.md` |

## Known limits

- iPhone only; no iPad layout, no widgets, no watch app.
- Validated on iOS 27; the iOS 26 manual walk is still owed.
- The dish catalogue is editorial and Spain-centric; calorie references are limited to the dishes
  that have a published source.
- Reading a full day of real Health data on a physical phone takes noticeably longer than on a
  simulator — the verdict screen shows a waiting state while it happens.
