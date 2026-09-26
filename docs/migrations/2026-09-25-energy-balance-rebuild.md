> **Read this before taking any work unit.** This plan supersedes the activity-baseline rule
> described in `docs/foodge-plan.md` §3 and in `CLAUDE.md` under *Product rules that bite*. Those
> two documents are updated by this plan, not before it.
>
> **Prep already done (25 Sep 2026):** the backup branch `backup/pre-energy-balance` is cut and
> pushed. It holds the last green, submittable state — 278/278 tests, zero warnings. Step 0's
> `git switch -c backup/...` is therefore already satisfied; only the feature branch remains.
>
> **The one judgement call that cannot be deferred:** Pass C (the catalogue collapse) is
> droppable. Make that call at the Checkpoint-B review, not at 20:00 on the 27th. Passes B + D
> alone ship a coherent product — the new allowance rule on the existing 27-variant catalogue.

# Foodge — back to the original idea: an allowance, not a personal baseline

## Context

Foodge today rules Treat / Balanced / Light by comparing **today's activity against the user's own
14-day recorded median**. That engine is built, tested (278/278 green) and in the current build —
but it is not the product you want.

The original idea is simpler: read Apple Health, fill the gaps with a short questionnaire, work
out **today's energy allowance**, and have the judge grant a cheat meal sized to it. A sedentary
day gets a salad; a day with good sleep and a real workout gets a burger. Ten dishes, each with a
calorie range. Playful, cheeky, explicitly not nutritional advice.

You chose a **full rebuild**, accepting the risk two days before the deadline (27 Sep 2026, 21:00
Europe/Madrid). This plan is built around that: five passes, each ending at a **green checkpoint**,
ordered so the droppable work is last. If the clock runs out after Pass B you still have a
coherent, shippable product — the new rule on the old catalogue.

**No architectural change.** Clean Architecture, MVVM, the protocol seams, the navigation shape,
the composition root, the demonstration mechanism and the testing doctrine all stay. What changes
is the product rule, the catalogue, the questionnaire and the copy.

### Decisions you took this session

| # | Decision |
|---|---|
| 1 | Full rebuild, risk accepted. **Backup branch off `develop` before any edit.** Gitflow thereafter. |
| 2 | Verdict decided by **energy balance**, using all available Health data plus body basics. |
| 3 | Catalogue → **exactly 10 dishes, one per kind, no variants**, each with a kcal range. |
| 4 | Questionnaire asks **body basics + meals so far**. |
| 5 | Chicken and fish ship on an **SF Symbol placeholder**; you supply two matching renders later. |
| 6 | The **voice ban is overturned**: cheat-meal framing allowed, allowance figures in copy, narration ban narrowed. |

---

## Step 0 — Branches, before any edit

```
git switch develop
git switch -c backup/pre-energy-balance
git push -u origin backup/pre-energy-balance
git switch develop
git switch -c feature/FOODGE-energy-balance
```

The backup is pushed immediately. Unpushed commits exist on one machine only.

---

## Step 1 — Ledger first (the repo's own rule)

`docs/implementation-tasks.md` line 24: *"A change to a product rule requires a new numbered
decision below, written before the code."* Write **D110–D120** before any Swift:

- **D110** Schema V1 is edited **in place**; the app is unreleased, so the store is discarded by a
  dev reinstall rather than migrated. Old saved cases are unrecoverable — their decision blobs
  encode a shape that no longer exists. Extends D10.
- **D111** The 14-day recorded baseline is removed. The verdict comes from today's energy balance.
  Supersedes D5, D6, D12, D13, D16, D23, D24, D32, D55, D56.
- **D112** Allowance = `(resting + active) − intake`, banded by **share of maintenance**, not by an
  absolute kcal figure, so the rule scales with body size.
- **D113** Maintenance uses Health `basalEnergyBurned`; absent that, Mifflin–St Jeor from body
  basics, **prorated by the calendar day's real length** (D7 survives and now matters more).
- **D114** Intake may be *estimated* from a questionnaire. `RestingEnergy` and `DailyIntake` are
  both two-case `recorded`/`estimated` enums so provenance is readable at every call site.
  Amends D48, D49.
- **D115** Catalogue collapses to 10 dishes, one per kind. `DishVariant` deleted; `CatalogueEntry`
  deleted. Supersedes D36, D40, D41, D42, D63.
- **D116** Dishes carry an **editorial** `kilocalorieRange`. This is not a verified figure —
  `CalorieReference` remains the only type allowed to claim one, and D50's no-dish-is-wired rule
  survives renamed. Partially reverses the "a generic burger has no calorie value" rule, and the
  copy must say the ranges are indicative.
- **D117** Onboarding gains body basics. Reverses the plan's "no unused weight / BMI" restriction —
  the data is now load-bearing, not decorative.
- **D118** The voice rule is replaced: cheat-meal framing allowed in English. Jokes about a
  person's body, discipline or worth, and any instruction to skip a meal, stay banned. **Spanish
  uses *capricho*, never *comida trampa*** — the latter carries exactly the guilt framing that
  remains banned, and it stays in `bannedPhrases`.
- **D119** The narration numeric ban is **narrowed by exactly three string removals** from
  `NarrationValidator.bannedPhrases`. `makesNumericClaim`, the digit ban and `NarrationPrompt` are
  untouched, so `NarrationPromptTests.promptContainsNoNumbers` stays pinned as the justification.
  The flourish may name the category and the dish; it may never state a number.
- **D120** `DishFamily` keeps its name although one dish per kind makes it a slight misnomer.
  Renaming touches 25 files, three persisted columns and four localization files for zero
  behavioural gain. Logged as naming debt.

---

## Pass A — additive only, build never breaks (green → green)

New Domain files land **beside** the old ones. Nothing references them, so the build and all 278
tests stay green while the hardest arithmetic lands with tests behind it.

### `Domain/Entities/BodyBasics.swift`
```swift
enum BiologicalSex: String, Codable, CaseIterable, Hashable, Sendable { case female, male }

struct BodyBasics: Hashable, Codable, Sendable {
    let sex: BiologicalSex
    let ageYears: Int
    let heightCentimetres: Double
    let weightKilograms: Double

    /// `nil` for an implausible answer — an unanswered questionnaire and a nonsense one both
    /// mean "no estimate is possible", never a nonsense BMR.
    init?(sex:ageYears:heightCentimetres:weightKilograms:)   // age 13...120, height 120...230, weight 30...300
}
```
Mirrors `Note`'s validating-failable pattern in `Domain/Entities/DailyContext.swift`.

### `Domain/Entities/IntakeEstimate.swift`
```swift
enum MealSlot: String, Codable, CaseIterable, Hashable, Sendable { case breakfast, lunch, snacks }

enum MealPortion: String, Codable, CaseIterable, Hashable, Sendable {
    case skipped, light, normal, heavy
    func kilocalories(for slot: MealSlot) -> Double   // editorial, by slot
}

/// Three explicit optionals, not `[MealSlot: MealPortion]` — a dictionary with an enum key does
/// not round-trip through Codable as an object, and `nil` ("not answered") must stay distinct
/// from `.skipped` ("I did not eat it").
struct IntakeQuestionnaire: Hashable, Codable, Sendable {
    let breakfast: MealPortion?
    let lunch: MealPortion?
    let snacks: MealPortion?
    var isAnswered: Bool
    var kilocalories: Double
}

enum DailyIntake: Hashable, Codable, Sendable {
    case recorded(EnergyAggregate)        // HealthKit dietaryEnergy — replaces, never adds
    case estimated(IntakeQuestionnaire)
}
```
Bucket table (kcal): breakfast 200 / 400 / 650 · lunch 350 / 650 / 1000 · snacks 100 / 250 / 500.
`.skipped` is 0 — an *answered* zero, which is a reading. An unanswered slot contributes nothing
and says so through `isAnswered`. **This is the distinction that keeps "missing stays missing"
true**, and it gets its own test.

### `Domain/Entities/EnergyAllowance.swift`
```swift
enum RestingEnergy: Hashable, Codable, Sendable {
    case recorded(EnergyAggregate)       // HealthKit basalEnergyBurned
    case estimated(kilocalories: Double, body: BodyBasics, window: DateInterval)
}

struct EnergyAllowance: Hashable, Codable, Sendable {
    let activeKilocalories: Double
    let restingKilocalories: Double
    let intakeKilocalories: Double
    /// resting + active. The denominator of `share`.
    let maintenanceKilocalories: Double
    /// maintenance − intake. **Never floored at zero.** Negative is a valid, returned value.
    let allowanceKilocalories: Double
    let share: Double                    // allowance / maintenance
    let restingIsEstimated: Bool
    let intakeIsEstimated: Bool
    let window: DateInterval
}
```
Absence is the absence of the enum (`RestingEnergy?` is `nil`), never a zero case — the same shape
`HealthAggregates` uses for its six optionals.

### `Domain/UseCases/BasalMetabolicRate.swift`
```swift
enum BasalMetabolicRate {
    static let formulaVersion = "mifflin-st-jeor"
    /// kcal/24 h. men: 10W + 6.25H − 5A + 5 · women: 10W + 6.25H − 5A − 161
    static func dailyKilocalories(for body: BodyBasics) -> Double
    /// Prorated by the fraction of the **local day** elapsed — never by 86 400.
    /// A 23-hour spring-forward day makes 19:30 a *larger* fraction of the day, not a smaller one.
    static func kilocalories(for body: BodyBasics, upTo window: DateInterval, calendar: Calendar) -> Double
}
```
`calendar` is injected, matching `DishSelection`'s precedent. `.autoupdatingCurrent` appears nowhere.

### `Domain/UseCases/CheatMealAllowanceRule.swift`
```swift
struct AllowanceRequest: Sendable {
    let activeEnergy: EnergyAggregate?
    let resting: RestingEnergy?
    let intake: DailyIntake?
    let window: DateInterval            // local midnight → evaluation instant
}

enum AllowanceUnavailableReason: Hashable, Sendable {
    case missingActiveEnergy
    case noRestingBasis                 // no basal samples and no usable BodyBasics
    case noIntakeBasis                  // no dietaryEnergy and no answered questionnaire
    case nonPositiveMaintenance         // a share of zero is meaningless
    case windowTooShort                 // < 90 min since local midnight
    case windowMismatch
}

enum CheatMealAllowanceRule {
    static let treatShare = 0.35        // share >= 0.35 → treat
    static let balancedShare = 0.20     // 0.20 ..< 0.35 → balanced; below → light
    static let ruleVersion = "2.0.0"

    static func allowance(_ request: AllowanceRequest) -> AllowanceOutcome
    static func decide(selfReport: SelfReportedActivity?) -> VerdictDecision   // fallbacks, unchanged in spirit
}
```
Boundary convention, stated once and pinned: `>= 0.35` treat, `>= 0.20` balanced, else light —
inclusive at each band's lower edge, mirroring the old table's "75 %–125 % both inclusive".

Missing input handling is structural, not sentinel: every input is `Optional`, every `guard let`
failure returns a **named** reason, and nothing coalesces to `0`. `windowMismatch` preserves
`CalorieProvenance`'s identical-`DateInterval` precondition (D47), with the one deliberate
relaxation that an `.estimated` resting or intake is built *from* `request.window` and so matches
by construction.

In Pass A the rule returns only its own `AllowanceOutcome` — it cannot yet build a `VerdictDecision`,
whose `CategoryBasis` still has the old shape. That keeps Pass A strictly additive.

**Sleep, steps and workouts inform the explanation, never the arithmetic.** Active energy already
contains workout and step energy, so any additive use double-counts — the project's own
non-negotiable. They append reason codes: workouts non-empty or high steps → `.strongActivityToday`;
sleep < 6 h → `.shortSleep`; `context.energyLevel == .low` → `.lowReportedEnergy`.

### New tests (Pass A)
`FoodgeTests/Domain/UseCases/BasalMetabolicRateTests.swift` — worked Mifflin values written as
literals from the published equation; proration across a 23-hour DST day.
`CheatMealAllowanceRuleTests.swift` — both boundaries, negative allowance, every unavailable reason.
`IntakeEstimateTests.swift` — unanswered → `isAnswered == false`; `.skipped` → 0.

**Checkpoint A:** zero-warning build, ~295 tests green.

---

## Pass B — the rule swap (red → green). Catalogue untouched.

Order matters: each deletion's dependents are rewritten first.

1. `Domain/Entities/VerdictDecision.swift`
   ```swift
   enum CategoryBasis: Hashable, Codable, Sendable {
       case energyBalance(EnergyAllowance)
       case selfReported(SelfReportedActivity)   // survives
       case provisional                          // survives
   }

   enum ReasonCode: String, Codable, CaseIterable, Hashable, Sendable {
       case generousAllowance, moderateAllowance, slimAllowance
       case allowanceSpent                        // allowance <= 0, its own sentence
       case restingEnergyEstimated, intakeEstimated
       case strongActivityToday, shortSleep, lowReportedEnergy
       case selfReportedMore, selfReportedUsual, selfReportedLess, checkInSkipped
   }
   // CategoryOutcome deleted — nothing returns needsTrackingConfirmation any more.
   ```
   **`.needsSelfReport` stays.** A day with no readable active energy cannot be given a number
   without inventing one, so `SelfReportCheckInSection`, the stage and the provisional fallback all
   survive. Only the *tracking-confirmation* path dies. Every reason code must be reachable — the
   four unreachable ones D62 tolerated do not come back.

2. `Domain/Entities/EvidenceSnapshot.swift` — drop `history`, drop `trackingRepresentative`, add
   `intake: IntakeQuestionnaire?` and `body: BodyBasics?`.
3. `Domain/Entities/HealthAggregates.swift` — delete `value(for metric:)`.
4. **Delete:** `Domain/Entities/ActivityBaseline.swift`, `Domain/Entities/RecordedPatternSummary.swift`,
   `Domain/UseCases/ActivityBaselineCalculator.swift`, `Domain/UseCases/DinnerCategoryRule.swift`,
   `Domain/Services/VerdictEngine.swift` (no conformer; D55's reason to keep it is gone),
   `Presentation/Localization/ActivityMetric+DisplayName.swift`.
5. `Domain/UseCases/CalorieProvenance.swift` — delete `CalorieComparisonRequest`, `compare`,
   `CalorieComparison`, its reasons and outcome (zero call sites; the preconditions are
   incompatible with an estimated input). **Keep `calories(for:references:)` and `CalorieReference`**
   — a verified portion reference and an editorial range must stay different things, and that is
   what lets the copy be honest about which is which.
6. **Data:** `Data/Health/HealthEvidenceReader.swift` (drop `historyDays` and the 14-window
   `TaskGroup`), `Data/Health/EvidenceWindowPlanner.swift` (drop history; add
   `localDay(containing:calendar:) -> DateInterval` for proration — DST handling stays and now
   matters more), `Data/Persistence/Models/UserPreferences.swift` + `Domain/Entities/PreferencesDraft.swift`,
   `Data/Persistence/PersistenceActor.swift`, the four `Data/SampleData/SyntheticScenarios*.swift`,
   `PreviewDependencies.swift`, `Data/Demonstration/DemonstrationEvidenceProvider.swift`,
   `App/DemonstrationSessionFactory.swift`.
7. **Presentation:** `Today/TodayViewModel.swift` (delete `.needsTrackingConfirmation`,
   `pendingComparison`, `evaluateRecordedComparison`; add the intake bindings; and finally write
   `SelfReportedActivity` into the persisted `DailyContext` — it never was, a latent gap found
   during exploration). **Delete** `Today/Components/TrackingConfirmationSection.swift`,
   `Onboarding/Components/RecordedPatternSection.swift`, `RecordedPatternUnavailableRow.swift`.
   **Add** `Onboarding/BodyBasicsView.swift` + `OnboardingRoute.bodyBasics`, and
   `Today/Components/IntakeCheckInSection.swift`. Rewrite `ReasonCode+DisplayName.swift`. Touch
   `EvidenceSectionsView`, `RecordedActivityRow`, `EvidenceDetailsView`, `VerdictView`,
   `CaseDetailView`, `HealthConnectionView`, `OnboardingViewModel`, `TodayBeforeVerdictView`.

New screens use native controls only: `Picker` for sex and portions, `Stepper`/`TextField` with
`.keyboardType(.numberPad)` for age, height and mass. The intake section matches the existing
"Tonight" section's `.navigationLink` picker style.

`EvidenceSectionsView` replaces the baseline rows with the allowance arithmetic, each line
carrying its own provenance label: maintenance (recorded / estimated), active, intake (recorded /
estimated), allowance, share.

**Dropping 14 of 15 HealthKit queries per evaluation is also the cheapest available fix for the
~51-second verdict** recorded as the most serious open finding in WU-25-A. Measure it.

**Checkpoint B:** zero-warning build, green tests. Catalogue is still 27 variants and that is fine.

---

## Pass C — the catalogue collapse (red → green). **This is the droppable pass.**

1. `Domain/Entities/Dish.swift` — `DishVariant` collapses into `Dish`.
   ```swift
   struct Dish: Hashable, Codable, Sendable, Identifiable {
       let id: String                       // "dish.burger"
       let family: DishFamily
       let nameKey: String
       let ingredients: [Ingredient]
       let diets: Set<DietProfile>
       let convenience: Set<ConvenienceTag>
       /// Editorial range for a normal portion. Not a verified reference and never rendered as one.
       let kilocalorieRange: ClosedRange<Int>
       var category: DinnerCategory { family.category }
   }

   enum DishFamily: String, Codable, CaseIterable, Hashable, Sendable {
       case burger, pizza, tacos          // treat
       case pasta, riceBowl, wrap         // balanced
       case chicken, fish, salad, soup    // light
   }
   ```
   `ClosedRange<Int>` is already `Codable`, `Hashable` and `Sendable` — no custom conformance.
   `DietProfile`, `ConvenienceTag` and `Ingredient` survive unchanged.

2. **Calorie ranges** — researched against USDA FoodData Central figures (14″ cheese-pizza slice
   ≈ 285 kcal; fast-food cheeseburger 300–550; 150 g cooked chicken breast ≈ 245; 150 g salmon
   ≈ 310; 1 cup cooked spaghetti ≈ 221 before sauce; burrito bowl 450–650):

   | Dish | Tier | kcal |
   |---|---|---|
   | burger | Treat | 650–900 |
   | pizza | Treat | 570–860 |
   | tacos | Treat | 450–700 |
   | pasta | Balanced | 450–700 |
   | riceBowl | Balanced | 450–650 |
   | wrap | Balanced | 400–600 |
   | chicken | Light | 350–500 |
   | fish | Light | 350–500 |
   | salad | Light | 300–450 |
   | soup | Light | 200–350 |

3. `Domain/Catalogue/DishCatalogue.swift` — delete `CatalogueEntry` and `entries`, `version = "2.0.0"`.
   `DishCatalogue+Dishes.swift` — the 10 dishes. `Ingredient+Catalogue.swift` — pruned to what the
   10 actually use; `DishCatalogue.ingredients` is derived from the dishes, so an orphaned static
   is dead code the warning gate will not catch.
4. `Domain/UseCases/DishSelection.swift` — `[Dish]` everywhere. `RankKey` keeps all five keys;
   `recency` collapses from three levels to two (variant and family are now the same thing);
   `alternative(to:among:)` loses its "different variant, same family" fallback and becomes simply
   "the next ranked dish"; `rotatedIndex` mods 10, which visibly cycles every 10 days — a good demo
   property. `soleBlockers` is unchanged and becomes *more* important.
5. `Domain/Entities/PersistedDishOutcome.swift` — `variantID` → `dishID`. Skip the SwiftData column
   renames in `VerdictRevision`/`Appeal`: it saves an hour and costs only a stale name.
6. Rename `Presentation/Localization/DishVariant+DisplayName.swift` → `Dish+DisplayName.swift`;
   edit `DishFamily+DisplayName.swift`, `DishCatalogue+DisplayName.swift`, `Ingredient+DisplayName.swift`.
7. `Today/Components/DishArtworkView.swift` — new 10-case switch. Chicken and fish return
   `Image(systemName:)` **from the same switch** (D60's single swap point), never a second branch
   in `DishSummaryRow`, and keep `.accessibilityHidden(true)` so a placeholder never announces
   itself differently from real artwork. Eight dishes map onto existing renders (lentil salad →
   salad, vegetable wrap → wrap, vegetable soup → soup). `DishTortilla` is orphaned — leave the
   asset, note it, delete it after the deadline.
8. Touch: `DishSummaryRow`, `AppealCompatibleSection`, `AppealCravingSection`,
   `AppealNoMatchSection`, `FavouriteFamiliesSection`, `SettingsViewModel`, `TodayViewModel`.

### The exclusions cliff — the one genuine product hole

With one dish per kind and three per tier, a single exclusion can empty a whole tier: "bread" kills
burger and wrap at once. Three mitigations, by value:

1. **Keep the honest `.noMatch(blockingIngredientIDs:)`.** Never silently relax. Already built and
   tested (D43, D58) — no new behaviour.
2. **Ingredient lists are core components only.** Burger = `[beefPatty, burgerBun, lettuce, tomato]`,
   not six items with mayonnaise and onion. Garnishes in the list are exclusion landmines with no
   user value.
3. **A live coverage counter on the exclusions screen.** `IngredientExclusionsView` gains a footer
   reading "N of 10 dishes still available", from the same `DishSelection` filter. One computed
   property, one string — the cheapest way to stop someone walking into an empty catalogue without
   ever relaxing an exclusion.

Also verify by test that **every `DietProfile` × every `DinnerCategory` yields at least one dish**.
Model each dish's `diets` generously — a "burger" covers a bean burger — or a vegan has no Treat.

And: on a `.noMatch` night the **allowance figure is still shown**. The verdict now has a number
even with no dish, which is a real improvement on today's empty no-match screen.

**Checkpoint C:** zero-warning build, green tests.

---

## Pass D — voice (green → green)

`Domain/UseCases/NarrationValidator.swift`: remove exactly `"cheat meal"`, `"cheat day"` and the
English guilt phrases named in D118 from `bannedPhrases`. **Keep** `"comida trampa"` banned, and
keep the digit ban, `%`, `numberWords` and `measurementUnits` intact. `NarrationPrompt.swift` is
not touched, so `NarrationPromptTests.promptContainsNoNumbers` stays pinned — and that test is the
whole justification for the digit ban. "The flourish may reference the verdict" is satisfied by the
category words, which were never banned.

Allowance figures go only into **deterministic Presentation copy**, never into the model prompt.

`NarrationValidatorTests`: the "cheat meal is rejected" test **flips to an acceptance test**.
Everything else in that suite is untouched.

---

## Pass E — localization and final verification

### Dying keys need no work at all

Xcode marks unreferenced keys `extractionState: "stale"` on the next build, and
`UIStringLocalizationTests.declaredKeys` already filters `stale` out. So for the ~38 baseline /
pattern / tracking keys, the ~17 obsolete variant nameKeys and the ~30 obsolete ingredient
nameKeys, **the correct action is nothing**. No `.xcstrings` surgery, no risk. Optional cleanup
after the deadline.

### New keys — this exact order

1. Write the new `LocalizedStringResource` literals in Swift.
2. **Build.** Extraction adds the English keys automatically. This is the only legitimate way keys
   enter the catalog.
3. `StringCatalogRead` to list keys with no `es`.
4. `StringCatalogEdit` to add each Spanish value, ≤ 15 per batch, against the fixed courtroom
   glossary (*veredicto · el juez · el tribunal · las pruebas · apelar · **capricho***).
   **Never let a translation pass touch an English source string** — a sub-agent once plural-varied
   one irreversibly (D83) and it is not reversible through tooling.
5. Rebuild, then run `UIStringLocalizationTests` and `CatalogueNameLocalizationTests`.

Run this loop at the end of **each** pass, not once at the end. Left to the end it becomes a
40-key Spanish sprint at the worst possible moment.

### `CatalogueNameLocalizationTests` — keep the suite, edit three lines
Its oracle is the built `es.lproj` out of `Bundle.main` and is unaffected by the rebuild.
`DishCatalogue.entries.map(\.variant.nameKey)` → `DishCatalogue.dishes.map(\.nameKey)`; the
`for entry in` loop iterates `dishes` and calls `dish.localizedName(in:)`; `entry.variant` → `dish`
in the identifier check. Both localization suites read the **built** bundle — build immediately
before running them, or they pass on stale translations.

---

## Demonstration mode

All ten cases in `Domain/Entities/DemonstrationScenarioID.swift` are replaced. Declaration order is
offer order and must match `SyntheticScenarios.all` — `DemonstrationScenarioCatalogueTests` enforces
that and stays.

| Case | Demonstrates | Expected |
|---|---|---|
| `generousAllowance` | Big active day, light intake, resting recorded | Treat, share ≈ 0.45 |
| `modestAllowance` | Ordinary day | Balanced, share ≈ 0.27 |
| `slimAllowance` | Quiet day, heavy lunch | Light, share ≈ 0.12 |
| `allowanceSpent` | Intake exceeds maintenance | Light, allowance **negative**, dish still recommended |
| `estimatedResting` | No `basalEnergyBurned`; body basics drive Mifflin | Balanced + `.restingEnergyEstimated` |
| `estimatedIntake` | No `dietaryEnergy`; questionnaire supplies it | Treat + `.intakeEstimated` |
| `noHealthData` | Nothing readable *(kept)* | `.needsSelfReport` |
| `shortSleep` | 4 h sleep *(kept)* | Tier unchanged by sleep; `.shortSleep` present |
| `dstSpringForward` | 29 Mar 2026, a 23-hour local day *(kept)* | Prorated BMR uses a 23-hour day |
| `noCompatibleDish` | Vegan + exclusions empty the tier *(kept)* | `.noMatch`, allowance still shown |

`estimatedResting` and `estimatedIntake` become the scenarios that fail if D100's seeding rule is
dropped — body basics and the questionnaire are read from **stored preferences**, not from the
snapshot.

---

## Tests

Keep the suite architecture exactly: build a real `TodayViewModel` from `DemonstrationSessionFactory`,
drive it end to end, and use an **oracle independent of the code under test** — never call the rule
to check the rule.

**Delete (1 file):** `ActivityBaselineCalculatorTests.swift`.

**Rewrite:** `DinnerCategoryRuleTests` → `CheatMealAllowanceRuleTests` · `CalorieProvenanceTests`
(the 8 `compare` tests **port their arithmetic oracles** into the allowance suite — the sum, the
negative result, the window mismatch and replaces-never-adds all still apply; the 4
`calories(for:references:)` tests survive verbatim) · `DishCatalogueTests` · `TodayViewModelTests` ·
`OnboardingViewModelTests` · `DemonstrationScenarioOutcomeTests` · `DemonstrationScenarioCatalogueTests`.

**Edit (fixtures only; assertions survive):** `DishSelectionTests` (25 tests, 466 lines — the
largest mechanical job; ~21 assertions survive, the 4 "different variant, same family" ones die) ·
`HealthEvidenceReaderTests` · `EvidenceWindowPlannerTests` · `NarrationValidatorTests` ·
`CalorieReferenceCatalogueTests` (`noCatalogueDishVariantIsWiredToAReference` →
`noCatalogueDishIsWiredToAReference`) · `CatalogueNameLocalizationTests` · `CaseStoreTests` ·
`TodayNarrationViewModelTests` · `TodayAppealViewModelTests` · `HistoryViewModelTests` ·
`SettingsViewModelTests` · `DemonstrationSessionTests` · `DemonstrationEvidenceProviderTests` ·
the three fixture files.

**Untouched (73 tests):** `SleepIntervalUnionTests`, `NarrationPromptTests`, `DeadlineNarratorTests`,
`ValidatingNarratorTests`, `FoundationModelsNarratorTests`, `LocalReminderServiceTests`,
`UIStringLocalizationTests`, `IngredientOrderingTests`, `NarrationTemplateLocalizationTests`.

Landing zone ≈ 290–300 tests.

### The three tests that matter most

- **DST proration.** `86_400` is the obvious wrong answer and passes nine tests in ten. Write the
  literal expected value **before** implementing `BasalMetabolicRate`: a 35-year-old male, 70 kg,
  175 cm gives `10·70 + 6.25·175 − 5·35 + 5 = 1623.75` kcal/day; at 03:10 on a 23-hour day the
  fraction is `3.1667 / 23`, not `3.1667 / 24`.
- **`allowanceSpent`.** `allowanceKilocalories < 0` **and** `dishOutcome == .selected` — the
  "negative results never suppress a dinner suggestion" rule, which nothing currently tests.
- **Unanswered vs `.skipped`.** The distinction that keeps "missing stays missing" true.

Per the project's own hard-won note, every audit prompt must say explicitly: *"check whether each
test could actually fail, and whether any comment, doc or ledger entry claims more than the code
does."*

---

## SwiftData

**Edit `FoodgeSchemaV1` in place. No V2, no migration stage.** Four reasons:

1. D10 already establishes dev-reinstall-while-unreleased, and `FoodgeSchemaV1`'s own doc comment
   says so.
2. `FoodgeMigrationPlan.stages` is empty today, so the project already depends on inference or a
   reinstall for any model change.
3. `VerdictRevision.decisionData` and `evidenceData` are opaque `Data`. **Their SwiftData schema
   does not change at all** when the JSON shape changes. A migration stage cannot help; only a JSON
   rewrite could, and that is hours protecting zero real users.
4. `ContainerFactory` failure already surfaces as `AppLaunch.State.storeUnavailable` →
   `StoreUnavailableView`. A store that refuses to open shows a screen, not a crash.

Edits within V1: `UserPreferences` `−trackingRepresentative`, `+bodySexRawValue: String?`,
`+bodyAgeYears: Int?`, `+bodyHeightCentimetres: Double?`, `+bodyWeightKilograms: Double?`, with a
computed `var bodyBasics: BodyBasics?` returning `nil` unless all four parse — the same idiom as
`dinnerRoutineRawValue`.

**One real code change worth making regardless:** verify in `CaseStoreTests` that a revision whose
`decisionData` fails to decode is **skipped** by `allCases()` (D66) rather than propagating and
killing the whole History list. If it currently propagates, fix it.

**Instruction for the implementer: delete the app from the simulator and from the device before
the first run after Pass B.** Do not spend an hour discovering whether lightweight migration
handles the `trackingRepresentative` removal.

---

## Docs

`docs/foodge-plan.md` §3 rewritten: the activity baseline and ratio table out, the allowance rule
and the 10-dish catalogue with ranges in. The calorie section inverts — it now defines an
allowance, so it must say plainly that the figures are estimates and the app is not nutritional
advice.

`DESIGN.md`: voice rules per D118, recorded-pattern and tracking-confirmation screens out, body
basics and intake check-in in, dish asset list updated.

`CLAUDE.md`: the "Category decision table" and "Baseline" blocks under *Product rules that bite*
are replaced. **"Missing Health data stays missing" stays** — it now governs the questionnaire too.

---

## Verification

Per the `foodge-verify` skill:

1. `BuildProject` → `GetBuildLog severity: "error"` **and a second call at `severity: "warning"`.**
   The second call is the one that gets skipped; zero warnings is a build gate here.
2. `RunAllTests` on iPhone 18 Pro (27.0). Record the actual count, not "tests pass".
3. `RenderPreview` for Body Basics, Today (with the check-in), Verdict and Evidence Details, at
   default and AX5 Dynamic Type, both languages.
4. `RunProject` on the physical iPhone plus `GetConsoleOutput` — device interaction is
   simulator-only in this Xcode (D21). Walk: onboarding → body basics → Health → check-in →
   verdict → evidence details → appeal → history, from a **fresh install**.
5. **Time the `.evaluating` stage** and report the number. Pre-change it was ~51 s on device.
6. Agents, in order: `arc-audit-concurrency` → `arc-verify-ui` → `arc-audit-hig` →
   `arc-audit-accessibility` → `arc-constitution-review`. A unit closes on their green, not on my
   reading of it.

---

## Risks, worst first

1. **Two days to the deadline; feature freeze was yesterday.** *Mitigation:* the five-pass split
   gives four green checkpoints. If time runs out after Pass B + D you have a shipped allowance
   rule on the old 27-variant catalogue — a coherent product. **Pass C is the droppable one.
   Decide that at the Checkpoint-B review, not at 20:00 on the 27th.** The backup branch always
   holds a green, submittable app.
2. **`DishSelectionTests.swift`** — 466 lines, 25 tests, all built on `CatalogueEntry`. Easy to
   underestimate. *Mitigation:* do it **first** within Pass C, before any Presentation file, so a
   nasty fixture swap surfaces while only one file is red.
3. **Spanish falls behind.** *Mitigation:* the extraction-and-translate loop runs at the end of
   every pass. This is still the most likely thing to be half-done at 21:00.
4. **The exclusions cliff.** *Mitigation:* core-ingredient lists, the coverage counter, and the
   diet × category coverage test.
5. **Mifflin proration and DST.** *Mitigation:* the literal-valued DST test, written before the
   implementation.
6. **Near-zero maintenance denominator.** `share = allowance / maintenance` divides by a tiny
   figure at 00:30 local. *Mitigation:* the `nonPositiveMaintenance` and `windowTooShort` guards,
   both pinned by test.
7. **Stale store on first run after Pass B.** *Mitigation:* delete the app before first run, every
   time; `StoreUnavailableView` catches a forgotten one.
8. **`es.lproj` staleness trap.** Both localization suites read the built bundle. *Mitigation:*
   build immediately before running them; never diagnose a localization failure without a fresh
   build.
9. **Narration ban over-correction.** Removing the digit ban alongside the phrase ban would let the
   model invent a kcal figure — the worst possible regression for this product. *Mitigation:* the
   change is exactly three string removals; `makesNumericClaim` and `NarrationPrompt` are untouched.
10. **Chicken and fish on SF Symbols** next to eight sculpted renders. *Mitigation:* reversible in
    one file. If your renders do not arrive, either keep the placeholder or cut to eight dishes
    rather than ship a mismatched look.
11. **`DishTortilla` orphaned.** An unreferenced imageset is not a warning and will ship.
    *Mitigation:* leave it, note it, delete after the deadline. No asset-catalogue surgery on
    deadline time.
12. **`TodayViewModel` is the biggest single edit** and everything routes through it.
    *Mitigation:* do it last within Pass B, after the Domain types are green, so the compiler
    drives the change rather than guesswork.
