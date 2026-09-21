# Foodge — implementation task ledger

Executable work units for the ACoding Hackathon 2026 build (18–27 Sep 2026).
Read `docs/foodge-plan.md` (product rules) and `CLAUDE.md` (engineering rules) before taking a unit.

## Conventions

Each work unit records six fields:

| Field | Meaning |
|---|---|
| **Objective / scope** | What the unit delivers, and what it is explicitly not allowed to touch. |
| **Inputs / docs** | Plan sections, Apple documentation and skills to read first. |
| **Acceptance** | Observable criteria. Not "looks right" — a signal someone else could check. |
| **Tests / verifier** | The external signal that closes the unit. The agent's own opinion never closes it. |
| **Evidence** | Filled in on completion: build result, test counts, screenshot paths under `docs/evidence/`. |
| **Next** | The unit that follows. |

Rules for every unit:

- One unit at a time. A unit closes on zero-warning build + green tests + (for UI) visual verification.
- Checkpoint commit per unit, Conventional Commits, on `develop`.
- Evidence never contains real Health values — screenshot paths and pass/fail only.
- A change to a product rule requires a new numbered decision below, written before the code.

Status legend: ⬜ not started · 🟦 in progress · ✅ closed green · 🟥 blocked.

---

## Decisions log

| # | Decision | Rationale |
|---|---|---|
| D1 | Project template created with `storageType: None`; SwiftData is added by hand. | The template's `Item` model and `.modelContainer(for:)` boilerplate is dead code. We need a `VersionedSchema` V1, an in-memory demo container and `modelContainer(_:onSetup:)`. |
| D2 | `testingSystem: Swift Testing`. The UI-test bundle stays XCTest and carries only the template smoke test this session. | Constitution: Swift Testing for unit/integration, XCTest for UI automation. |
| D3 | Module default actor isolation is `nonisolated`; every View and ViewModel is explicitly `@MainActor`. | Plan §4 overrides the MainActor-by-default convention used in FavRes. |
| D4 | `HealthKitSampleSource` is an `actor` owning `HKHealthStore`, mapping HealthKit results to `Sendable` values inside the actor. | Updated after review: `HKHealthStore` **is** `Sendable` (annotated `NS_SWIFT_SENDABLE` in the iOS 27 SDK, and documented as conforming), and `HealthAuthorizationService` already depends on that to be a `Sendable` struct. The actor therefore stands on its real merit rather than on sendability: it serialises query state and keeps the fan-out of 15 windows off the main actor. |
| D5 | The test seam is the `HealthSampleSource` protocol (raw per-window sums, raw asleep intervals, workout list). `HealthEvidenceReader` composes a source, an injected `Calendar` and pure domain aggregators. | Sleep union, absent-vs-zero and workout non-double-counting are then testable in the unit target with no HealthKit present. |
| D6 | Same-local-time history is 15 parallel `HKStatisticsQueryDescriptor(.cumulativeSum)` queries in a `TaskGroup`, one per window `[startOfDay(d), sameClockTime(d))`. | A collection query yields full-day buckets and cannot cut each historical day at today's clock time. |
| D7 | The `Calendar` is injected with an explicit `timeZone` and frozen into the snapshot; `.autoupdatingCurrent` never appears in domain code. DST handled with `matchingPolicy: .nextTime`, `repeatedTimePolicy: .first`; day length always from `dateInterval(of: .day)`. | Plan §3 requires calendar-aware windows and forbids assuming 86,400-second days. |
| D8 | Every Health aggregate is `Optional`. `sumQuantity() == nil` maps to `nil`, never to `0`. | Plan §3: missing values remain missing. |
| D9 | Onboarding completion is `UserPreferences.onboardingCompletedAt: Date?` in schema V1. No `AppStorage` flag. | Single source of truth, deleted together with local data, and the demo container gets its own copy. |
| D10 | Schema V1 starts on Day 19 with `UserPreferences` only. `DailyCase`, `VerdictRevision` and `Appeal` join V1 on Day 21. | The schema is unreleased; growing V1 before submission is a dev reinstall, not a migration. |
| D11 | Test doubles are `actor`s, or `final class: Sendable` with `Mutex`-protected state. | `@unchecked Sendable` is forbidden. |
| D12 | The category rule returns `CategoryOutcome { .verdict(VerdictDecision) \| .needsTrackingConfirmation }`. | The plan requires asking whether tracking reflects the day *before* issuing a low-activity verdict. A fake provisional verdict would misrepresent the decision. |
| D13 | The category rule is implemented on Day 19 alongside the baseline calculator, not Day 20. | Both are pure and small, and Day 19 must close green. Day 20 keeps catalogue, selection and the calorie engine. |
| D14 | The feasibility probe is a `#if DEBUG` `FeasibilityProbeView` used as the root of `AppRootView` on Day 18, and deleted in the Day 19 onboarding commit (an acceptance criterion of WU-19-D). | Nothing else exists to host it on Day 18, the Xcode MCP has no scheme-environment tool, and no dead code may survive the day. |
| D15 | Judge artwork is a placeholder `JudgeBadgeView` wrapping an SF Symbol until Day 24. | The final-artwork swap then touches one file. |
| D16 | Even-count median is the mean of the middle pair. The sleep window is the previous day 18:00 → evaluation time. | Product rules not specified in the plan; recorded here so they are reviewable. |
| D17 | `.DS_Store` added to `.gitignore`; an in-repo copy of internal studio material deleted (the original stays outside the repository). | Hygiene, and licensed material must remain outside the submission repository. |
| D18 | `SWIFT_VERSION` is set to `6.0` on all three targets rather than left at the template's value. | The Xcode 27 multiplatform App template sets `SWIFT_VERSION = 5.0`, which silently forces `SWIFT_STRICT_CONCURRENCY` to `minimal` and disables every Swift 6 upcoming feature. The plan said to keep the language-mode value the template set and never invent `6.4`; `6.0` is the language-mode value that actually satisfies the plan's "Swift 6 language mode" baseline. |
| D19 | `SUPPORTS_MACCATALYST` is not set. | Xcode 27 rejects it: "Unknown build setting". `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"` already excludes macOS and Mac Catalyst. |
| D20 | `LocalizationPlanner` was called although its documented precondition skill (`xcode-integration:translation-coordinator`) does not exist in this environment. | The user directed that localization must use the Apple/Xcode-native route, and the planner is that route. The missing item is Xcode's own instruction skill, not a capability. No `.xcstrings` file is ever hand-edited. |
| D21 | Physical-device verification is done with `RunProject` plus the device log, not with the Xcode MCP's device-interaction tools. | Those tools refuse a physical iPhone outright: "The device you are targeting is not supported for Device Interaction. Supported: iOS [Simulator] 27.0+". The probe therefore logs its state labels — never a Health value, never model output — so results can be read back with `GetConsoleOutput`. This also constrains how `arc-verify-ui` can verify on device for the rest of the build. |
| D22 | `HealthReadTypes` was written in WU-18-D rather than waiting for WU-19-B. | The probe must request exactly the six product types, and having two definitions of that set — one temporary, one real — is how they drift apart. |
| D23 | Metric preference is resolved as: try active energy; if it cannot supply a usable comparison — too few observations **or** a zero median — try steps on the same rules; if steps also fail, report the **energy** failure, and `insufficientHistory(found:)` carries the count of usable **energy** observations. | The brief says "use steps when energy cannot supply a usable comparison" without saying whether a zero median counts as "cannot". Reading it as "cannot" is what keeps a user whose watch reports zero calories but real steps from losing their pattern entirely. Reporting the preferred metric's reason makes the failure deterministic instead of depending on which metric failed last. Pinned by `aZeroEnergyMedianFallsBackToSteps`. |
| D24 | `ActivityBaseline.window` is the span from the first to the last day actually used. Calendar-aware cutting of each day at the evaluation's local clock time is `EvidenceWindowPlanner`'s job (WU-19-B), not the calculator's. | The calculator receives only `[DailyActivityObservation]` — no calendar, time zone or cutoff — so it cannot be where the DST rule lives. Splitting it this way keeps the calculator pure and puts the daylight-saving tests where the calendar actually is. Pinned by the window expectations in `aFullFortnightUsesTheMedian`. |
| D25 | The test target declares a fifth tag, `.domain`, alongside the constitution's `.unit` / `.integration` / `.ui` / `.critical`. | Additive, not a substitution: it separates domain-rule suites from plumbing suites once the Data and Presentation suites arrive. All four constitutional tags remain declared. |
| D26 | Every Info.plist key and entitlement is verified against the **built** `Foodge.app/Info.plist`, never against `AddInfoPlist`'s return value. | The first `AddInfoPlist(NSHealthShareUsageDescription)` returned `{"result": true}` and persisted nothing — the key was absent from the build settings, from `Foodge-InfoPlist.xcstrings` and from the built plist. HealthKit then terminated the app on the device the moment authorization was requested: *"NSHealthShareUsageDescription must be set in the app's Info.plist in order to request read authorization"*. A second identical call persisted correctly. A tool's success result is not evidence that the project changed. |
| D27 | "One type per file" is read as one *concept* per file: a primary type may share its file with the small value types that exist only as its members, and the file is named after the primary type. | Splitting `BaselineUnavailableReason` or `ActivityMetric` into their own files would scatter one idea across four, and the plan's own type sketch groups them this way. The rule still bites where it matters: no file mixes unrelated types. Applies to `Dish`, `HealthAggregates`, `DailyContext`, `ActivityBaseline`, `VerdictDecision`, `EvidenceAvailability`, `EvaluationClock` and `SyntheticScenarios`. |
| D28 | `Data/SampleData/SampleData.swift` — the `PreviewModifier` with an in-memory container — moves from WU-18-C to WU-19-C. | A `PreviewModifier` needs a `ModelContainer`, and the schema does not exist until WU-19-C (D10). Writing it in WU-18-C would have meant a preview helper with nothing to hold. The scenarios themselves landed on Day 18 as planned. |
| D29 | The store directory uses `.completeUnlessOpen` file protection, not `.complete`, and is excluded from backups. | The plan said "complete file protection". `.complete` makes a file unreadable the instant the screen locks, including one the app already has open — which for a database mid-write means failed saves and a corrupt store, exactly the failure the setting was meant to prevent. `.completeUnlessOpen` keeps the protection at rest (nothing readable while locked and the app is not running) without breaking an open database. Protection and backup exclusion are applied to the directory so the SQLite sidecar files are covered too. |
| D30 | Redundant `Sendable` conformances were removed from `QuantityKind` and the test fixture's `Today`, but kept on `HealthAuthorizationService`. | The constitution forbids redundant conformances on value types, and for pure value types they are noise. `HealthAuthorizationService` is the exception: it stores a class reference (`HKHealthStore`), so spelling the conformance out converts "someone stores a non-Sendable type here" from a silent loss of the guarantee into a compile error. Documented in the file itself. |
| D31 | `IngredientExclusionsView` is deferred from WU-19-D to WU-20-A. WU-19-D ships four onboarding screens; `PreferencesDraft.excludedIngredientIDs` stays in the model and is written as an empty set. | `Ingredient` is declared and never constructed — the catalogue is WU-20-A. A picker over invented identifiers risks exclusions that silently never bite once the real catalogue lands, which the brief forbids ("never silently relax an exclusion"). Keeping the field in the model means no migration is owed when the screen arrives. The alternative — shipping the seam now — costs a screen that has to be localized and audited twice. |
| D32 | Schema V1 grows `UserPreferences.trackingRepresentative: Bool`, defaulting to `true`. `versionIdentifier` stays `1.0.0`. | `markUnrepresentative(_:)` is in WU-19-D's action list, but the flag lived only on `EvidenceSnapshot`, so the mark would not survive a relaunch. D10 already establishes that growing unreleased V1 is a dev reinstall, not a migration. The default is `true` because unasked means "use my data", which is what a user who skipped the Health step expects. This is the *standing* question — may the recorded fortnight be used as a baseline at all, exactly `ActivityBaselineCalculator`'s parameter — and is distinct from the per-day confirmation the category rule asks for on Day 21. |
| D33 | The brand colour sets (`AppBurgundy`, `AppGold`, `AppBurgundyMuted`, plus a value for `AccentColor`) are authored in WU-19-D with all four appearances; artwork still lands on Day 24. | The constitution forbids colour literals in code, so anything tinted needs the catalogue the moment `JudgeBadgeView` exists. Day 24 then swaps artwork only, not the palette. The Xcode MCP exposes no asset-catalogue tool, so the `.colorset/Contents.json` files are written into the synchronized root group — filesystem work, not a `project.pbxproj` or `.xcstrings` hand-edit. |
| D34 | Three protocol seams are introduced — `HealthAuthorizing` and `PreferencesStore` in `Domain/Services/` — and `PreferencesDraft` moves from `Data/Persistence/` to `Domain/Entities/`. Both existing concrete types conform with no API change. A `#Preview` is a composition root: `PreviewDependencies` (`#if DEBUG`) may name `AppDependencies`, which production Presentation code may not — so the assembly lives in `AppDependencies.makeOnboardingViewModel()` (App layer) and `OnboardingViewModel` has no initializer naming `AppDependencies` at all. | The ledger named the concrete `HealthAuthorizationService` and `PersistenceActor` as ViewModel dependencies. One presents a system sheet (untestable off-device) and the other's save throws only when `modelContext.save()` does, which an in-memory container never will — so a failed save would be unreachable in tests. `PreferencesStore` names `PreferencesDraft`, so the draft has to be Domain, or `OnboardingViewModel` would import Data and break the one-way dependency direction `arc-constitution-review` checks. |
| D35 | `OnboardingViewModel.HealthState` has a sixth case, `.requestFailed`, beyond the five the ledger named. | The five cannot express "the authorization request itself did not complete". Mapping that to `.noReadableData` would assert an absence the app cannot prove — the same mistake as claiming denial. |
| D36 | The catalogue is a pure `Domain/Catalogue/` namespace (`enum DishCatalogue`, `static let`s, `version = "1.0.0"`). No protocol, no `Data/` implementation, no `AppDependencies` field. | A seam here has no I/O and no failure mode to drive in a test (D34's own reasoning). A JSON resource would convert compile-time guarantees about diet sets into a runtime decode path days before submission. |
| D37 | `nameKey` is English display text, resolved with `LocalizedStringResource(String.LocalizationValue(stringLiteral:))`, not a dotted identifier. | Forced by a finding: the built app ships **no `en.lproj`** — English is the source language, so a String Catalog key *is* the English string. A dotted key would render the raw identifier on screen in English. The rejected literal `switch` over 71 cases would buy compile-time extraction at the cost of a second copy of the catalogue nothing keeps in step (the exact duplication D27 and `DinnerCategory.families` both exist to prevent). |
| D38 | `IngredientExclusionsView` is pushed from `PreferencesView`, not a fourth linear onboarding step. `OnboardingRoute` gains `.ingredientExclusions`. | Exclusions are optional and secondary; a fourth required step puts a Continue gate in front of an optional choice and still needs a Settings entry later. |
| D39 | Repeat-avoidance history is a parameter (`recentSelections: [RecentDishSelection]`) on `DishSelection.select`, not a `CaseStore` method. Callers pass `[]` until Day 21. | `DailyCase` is D10-deferred to WU-21-A, so there is no history to read yet — but the rule about *which* history counts belongs with the selection rule, not with a store that has no conformer. |
| D40 | Rotation is a continuous local-day index since the reference date (1 Jan 2001), mod the **full catalogue count** — never the candidate count. | Day-of-year mod N jumps backwards 364 days each New Year (pinned by `newYearRotatesByOne`, which fails against that implementation). Modding by the candidate count would shift one user's rotation the moment they excluded an ingredient. |
| D41 | Repeat avoidance is two-level (same variant = penalty 2, same family = penalty 1, else 0) and is a ranking preference, not a hard filter. | Variant-only avoidance would still serve beef, halloumi and black-bean burgers on three consecutive nights — the same dinner, as the user experiences it. Keeping it a preference (not a filter) is what stops a small candidate set producing an honest no-match it doesn't need to. |
| D42 | A distinct alternative prefers a different family; falls back to a different variant in the same family; `nil` when only one candidate survives. | A "second-ranked candidate" is cheaper to write but produces "Beef burger — or try the Halloumi burger": the same recommendation again with different cheese. |
| D43 | No-match is a returned value (`.noMatch(blockingIngredientIDs:)`), never a thrown `FoodgeError.noCompatibleDish`. Nothing throws that error in WU-20-B. | An empty candidate set is a correct consequence of the user's own exclusions, not a failure. Throwing would force every call site into `do/catch` to render a normal screen and would discard *which* ingredient is blocking — the screen needs that to say which exclusion to revisit. |
| D44 | `VerdictEngine` is not grown with a `selectDish` method; its doc comment (which claimed dish selection "joins this protocol on Day 20") is corrected instead. | The claim was false since D13 put the category rule outside `VerdictEngine`, and the protocol has no conformer anywhere. Adding a method would create a second declaration of a contract with no implementation to hold it — the exact "doc claims more than the code does" defect the audit prompts here hunt for. |
| D45 | Convenience scores the intersection size between a variant's tags and a preference set derived from `DailyContext` (`dinnerTime == .quick` → `{quick, onePan, noCook}`; `energyLevel == .low` → adds `{onePan, noCook}`). Sleep-driven easing is deferred to Day 21. | Counting rather than testing membership lets a hurried *and* tired user's no-cook one-pan dish outrank a merely-quick one, with no extra rule. Sleep lives on `EvidenceSnapshot`, not `DailyContext`, so wiring it now would need a Health-shaped parameter no caller can fill yet. |
| D46 | Craving strictly outranks convenience in `DishSelection`'s ranking tuple — `(craving, convenience, recency, favourite, rotation)`, in that order. | The brief only says "craving and convenience" together, without ordering them against each other; the two existing tests each held the *other* factor tied by construction, so neither pinned this specific precedence. Craving is what the user explicitly asked for tonight; convenience is a standing preference inferred from context. Pinned by `convenienceNeverBeatsCraving` — flagged by `arc-constitution-review` as an ambiguous-rule resolution that should carry its own decision, like every other tie-break choice in this ranking. |
| D47 | "Share a cutoff" in `CalorieProvenance.compare(_:)` means identical `DateInterval`s across active, resting and intake — not merely a matching end instant. | Kcal sums are duration-dependent, so aligning only the cutoff instant while allowing different window starts would let two differently-sized periods be subtracted as if comparable. `HealthEvidenceReader` already produces one identical shared window for all three energy kinds today, so the stricter check costs nothing now. |
| D48 | `intakeConfirmedComplete: Bool` is a parameter on `CalorieComparisonRequest`, not a persisted field. | Same reasoning as D39: no store exists yet to read it from, and the rule about what counts as "confirmed" belongs with the rule, not with a store that has no conformer. |
| D49 | Manual intake is modelled as `RecordedIntake.manual(kilocalories:window:)`, a case of an enum sibling to `.recordedFromHealth(EnergyAggregate)` — never a second optional field alongside a Health total. | Makes "replaces, never adds" a type-level guarantee: a caller cannot physically supply both a Health total and a manual total to be summed, rather than a runtime precedence rule a call site could get wrong. |
| D50 | `CalorieReferenceCatalogue` encodes the plan's three verified Spain McDonald's items (Big Mac 544 kcal, hamburger 258 kcal, cheeseburger 306 kcal) as `Domain/Catalogue/` `static let`s, mirroring D36's catalogue-as-constant shape. Zero of the 27 `DishCatalogue+Dishes.swift` variants are wired to `calorieReferenceID` — enforced by a regression test. | These are specific fast-food menu items in one market; none of the catalogue's home-style burger/pizza/etc. variants are the same product, and the brief explicitly forbids applying a reference to a different product. The dataset stands alone until a future flow lets a user attach one to a specific meal. |
| D51 | `VerdictRevision.decisionData`/`evidenceData` persist `VerdictDecision`/`EvidenceSnapshot` JSON-encoded whole, not decomposed into flat columns. `PersistedDishOutcome`/`AppealChoice`, by contrast, are flattened to columns. | `CategoryBasis`'s associated values don't map to flat SwiftData columns without a second entity hierarchy, which the constitution forbids; a blob also guarantees byte-exact reproducibility for "reopen without regenerating." `PersistedDishOutcome`/`AppealChoice` are small, stable, app-owned enum shapes, unlike `CategoryBasis`'s open-ended associated data. |
| D52 | `AppealChoice` is a concrete two-case enum now: `.catalogue(variantID:family:)` or `.freeText(String)`. | Grounded directly in `foodge-plan.md` section 3's own two named appeal outcomes. Appeal *negotiation* (matching a compatible craving, honest no-match) stays WU-22-A's job — this only gives an appeal a place to be recorded. |
| D53 | `CaseStore` methods take no separate `day`/`calendar` parameter; `PersistenceActor`'s private `localDayKey(for:)` derives `"yyyy-MM-dd"` from the caller's own `EvidenceSnapshot` (`evaluatedAt` + `timeZoneIdentifier`, Gregorian) — the only source of "what day is this." | A second `day` parameter would be a second source of truth that could disagree with the one already inside the evidence it was computed from. Zero-padded by hand rather than `String(format:)`/`DateFormatter` — both forbidden, and this key is internal storage that must never vary with device locale. |
| D54 | `VerdictRevision.narrationText` is added as a nullable column now, with no write path yet. | Zero-risk under D10 (unreleased app, so growing schema V1 is a dev reinstall) — same class of change as D32. `attachNarration` is WU-23-A's job. |

---

## Day 18 — foundation

### WU-18-A ✅ Repo hygiene and handoff documents

- **Objective / scope**: persist the plan, design specification and this ledger. Delete the in-repo
  copy of internal studio material. No Xcode project work.
- **Inputs / docs**: `docs/foodge-plan.md` §2 and §6.
- **Acceptance**: `git status` shows only `CLAUDE.md`, `DESIGN.md`, `docs/`, `.gitignore`.
  No internal studio material anywhere in the repo. `CLAUDE.md` ≤ 80 lines.
- **Tests / verifier**: `git status`, manual read-through.
- **Evidence**: 2026-09-18. The in-repo copy of internal studio material verified byte-identical to its original
  (`diff -rq`, no differences) before deletion; the original remains outside the repository.
  `foodge-plan.md` moved to `docs/`. `.DS_Store` removed and ignored.
  `git status` lists exactly `.gitignore`, `CLAUDE.md`, `DESIGN.md`, `docs/`
  (`.claude/settings.local.json` is covered by the user's global ignore).
  `CLAUDE.md` is 77 lines.
- **Next**: WU-18-B.
- **Commit**: `chore(repo): persist plan, design spec and task ledger`

### WU-18-B ✅ Project creation with strict Swift 6 settings

- **Objective / scope**: create the Xcode project and its three targets through the Xcode MCP only.
  No domain code.
- **Inputs / docs**: `arc-mcp-xcode`, plan §1 and §4.
- **Steps**:
  1. `XcodeNewProject` → `Foodge/Foodge.xcodeproj` (`com.apple.dt.unit.multiPlatform.app`,
     `storageType: None`, `testingSystem: Swift Testing`, `hostInCloudKit: false`,
     org `com.arclabs`, team `4W652PD582`). Then `XcodeOpenWorkspace`.
  2. `XcodeListTargets`; add a `UITestingBundle` target if the template did not create one.
  3. `UpdateTargetBuildSetting` on all targets: `IPHONEOS_DEPLOYMENT_TARGET=26.0`,
     `SUPPORTED_PLATFORMS="iphoneos iphonesimulator"`, `SUPPORTS_MACCATALYST=NO`,
     `TARGETED_DEVICE_FAMILY=1`, `SWIFT_STRICT_CONCURRENCY=complete`,
     `SWIFT_APPROACHABLE_CONCURRENCY=YES`, `SWIFT_DEFAULT_ACTOR_ISOLATION=nonisolated`,
     `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY=YES`, `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`,
     `CODE_SIGN_STYLE=Automatic`; `STRING_CATALOG_GENERATE_SYMBOLS=YES` on the app target.
     Confirm `SWIFT_VERSION` holds the language-mode value the template set — never `6.4`.
  4. `AddInfoPlist(NSHealthShareUsageDescription)` (read-only; no update-usage key).
     `AddEntitlement(com.apple.developer.healthkit, true)`.
  5. `LocalizationPlanner(es)` → `Resources/Localizable.xcstrings`.
     **Stop and ask** if the planner cannot create the catalogue — never hand-write `.xcstrings`.
  6. Replace the template `ContentView.swift` with `App/FoodgeApp.swift` + `App/AppRootView.swift`;
     create `App/ Domain/ Data/ Presentation/ Resources/` via `XcodeMakeDir` / `XcodeMV`.
- **Acceptance**: `BuildProject` succeeds for simulator and device; `GetBuildLog(severity: warning)`
  is empty; settings confirmed via `GetTargetBuildSettings`.
- **Tests / verifier**: Xcode MCP build + build log.
- **Evidence**: 2026-09-18/19. `XcodeNewProject` created all three targets (`Foodge`, `FoodgeTests`,
  `FoodgeUITests`) — the template supplied the UI-test bundle, so no `XcodeNewTarget` was needed.
  All ten build settings applied per target; `SUPPORTS_MACCATALYST` rejected as unknown (D19) and
  `SWIFT_VERSION` raised from the template's `5.0` to `6.0` (D18).
  Confirmed on `FoodgeTests` via `GetTargetBuildSettings`: `SWIFT_VERSION 6.0`,
  `SWIFT_STRICT_CONCURRENCY complete`, `SWIFT_DEFAULT_ACTOR_ISOLATION nonisolated`,
  `SWIFT_TREAT_WARNINGS_AS_ERRORS YES`, `SWIFT_APPROACHABLE_CONCURRENCY YES`,
  `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY YES`, `IPHONEOS_DEPLOYMENT_TARGET 26.0`,
  `TARGETED_DEVICE_FAMILY 1`, `SUPPORTED_PLATFORMS "iphoneos iphonesimulator"`.
  Confirmed for all three targets from the compiler command lines in the build log:
  `-swift-version 6` matches 7 tasks, `-swift-version 5` matches 0.
  The first device build failed with "No Accounts" and a provisioning profile lacking HealthKit;
  after the user signed in to Xcode it succeeded. Final state: device (`iPhone de CR`) and
  simulator (`iPhone 17 Pro (27.0)`) builds both succeed with `buildForTesting`, and
  `GetBuildLog(severity: warning)` returns 0 entries.
  `LocalizationPlanner(es)` created `Resources/Localizable.xcstrings` and
  `Resources/Foodge-InfoPlist.xcstrings` (D20). Corrected after review: `Localizable.xcstrings`
  is committed **empty** — no view strings have been extracted yet. Only the Info.plist catalogue
  has entries (`CFBundleName`, `NSHealthShareUsageDescription`), English only. Template `ContentView.swift` removed; `FoodgeApp.swift` and `Assets.xcassets`
  relocated into `App/` and `Resources/`.
- **Next**: WU-18-C.
- **Commit**: `chore(project): create Foodge Xcode project with strict Swift 6 settings`

### WU-18-C ✅ Domain skeleton, sample data and first failing tests

- **Objective / scope**: value types, domain protocols, use-case stubs, synthetic scenarios and the
  first three test suites — deliberately red. No Health, no persistence, no UI beyond the root.
- **Inputs / docs**: plan §3 and §4; skills `swift-testing-doctrine`, `swift-concurrency-strict`.
  `arc-test-engineer` writes the suites before the stubs are filled.
- **Deliverables**:
  - `Domain/Entities/`: `DinnerCategory`, `EvidenceSnapshot`, `HealthAggregates`
    (`EnergyAggregate`, `StepAggregate`, `SleepAggregate`, `WorkoutSummary`, `Provenance`),
    `EvidenceAvailability` (+ `HealthKind`), `DailyContext` (+ `DinnerTime`, `EnergyLevel`,
    `SelfReportedActivity`, `Note` with failable init ≤ 240), `ActivityBaseline`
    (+ `DailyActivityObservation`, `ActivityMetric`, `BaselineUnavailableReason`),
    `VerdictDecision` (+ `CategoryBasis`, `ReasonCode`, `CategoryOutcome`), `Dish`
    (`DishFamily`, `DishVariant`, `DietProfile`, `Ingredient`, `ConvenienceTag`),
    `CalorieReference`, `DietaryConstraints`. Grouped per D27.
  - `Domain/Services/`: `HealthEvidenceProvider`, `VerdictEngine`, `VerdictNarrator`, `CaseStore`,
    `ReminderService`, `EvaluationClock` (+ `FixedClock`).
  - `Domain/UseCases/`: `ActivityBaselineCalculator`, `DinnerCategoryRule`, `SleepIntervalUnion` — stubs.
  - `Domain/Errors/FoodgeError.swift`.
  - `Data/SampleData/`: `SyntheticScenarios.swift` (+ `+Days`), `SampleData.swift`
    (`PreviewModifier`, in-memory container, `isSynthetic = true`).
  - Scenarios at `FixedClock` 2026-09-18 19:30 Europe/Madrid: `activeDay` (520 vs baseline 400),
    `typicalDay` (410/400), `restDay` (180/400, tracking confirmed), `noHealthData`,
    `partialTracking` (150/400, unrepresentative), `stepsFallback` (energy 3 observations;
    steps 14 observations, median 8200, today 9000), `shortSleep` (5 h 10 min),
    `dstSpringForward` (2026-03-29 03:10).
  - Tests: `FoodgeTests/Support/Tags.swift`, `Domain/UseCases/DinnerCategoryRuleTests.swift`,
    `ActivityBaselineCalculatorTests.swift`, `SleepIntervalUnionTests.swift` (inventory in the plan).
- **Acceptance**: build green with zero warnings; `RunSomeTests` shows the three suites compiling
  and **failing** — this red state is intentional and D13 blocks Day 19 from closing until green.
- **Tests / verifier**: `BuildProject`, `RunSomeTests`, `arc-test-engineer`.
- **Evidence**: 2026-09-19. Domain, scenarios and suites build with zero warnings on simulator
  and device. `RunSomeTests` over the three suites: **25 tests, 3 passed, 22 failed** — the
  intended red state.
  `arc-test-engineer` audited all five test files before implementation and returned
  *"suite clean — 0 tautological tests, all cases pass the Gate"*, having independently
  recomputed every median, both threshold boundaries and all three sleep unions, and having
  empirically confirmed that `Duration` and median equality are bit-exact (so a correct
  implementation will not fail on floating point). Note its warning that
  `Duration.seconds(27000).description` prints `27000.000000000004` — the failure text looks
  like a float bug when it is not.
  Two P1 findings fixed: the `invalidValuesAreDiscarded` title said "not positive" where the
  brief says **nonnegative**, which would have steered the filter to `> 0` and silently broken
  the zero-median branch; and no fixture fed sleep intervals out of order, so an implementation
  that merged without sorting would have passed everything and shipped broken.
  Also applied: `try result.get()` in place of `try #require(try? …)` so the five refusal paths
  report which reason fired; a positive assertion in `aMissingTodayIsNotTreatedAsZero`; reason
  codes asserted in the self-report cases; and three new tests —
  `recordedEvidenceBeatsASelfReport`, `aZeroEnergyMedianFallsBackToSteps` and
  `unsortedRecordsAreMerged`. Decisions D23–D25 record the rules those pin.
  The template `FoodgeTests.swift` was deleted: an empty example with no assertions, which the
  doctrine's Gate rejects.
  **For WU-19-A:** the 3 green tests are green only because the stubs return plausible values —
  `DinnerCategoryRule`'s stub hardcodes exactly the provisional-balanced answer two of them
  assert. Green here does not mean done.
- **Next**: WU-18-D.
- **Commits**: `feat(domain): add evidence, verdict and catalogue value types with synthetic scenarios`
  · `test(domain): add failing category rule, baseline and sleep union tests`

### WU-18-D ✅ Health and Foundation Models feasibility probe on the iPhone

- **Objective / scope**: prove on the physical device that Health authorization, a real read and
  on-device generation all work before any feature depends on them. Temporary UI (D14).
- **Inputs / docs**: plan §4; skills `foundation-models`, `apple-app-security`;
  HealthKit authorization and Swift-concurrency query documentation.
- **Deliverables**: `App/FeasibilityProbeView.swift` (`#if DEBUG`, root of `AppRootView` for Day 18
  only), `Data/Health/HealthAuthorizationService.swift` (kept), `Data/Narration/NarrationAvailability.swift` (kept).
- **Probe behaviour**: "Connect Health" → `requestAuthorization(toShare: [], read: <6 types>)` →
  read today's active energy → shows "readable" / "no readable data" (never "denied") ·
  availability case label · "Say hello" → `LanguageModelSession().respond(to:)` → shows the
  response **length** only.
- **Acceptance**: `DeviceInteractionStartWorkspaceSession` on the connected iPhone →
  `InstallAndRun` → screenshots of the Health sheet, the `.available` state and a received
  response. Paths recorded below; no Health values anywhere. Session ended.
- **Tests / verifier**: device log via `GetConsoleOutput`; `arc-constitution-review` before the
  day's last commit.
- **Evidence**: 2026-09-19, on the connected iPhone (`iPhone de CR`, iOS 27.0), via
  `RunProject` rather than a device-interaction session (D21).
  **First run crashed** on "Connect Health":
  `NSInvalidArgumentException — NSHealthShareUsageDescription must be set in the app's Info.plist
  in order to request read authorization for the following types: …`. Cause and fix in D26; the
  HealthKit entitlement was correct throughout (`com.apple.developer.healthkit => true` in the
  signed entitlements).
  After the fix, on device:
  `PROBE health=noReadableData` · `PROBE lastSevenDaysReadable=true` ·
  `PROBE availability=available` · `PROBE narration=answered(characterCount: 6)`.
  So: authorization completes, a real seven-day Health read returns data, an empty window is
  reported as absence (the run was at 00:43, when today genuinely held nothing) and never as a
  denial, and on-device generation produced a real response. No Health value and no model output
  reached the screen or the log — only the state labels above.
- **Next**: WU-19-A.
- **Commit**: `chore(debug): add temporary Health and Foundation Models feasibility probe`

---

### Day 18 close

`arc-constitution-review` audited commits `9d483a1..42af208` on 2026-09-19 and returned
**0 blockers**, verifying the zero-warning claim itself through the MCP rather than taking it on
trust: `GetBuildLog(severity: warning)` empty, all three targets present, `-swift-version 6` on
every compile task and `-swift-version 5` on none, and `SWIFT_DEFAULT_ACTOR_ISOLATION`,
`SWIFT_STRICT_CONCURRENCY` and `SWIFT_TREAT_WARNINGS_AS_ERRORS` confirmed on all six
configurations. It found no force unwrap, no sendability suppression, no secret, no logged Health
value, no framework leak into Domain, and explicit `@MainActor` on every UI-facing type.

Fourteen non-blocking findings; the substantive ones are fixed in the commit that closes Day 18. Three deferred, each
with a reason: the UI-test template smoke test stays until Day 26 (D2), the probe's unlocalized
display helpers die with the probe in WU-19-D (D14), and iOS 26 validation is still owed.

## Day 19 — evidence and onboarding

### WU-19-A ✅ Baseline calculator, category rule and sleep union

- **Objective / scope**: fill the three pure use-case stubs. Domain only — no Health, no UI.
- **Inputs / docs**: plan §3 (activity baseline, category decision table); `swift-testing-doctrine`.
- **Rules**:
  - `ActivityBaselineCalculator.baseline(from:trackingRepresentative:)` — not representative →
    `.markedUnrepresentative`; keep non-nil, finite, non-negative energy values; count ≥ 7 and
    median > 0 → `.activeEnergy`; otherwise the same test on steps → `.steps`; otherwise
    `.insufficientHistory(found:)` or `.zeroMedian`.
  - `DinnerCategoryRule.decide(today:baseline:trackingRepresentative:selfReport:)` — ratio > 1.25 →
    treat; 0.75…1.25 inclusive → balanced; < 0.75 confirmed → light; < 0.75 unconfirmed →
    `.needsTrackingConfirmation`; no usable ratio but a self-report → mapped category with basis
    `.selfReported`; nothing at all → balanced, `.provisional`, reason `.checkInSkipped`.
  - `SleepIntervalUnion.duration(of:)` — sort, merge overlaps, sum.
- **Acceptance**: every Day 18 test green; zero warnings.
- **Tests / verifier**: `RunSomeTests` on the three suites.
- **Evidence**: 2026-09-19. `RunSomeTests` over the three suites: **25 tests, 25 passed, 0 failed**
  (from 22 failing). `GetBuildLog(severity: warning)` empty.
  Three things the tests forced that a reading of the brief alone would not have:
  the sleep union sorts before merging and extends the open span only forwards, so a stage nested
  inside a longer record cannot shorten it; the calculator reports the **preferred** metric's
  failure when both metrics refuse, so the reason does not depend on evaluation order (D23); and
  the rule returns `nil` from its recorded branch when today's reading is missing, so an absent
  value can never fall through the "below 75%" door into a light verdict.
  `Duration` equality held exactly, as the test auditor predicted — the implementation computes
  from `DateInterval.duration`, a `Double`, and still compares equal to integer seconds.
- **Next**: WU-19-B.
- **Commit**: `feat(domain): implement activity baseline calculator, category rule and sleep union`

### WU-19-B ✅ Health reader

- **Objective / scope**: `Data/Health/` — `HealthSampleSource` (protocol), `HealthKitSampleSource`
  (actor), `HealthEvidenceReader: HealthEvidenceProvider`, `HealthReadTypes`,
  `EvidenceWindowPlanner` (pure). No UI.
- **Inputs / docs**: plan §3 evidence contract; `swift-concurrency-strict`; HealthKit statistics
  and Swift-concurrency query documentation.
- **Rules**: quantities via `HKStatisticsQueryDescriptor(.cumulativeSum)` with
  `predicateForSamples(withStart:end:options: [.strictStartDate])`; sleep via
  `HKSampleQueryDescriptor` filtered by `HKCategoryValueSleepAnalysis.allAsleepValues`, returning
  raw `DateInterval`s for the domain to union; workouts listed only, energy never re-added;
  dietary energy summed separately. `isHealthDataAvailable() == false` → `.healthUnavailable`
  with zero source calls. Absence is never denial. `withThrowingTaskGroup` across the 15 windows
  with `try Task.checkCancellation()`.
- **Acceptance**: `EvidenceWindowPlannerTests` and `HealthEvidenceReaderTests` green
  (fixtures per D11); zero warnings.
- **Tests / verifier**: `RunSomeTests`; `arc-audit-concurrency` clean.
- **Evidence**: 2026-09-19. **11 tests, 11 passed**; 39 across the whole unit suite, zero warnings.
  Both daylight-saving cases verify against real arithmetic rather than assertion: 29 March 2026
  gives a 3-hour window from midnight to 04:00 and 25 October gives a 5-hour one, so the
  same-clock-time cut is demonstrably calendar-aware and not seconds-based.
  `arc-audit-concurrency` returned **0 blockers**, confirming no `nonisolated(unsafe)`,
  `@unchecked Sendable`, `@preconcurrency`, GCD or continuation anywhere in the layer, and
  verifying the zero-warning build itself. Three of its findings are fixed here:
  today's reads and the fortnight were being awaited one after the other despite sharing nothing
  (now concurrent, so the cost is the slower rather than the sum); the actor's doc comment claimed
  it *serialised* queries, which is false for a reentrant actor and would have misled the next
  person who added state to it; and `compactMap` on the reassembled history could have silently
  returned a short fortnight that the baseline would treat as complete.
  The fourth mattered most for the tests: the fixture never suspended, so
  `historyReadingsStayAlignedWithTheirDays` would have passed against a serial loop. It now delays
  the earliest window longest, which forces results to arrive out of submission order and puts the
  index-keyed reassembly under real test.
  D30 records the one `Sendable` conformance deliberately kept.
- **Next**: WU-19-C.
- **Commit**: `feat(health): add HealthKit sample source and evidence reader with same-local-time windows`

### WU-19-C ✅ Schema V1 and persistence actor

- **Objective / scope**: `Data/Persistence/` — `FoodgeSchemaV1` (`VersionedSchema`,
  `[UserPreferences.self]`), `FoodgeMigrationPlan` (no stages yet), `Models/UserPreferences.swift`
  (`@Model`: diet profile, excluded ingredients, favourite families, dinner routine,
  `onboardingCompletedAt`, narration enabled, reminder time), `PersistenceActor` (`@ModelActor`,
  `savePreferences(_ draft: PreferencesDraft)`), `ContainerFactory` (`makeLive()` in Application
  Support, backup-excluded, complete file protection; `makeInMemory()`), `PreferencesDraft`
  (Sendable transport). Live model objects never cross an actor boundary.
- **Inputs / docs**: plan §4; skills `swiftdata-architecture`, `apple-app-security`.
- **Acceptance**: `ContainerFactoryTests.preferencesSurviveContainerReopen` green; zero warnings.
- **Tests / verifier**: `RunSomeTests`; `arc-audit-concurrency` clean.
- **Evidence**: 2026-09-19. `ContainerFactoryTests`: **3 tests, 3 passed**. The reopen test writes
  through `PersistenceActor` into a real on-disk store, opens a **separate** container on the same
  file and reads every field back. Two more pin things the plan did not list but that would have
  bitten later: a second save updates the single record rather than adding a duplicate the app
  would then read at random, and an in-memory container keeps nothing — which is what stops a
  demonstration scenario ever reaching someone's real history.
  `PreferencesDraft` is the only thing crossing the actor boundary; no live `@Model` object leaves
  the context that owns it. Enum values persist as raw strings so renaming a Swift case cannot
  silently change stored data, and an unrecognised stored diet falls back to omnivore rather than
  narrowing what the user is offered.
  D29 records the file-protection level chosen.
- **Next**: WU-19-D.
- **Commit**: `feat(persistence): add schema V1 with user preferences and persistence actor`

### WU-19-D ✅ Progressive onboarding

- **Objective / scope**: `Presentation/Features/Onboarding/` — `OnboardingFlowView`
  (`NavigationStack(path:)` over `OnboardingRoute`), `WelcomeView`, `HealthConnectionView`,
  `RecordedPatternSection`, `PreferencesView`, `IngredientExclusionsView`,
  `Components/JudgeBadgeView`, and `OnboardingViewModel` (`@MainActor @Observable final class`;
  dependencies `HealthAuthorizationService`, `any HealthEvidenceProvider`, `PersistenceActor`,
  `EvaluationClock`; state `healthState { idle, requesting, connected(summary), unavailable,
  noReadableData }` plus `draft`; actions `connectHealth()`, `skipHealth()`,
  `markUnrepresentative(_:)`, `finish()`). `AppRootView` reads preferences with `@Query` and shows
  onboarding or a `MainTabView` placeholder (Today / History, `ContentUnavailableView`).
  English literals localized to `es` through `LocalizationPlanner` / `StringCatalogEdit`.
  **Delete `FeasibilityProbeView` and its root wiring** (D14).
- **Inputs / docs**: `DESIGN.md`; skills `swiftui-doctrine`, `ios-accessibility-wcag`.
- **Acceptance**: `RenderPreview` for each view across {light, dark, `es`, AX5}; a device session
  completes Welcome → Health → Preferences and a relaunch skips onboarding; no probe code remains
  anywhere in the repository.
- **Tests / verifier**: `OnboardingViewModelTests` green; `arc-verify-ui` iterated until ✅;
  `arc-audit-hig` and `arc-audit-accessibility` with no blockers; `arc-constitution-review`
  before the day's last commit.
- **Evidence**:
  - Baseline before starting: build 0 errors / 0 warnings (`GetBuildLog severity: "warning"`, the
    second call), 41/41 tests.
  - **Tests written first and proven red**: the suite ran against empty method bodies and
    **15/15 cases failed**, then passed once implemented. Final: **61/61** (59 `FoodgeTests`
    + 2 `FoodgeUITests`), of which `OnboardingViewModelTests` contributes **19 test functions /
    20 cases**. Build 0 errors, 0 warnings at `severity: "warning"`.
  - Scope changed by the ledger's own count: 4 screens, not 5 (D31), and 20 onboarding cases,
    not the 13 planned — `arc-test-engineer` found the `evidenceFailure` seam existed with no
    test using it, leaving the D35 rule (a failed read is not an absence) unproven. It also
    exposed a real defect: a cancelled read left `.requesting` on screen permanently. Both fixed,
    plus tests for `toggleFavourite` removal, a nil-snapshot mark, and disjoint energy/step days
    (the last one is what actually pins D23's rationale).
  - `arc-constitution-review` returned **2 blockers, both real**: `OnboardingViewModel` had a
    `convenience init(dependencies: AppDependencies)` — production Presentation naming an App
    type, flatly contradicting D34's own wording — and **all 16 `View` structs were missing the
    explicit `@MainActor`** the project requires under `nonisolated` default isolation
    (`AppRootView` had regressed: the Day 18 version carried it). Both fixed; assembly moved to
    `AppDependencies.makeOnboardingViewModel()`.
  - Previews rendered and read, not just invoked: `WelcomeView`, `HealthConnectionView`
    (connected), `PreferencesView`, `RecordedPatternSection`, at `en`, at `es`, and at AX 5.
    AX 5 confirmed `LabeledContent` stacks label-over-value rather than truncating — the comment
    claiming that is now evidence, not assertion.
  - Localization: 67 keys + 2 Info.plist keys through `LocalizationPlanner` / `StringCatalogEdit`;
    9 more after the apostrophes were corrected to `’`. Verified in the **built**
    `Foodge.app/es.lproj/Localizable.strings` and `InfoPlist.strings` (D26), not from the tool's
    return value.
  - Simulator session completed Welcome → Health (Apple's sheet, all six types granted) →
    Preferences → Save, reached the Today/History tabs, and **a force-quit relaunch went straight
    to the tabs** — onboarding skipped, which is the half only a relaunch can prove. Console via
    `GetConsoleOutput`: `ONBOARDING launch completed=false` → `state=requesting` →
    `state=noReadableData`, then `launch completed=true` on the next launch. No Health value
    appears in any line.
  - The simulator pass found two defects a preview could not: the dish rows were **completely
    unresponsive to taps**, and all nine exposed a false "Selected" accessibility element.
    `LabeledContent` inside a `Button` forms its own accessibility container. Rebuilt as an
    `HStack` label with `.contentShape(.rect)` — which fixed the taps but **not** the phantom
    element: a trailing checkmark in a `Form` row becomes the row's native accessory, and an
    accessory ignores `.accessibilityHidden(true)`, so `.opacity(0)` left all nine announcing
    themselves as selected. Only building the glyph when selected fixed it. Re-verified on a
    clean install: nine bare `Button` leaves, the `Selected` trait on the button alone, and
    **row geometry byte-identical across all four states** — the layout-shift the opacity trick
    was protecting against does not occur, because the glyph sits in a fixed-height row's
    trailing space.
  - `arc-audit-hig`: **0 blockers**, two extractions taken — `DishFamily` filtering moved to
    `DinnerCategory.families` (domain knowledge had been duplicated in a View) and the dinner
    routine's footer to `DinnerTime?.footerDescription`.
  - `arc-audit-accessibility`: **3 blockers, all real, all fixed**. (1) `.borderedProminent`'s
    default white label on `AppBurgundy` measured **2.47:1** in dark appearance and **1.74:1**
    at high contrast — `AppBurgundy` is tuned as a *foreground* colour and inverts lightness
    between appearances, so it cannot also serve as a button background with a fixed label.
    Fixed with a paired `AppOnBurgundy` colour set rather than the auditor's `colorScheme`
    branch, so the pairing lives in the catalogue like every other colour decision.
    (2) At AX 5 the pinned `safeAreaInset` Continue button overlapped the text above it; it now
    flows as the last scrolling item at accessibility sizes only. (3) `StoreUnavailableView` is
    the app's root with nothing around it to scroll, so at AX 5 in Spanish its only action —
    the sole way out of a fatal error — went off-screen unreachable; wrapped in a `ScrollView`
    with `containerRelativeFrame(.vertical)` (not a `GeometryReader`).
  - Also replaced `.foregroundStyle(.secondary)` at five call sites: `secondaryLabel` measures
    ~3.4:1 on white in standard contrast, under the 4.5:1 floor. **Note this changes the visual
    register** — secondary text is now brand-tinted rather than grey, which is a deviation from
    DESIGN.md's "semantic text colours throughout" worth reviewing on Day 24.
  - Two claims in the accessibility report did not survive checking: it cited a "pre-existing
    SwiftLint `--strict` gate" (this project has no SwiftLint — the wraps were harmless, and the
    `\` line continuations preserved every string literal exactly, confirmed by the catalogue
    reporting **0 new keys**), and it confirmed the `Measurement` formatting by API inspection
    rather than by hearing VoiceOver, which it said plainly.
  - **Physical device ("iPhone de CR", iOS 27), the run that closes the unit.** The console is
    the whole instrument here (D21), so `AppLaunch` gained a `store=unavailable` marker first —
    without it a store that refuses to open is indistinguishable from an app that logged nothing.
    It was not needed: the store opened, so **growing V1 did not reject the existing store on
    the phone**. Whether that is because the device held no prior store or because SwiftData
    took the new property from its default is not determinable from here, and is not claimed.
    Sequence, PID 16175:
    `launch completed=false` → `state=requesting` → `state=connected` → `state=requesting` →
    `state=connected` → `save=completed`. **`.connected` ran against a real recorded fortnight
    for the first time anywhere** — every simulator run had ended in `noReadableData` because
    there was nothing to read. **No Health value appears in any line**, only state labels.
  - Relaunch proved on a **separate process** (PID 16178): `launch completed=true`. That is the
    persistent half — `@Query` reading the record back from disk — not the within-session
    `didFinish` latch, which a same-process transition could not have distinguished.
- **Next**: Day 20 backlog.
- **Commits**: `feat(onboarding): add progressive Welcome, Health connection and Preferences flow`
  · `chore(debug): remove feasibility probe`

---

## Day 20 — dish catalogue, deterministic selection and calorie provenance (WU-20-A / WU-20-B / WU-20-C)

- **Objective**: a curated 27-variant, 44-ingredient catalogue (D36–D38, D44) and a deterministic
  selector over it (D39–D43, D45), unblocking `IngredientExclusionsView` (deferred by D31); plus
  calorie provenance keeping active/resting/dietary energy separate with a verified-reference
  dish display (D47–D50).
- **Baseline**: 61/61 tests, 0 warnings, confirmed before starting.
- **Phase 0 — tooling gate**. Proved with one real key ("Cooked lentils" → "Lentejas cocidas"):
  (a) `StringCatalogEdit` **cannot** create a key that was never extracted from a source literal
  — it fails outright ("String key ... not found"). (b) A key whose source literal is later
  deleted **does** survive, translated, in the built `es.lproj` — confirmed by reading
  `Foodge.app/es.lproj/Localizable.strings` directly after removing the literal and rebuilding.
  Resolved as **seed-and-delete**: a temporary file lists every new English name as a
  `LocalizedStringResource` literal, purely so the build's extractor adds the key; translate;
  delete the file. Keeps D37's dynamic lookup intact, at the cost of repeating the seed step for
  any future catalogue addition — the localization coverage test (below) is what catches a
  forgotten one.
- **Phase 1 — catalogue data**: `DishCatalogue`, `DishCatalogue+Dishes` (9 `Dish` constants),
  `Ingredient+Catalogue` (44 statics). `DishCatalogueTests` — 11 tests, including an independent
  animal-product oracle (hand-lists meat/fish/egg-dairy separately from the catalogue's own
  `diets` field) and the vegan-per-category guarantee (treat 3, balanced 2, light 6). `CLAUDE.md`
  Layout block updated the same commit. **11/11 green, 0 warnings.**
- **Phase 2 — localization**: `Ingredient+DisplayName`, `DishVariant+DisplayName`.
  `CatalogueNameLocalizationTests` — 3 tests against the **built** `es.lproj`. 69 new keys
  seeded and translated (71 names − 2 that already existed: "Cooked lentils" from the Phase 0
  probe, "Pasta" already a key from the family name), plus 2 screen keys ("Exclude ingredients",
  "Ingredients to exclude"). **14/14 green, 0 warnings.**
  - **Real defect caught and fixed here, not by an auditor**: `localizedName(in:)` first used
    `String(localized: String.LocalizationValue(stringLiteral:), locale:)`. It returned the
    **English** source string for every key, for every ingredient and variant, when called from
    the hosted test target — deterministic, not a race (confirmed by rerunning the identical
    failing test twice, same 37 keys both times) — even though the built `es.lproj` file on disk
    was correct throughout (confirmed with `plutil`). `String(localized:locale:)`'s bundle
    resolution does not follow the same `TEST_HOST` chain as `Bundle.main.url(forResource:)`
    inside a hosted unit test. Fixed by resolving directly against `Bundle(url:)` for the
    requested locale's `.lproj`, falling back to `nameKey` when none exists (the English case,
    since there is no `en.lproj`). Isolated with `RunCodeSnippet` before touching the fix.
- **Phase 3 — exclusions screen**: `IngredientExclusionsView` (searchable, `SelectableRow`
  reused unchanged in code — see the accessibility finding below), `OnboardingViewModel` gained
  `toggleExclusion(_:)` and `excludableIngredients(matching:locale:)`, `OnboardingRoute`/
  `OnboardingFlowView` wired, `PreferencesView` gained the row. `OnboardingViewModelTests` gained
  4 tests plus one existing test (`finishingWritesTheCompletedDraftExactlyOnce`) updated to
  exercise a real exclusion instead of asserting it stays empty. `memory/decisions/exclusions-
  screen-waits-for-the-catalogue.md` gained a "Resolved in WU-20-A" note. Previews rendered and
  read at light, dark, `en`, `es` (device default) and AX 5 — alphabetical sort correct in both
  languages, no truncation at AX 5. **24/24 green, 0 warnings.**
  - `arc-verify-ui` drove the real flow on simulator (`iPhone 17 Pro`, iOS 27.0): Welcome → skip
    Health → Preferences → search "mushroom" → select → back (count persisted: 0 → 1) → Save →
    landed on the main tabs. **Pass.**
  - **`arc-audit-hig` found a real BLOCKER**, and it was in this ledger, not just the code: the
    row was first written as a hand-built `HStack` (label + trailing count), justified here as
    "per the D-device lesson" — but that lesson (WU-19-D, `LabeledContent` breaking tap response
    *inside a custom `Button`*) does not generalize to a `NavigationLink`, where `LabeledContent`
    is Apple's own documented pattern for exactly this label-plus-trailing-value case, and is
    already this project's own working pattern one file over (`RecordedPatternSection`). Fixed:
    the row is now `LabeledContent("Ingredients to exclude", value: …, format: .number)` inside
    the `NavigationLink`. Preview re-rendered, visually unchanged from the `HStack` version.
  - `arc-verify-ui`'s VoiceOver pass found a **real, reproducible defect**, not new to this
    screen: `SelectableRow`'s selected-state checkmark broke a row into **three** accessibility
    elements (`Button …Selected` + a duplicate `StaticText` + an `Image label:'Selected'`)
    instead of one, reproducing identically on the pre-existing `FavouriteFamiliesSection` rows —
    a shared-component regression the file's own comment claimed was already fixed and "verified
    on device, twice". Took **five attempts** to actually close, four of them disproved on
    device before the fifth held:
    (1) `.accessibilityHidden(true)` on the checkmark alone — did not suppress it.
    (2) `.accessibilityElement(children: .ignore)` + `.accessibilityLabel` on the label `HStack`
    *inside* the `Button`'s closure — not absorbed into the `Button`'s own element; unchanged.
    (3) The same modifiers moved onto the `Button` itself, after `.buttonStyle(.plain)` —
    unchanged again.
    (4) `.accessibilityElement(children: .combine)` (Apple's own first-recommended behavior)
    plus `.accessibilityHidden(true)` on the leaf `Image` directly — **the decisive diagnostic**:
    hiding the leaf itself still didn't work, ruling out modifier placement entirely and pointing
    at iOS recognizing an SF Symbol literally named `"checkmark"` inside a `Form`/`List` row as a
    system-level selection accessory, reinjected regardless of the declared view hierarchy.
    (5) Replaced `Image(systemName: "checkmark")` with a hand-drawn `Shape` (`CheckmarkMark`,
    a stroked `Path`) carrying no SF Symbol identity — a fifth on-device pass confirmed the
    hierarchy no longer contains any element labelled "Selected" other than the row's own trait,
    on both `FavouriteFamiliesSection` and `IngredientExclusionsView`, with the glyph still
    visually present (screenshot-confirmed, not a visual regression). **Caveat, stated plainly
    rather than rounded up**: the device-interaction tooling used here has no VoiceOver-navigation
    command, so this is a structural hierarchy-dump confirmation, not a literal recorded VoiceOver
    swipe-through — the same evidence standard the four failures were caught with, applied
    consistently to the pass. Each intermediate attempt's "verified on device" language was
    corrected to not overclaim once the next pass disproved it.
- **Phase 4 — selection**: `DishSelection.select(from:category:constraints:context:
  favouriteFamilies:recentSelections:on:calendar:)`, `RecentDishSelection`,
  `DishSelectionOutcome`. `VerdictEngine`'s doc comment corrected (D44). `DishSelectionTests` — 23
  tests against a hand-written five-entry miniature catalogue (filters, all 5 ranking criteria
  individually isolated, the "never beats" comparator-priority pins, all 3 alternative branches,
  a shuffle-safety test) plus 6 rotation tests and a real-catalogue "no diet alone ever produces
  no-match" sweep across all 3 categories × 4 diets. One test bug caught in review before commit
  (a diet-filter test had over-excluded down to zero candidates, producing a false `.noMatch`
  the test itself didn't expect — fixed by relying on the diet filter alone). **23/23 green,
  0 warnings**, one iteration.
- **Full regression**: 61 → **102 tests**, 0 warnings, confirmed with `RunAllTests` after every
  phase and again after both fixes above. Re-confirmed once more after a machine reboot mid-
  session (see below) and once more after the accessibility audit's own edit: **102/102, 0
  warnings**, each time.
- **Environment note**: this session hit genuine OS-level process exhaustion (`unable to spawn
  process 'clang-stat-cache' (Resource temporarily unavailable)`, and even a plain shell `echo`
  failed) after a very long idle period with a stalled background test run. A reboot cleared it;
  not a code or tooling defect, but worth recording since it cost real session time. Also: after
  reboot, the active run destination had reset to the generic **"Any iOS Device (arm64)"** build
  destination, which builds but silently returns "No result" for every test — `RunAllTests`
  reported `99 tests: 0 passed, 0 failed, 99 not run` with no error. Fixed by explicitly switching
  back to `iPhone 17 Pro (27.0)` before re-running. Worth checking the active destination first
  the next time a fresh session's test run comes back suspiciously all-"No result".
- `arc-audit-hig`: **1 blocker, real** — the new `PreferencesView` row was first written as a
  hand-built `HStack`, justified in this very ledger as "per the D-device lesson." The auditor
  traced that lesson to WU-19-D's actual incident (`LabeledContent` breaking tap response *inside
  a custom `Button`*) and showed it doesn't generalize to a `NavigationLink`, where `LabeledContent`
  is Apple's own documented pattern for a label-plus-trailing-value row — and is already this
  project's own working pattern one file over (`RecordedPatternSection`). Fixed: see the Phase 3
  entry above.
- `arc-audit-accessibility`: **0 blockers.** Verified AX5/X-Small/dark on the 44-row list (no
  truncation, no horizontal scroll), confirmed the `LabeledContent` row reflows correctly at AX5
  (unchanged from before the HIG fix), computed contrast on the hand-drawn checkmark shape
  (~10:1 light, ~8.5:1 dark — both clear 1.4.11's 3:1 floor for a meaningful shape), confirmed hit
  targets and reduce-motion (no `.animation`/`.transition` anywhere in these files). Reached and
  verified the previously-untested `ContentUnavailableView.search` empty state by adding a
  source-compatible `init(vm:initialSearchText:)` (default `""`, no existing call site affected)
  and a `"No matches"` preview — Apple's own component, confirmed correct, no code fix needed
  there. Caught and flagged (not a code defect): `RenderPreview`'s `previewCanvasControlOverrides`
  parameter does **not** control Dynamic Type/Color Scheme — that's `previewVariantOverrides`; an
  initial pass using the wrong one silently rendered identical screenshots regardless of the
  requested size, caught by comparing "AX 5" and "X Small" output byte-for-byte before correcting.
  Confirmed no comment or ledger entry here repeats the earlier "verified on device, twice"
  overclaim pattern.
- `arc-constitution-review`: **0 blockers, 1 MAJOR (fixed), 2 MINOR (both fixed).**
  - **MAJOR**: `DishSelectionOutcome.noMatch(blockingIngredientIDs:)` was over-inclusive and its
    doc comment overclaimed what it guaranteed — the auditor found a case (a candidate blocked by
    *two* excluded ingredients at once) where a named id would **not** actually unblock anything
    if removed alone, contradicting the comment's per-id claim. `exclusionNeverRelaxes` couldn't
    catch it — every candidate there shares one blocking ingredient. Fixed: `blockingIngredientIDs`
    now names only ids **individually** sufficient to unblock a candidate (`soleBlockers`), with
    the doc comment corrected to say so explicitly. Pinned by the auditor's own counterexample,
    `blockingIDsExcludeJointlyNeededIngredients`.
  - **MINOR (SwiftLint, caught fixing the above)**: `select` had grown to 8 parameters and
    `rankKey` returned a bare 5-tuple — both against this project's lint gate. Fixed by
    introducing `DishSelectionRequest` (bundles everything about the user's own state) and a
    named, `Comparable` `RankKey` struct in place of the tuple; both are call-site-only changes,
    no ranking behavior moved.
  - **MINOR**: the checkmark shape's size wasn't `@ScaledMetric`. Fixed (`@ScaledMetric(relativeTo:
    .body)` for both the frame size and the stroke width).
  - **MINOR**: craving outranking convenience in the ranking tuple had no decision number or test
    proving the precedence when the two conflict (the existing tests each held one factor tied by
    construction). Recorded as D46; pinned by `convenienceNeverBeatsCraving`.
  - Everything else the auditor checked came back clean: no non-negotiable violations, correct
    architecture/dependency direction, `@MainActor` throughout, Swift Testing conventions
    followed, D27's one-concept-per-file carve-out correctly applied to `CatalogueEntry`/
    `RecentDishSelection`/`DishSelectionOutcome`, and — checked independently, not assumed —
    `TEST_HOST`/`BUNDLE_LOADER` really are set on the `FoodgeTests` target in `project.pbxproj`,
    so the `Bundle.main`-resolves-to-`Foodge.app`-under-test claim this whole localization gate
    depends on is genuine.
  - Full regression after all four fixes: **104/104, 0 warnings** (the two new tests —
    `blockingIDsExcludeJointlyNeededIngredients` and `convenienceNeverBeatsCraving` — take the
    count from 102 to 104).
- **Commits**: `feat(catalogue): add the nine-family dish catalogue and ingredient exclusions`
  (Phases 0–3), `feat(domain): add deterministic dish selection with a date-rotated tie-break`
  (Phase 4).

### WU-20-C ✅ Calorie provenance

- **Objective / scope**: keep active, resting and dietary energy as three separate recorded
  facts; a numerical comparison only when their windows share a cutoff and intake is confirmed
  complete; manual intake replaces the Health total rather than adding to it; a dish shows
  calories only against a verified portion reference (D47–D50). Domain-only, matching the WU-19-A/
  WU-20-B pattern — no ViewModel or View; the Today-flow UI that will consume this is WU-21-B.
- **Baseline**: 104/104 tests, 0 warnings, confirmed before starting.
- **Deliverables**: `Domain/UseCases/CalorieProvenance.swift` (`RecordedIntake`,
  `CalorieComparisonRequest`, `CalorieComparison`, `CalorieComparisonUnavailableReason`,
  `CalorieComparisonOutcome`, `DishCalorieOutcome`, `CalorieProvenance.compare(_:)` and
  `.calories(for:references:)`); `Domain/Catalogue/CalorieReferenceCatalogue.swift` (the plan's
  three verified Spain McDonald's items, mirroring D36's catalogue-as-constant shape).
  `CalorieProvenanceTests` (12 tests: all 6 required scenarios from `docs/foodge-plan.md:348` —
  missing resting energy, unconfirmed intake, manual replacement, negative differences, unknown
  portions, verified references — plus symmetric/defensive coverage: missing active energy,
  mismatched cutoffs, Health-intake-used-when-no-manual, the exact net arithmetic, and a dangling
  reference id) and `CalorieReferenceCatalogueTests` (2 tests: the three references' country,
  product, portion, URL, kilocalorie figure and verification date re-typed by hand from the brief;
  and that zero catalogue variants claim one of these ids). **14/14 green, one iteration.**
- **Full regression**: 104 → **118/118 tests, 0 warnings**.
- **User decisions taken up front**: wire zero catalogue variants to the three references (none of
  the 27 existing variants are the same product — wiring any would violate the brief's "do not
  apply them to other burgers"), and keep the defensive/symmetric tests beyond the six named
  scenarios.
- `arc-constitution-review`: **0 blockers, 3 MINOR, all fixed.** (1) `CalorieComparisonRequest`'s
  doc comment cited "the constitution's parameter-count ceiling" — no such rule exists in either
  `CLAUDE.md`; corrected to not cite a rule that isn't there, the exact "claims more than the code
  does" pattern this project's audits watch for. (2) `CalorieReferenceCatalogueTests` asserted
  region and kilocalories but not `productName`, `portionDescription` or `source` — a typo in a
  URL or portion string would have compiled and passed; all three now asserted for every
  reference. (3) Noted but not required to fix: `DishCalorieOutcome`/`calories(for:references:)`
  is a looser fit for D27's one-concept-per-file carve-out than the rest of the file, since it
  shares no name-relationship with `CalorieComparison*` — acceptable for now (precedent:
  `DishSelection.swift` is similarly loose), split out if the file grows further. Everything else
  checked clean: no force-unwraps, correct `Sendable`/value-type shape, no throwing path (D43
  precedent correctly followed), and `RecordedIntake`'s enum design confirmed to make
  "manual replaces Health, never adds" a structural guarantee rather than a caller convention.
- **Commit**: `feat(domain): add calorie provenance with separated energy facts and verified portion references`

---

## Day 21 — case persistence (WU-21-A)

### WU-21-A ✅ Schema V1 grows `DailyCase`/`VerdictRevision`/`Appeal`; `CaseStore` implementation

- **Objective / scope**: grow schema V1 (D10) with `DailyCase`, `VerdictRevision` and `Appeal`,
  and give `CaseStore` its first real implementation — the saved-case lifecycle from
  `foodge-plan.md` section 3: one case per local day, reopening returns the saved verdict without
  regenerating, an explicit "update evidence" appends an immutable new revision, and an appeal
  attaches to one specific revision. Domain + Data only — no View/ViewModel (WU-21-B), no appeal
  negotiation logic (WU-22-A), no `AppDependencies` wiring (deferred to the first real consumer).
- **Baseline**: 118/118 tests, 0 warnings, confirmed before starting.
- **Deliverables**: `Domain/Entities/PersistedDishOutcome.swift`, `Domain/Entities/CaseRecord.swift`
  (`AppealChoice`, `AppealDraft`, `SavedAppeal`, `NewRevisionDraft`, `SavedRevision`, `SavedCase`),
  `Domain/Services/CaseStore.swift` (rewritten: `savedCase(matching:)`, `recordRevision(_:)`,
  `recordAppeal(_:to:)`), two new `FoodgeError` cases (`revisionNotFound`, `caseCorrupted`);
  `Data/Persistence/Models/{DailyCase,VerdictRevision,Appeal}.swift` (D51); `FoodgeSchemaV1.models`
  grows to `[UserPreferences, DailyCase, VerdictRevision, Appeal]`, `versionIdentifier` unchanged,
  `FoodgeMigrationPlan.stages` stays `[]`; `extension PersistenceActor: CaseStore` (D53).
  `CaseStoreTests` (8 tests: reopen-without-regenerating, an unrecorded day returns `nil`, a second
  explicit save preserves the first revision, two local days never collide, an appeal attaches to
  one specific revision, an unknown revision id throws `revisionNotFound` honestly, a real on-disk
  container reopen, and a genuine save failure reported as `FoodgeError.saveFailed`).
- **Full regression**: 118 → **126/126 tests, 0 warnings**.
- **Plan assumption disproven mid-unit**: the original test plan for "a failed save is reported
  honestly" assumed a raw `ModelContext` inserting a second `DailyCase` with a duplicate
  `localDayKey` would throw a genuine `@Attribute(.unique)` violation, mirroring a SQL `UNIQUE`
  constraint. It does not — SwiftData's unique constraint merges/upserts silently instead of
  throwing, confirmed by writing the test and watching it fail with "an error was expected but
  none was thrown." Replaced with a real, reachable failure instead: record a revision through a
  real on-disk container, `chmod` the store file to `0o444`, then open a **fresh**
  `PersistenceActor`/`ModelContainer` at the same URL and call `recordRevision` again — this
  throws because POSIX permission is checked at `open()` time, not on every write, so the already-
  open first container would have kept succeeding. Confirmed the throw is specifically
  `FoodgeError.saveFailed` (PersistenceActor's own catch around `modelContext.save()`), not a raw
  error from container-open time, by tightening the assertion from `any Error` to
  `FoodgeError.saveFailed` and re-running. See `memory/troubleshooting/swiftdata-unique-does-not-throw-on-save.md`.
- `arc-constitution-review`: **0 blockers, 2 MINOR, both fixed.** (1) `Appeal.asSavedAppeal()`
  silently drops a corrupted appeal via `compactMap`, unlike `decodedDecision()`/`decodedEvidence()`,
  which throw `caseCorrupted` on the same class of failure — doc comment corrected to state the
  asymmetry is deliberate (losing one appeal is a smaller footprint than failing the whole
  revision) rather than leaving it unexplained. (2) `PersistenceActor.zeroPadded` assumes a
  non-negative value; doc comment corrected to say so explicitly (true for every Gregorian
  `year`/`month`/`day` component in this app's lifetime, but worth stating before the helper is
  ever reused elsewhere). One informational note (this ledger entry) closes the loop the auditor
  flagged: the `.unique` discovery now has its D-numbered decision (see above) and this entry.
  Independently re-verified the build/test claims (re-ran `GetBuildLog` at both severities and
  `grep -c "@Test"` on the new suite) rather than trusting the reported numbers.
- **Commit**: `feat(data): grow schema V1 with DailyCase/VerdictRevision/Appeal and implement CaseStore`

---

## Day 21–27 backlog (stubs — expand when the day is taken)

| Day | Unit | Deliverable | Exit condition |
|---|---|---|---|
| 21 | WU-21-B | Today flow: evidence summary, context inputs, **Give me a verdict**, verdict screen, evidence details | `arc-verify-ui` ✅ |
| 22 | WU-22-A | Appeals: compatible craving, compatible variant, cross-category choice, honest no-match | Appeal tests green |
| 22 | WU-22-B | History list and case detail preserving the evidence and rule version used at the time | `arc-verify-ui` ✅ |
| 23 | WU-23-A | Foundation Models narration after the deterministic verdict, structured and length-validated | Narration tests green |
| 23 | WU-23-B | Reviewed ES/EN fallback templates, 8-second budget, cancellation, stale-result discard, adversarial-note tests | Adversarial tests green |
| 24 | WU-24-A | Final artwork: app icon, three judge poses, nine dish illustrations; `JudgeBadgeView` swapped (D15) | Visual review |
| 24 | WU-24-B | Evening reminder (single local notification, generic content), complete ES/EN copy, feature freeze | Reminder tests green |
| 25 | WU-25-A | Accessibility, privacy, regression and performance verification. Defect fixes only | All audits no blockers |
| 26 | WU-26-A | Release candidate, clean-checkout validation, README, demo rehearsal, submission package | Clean checkout builds and runs |
| 27 | — | Contingency buffer and final verification; user submits by 21:00 Europe/Madrid | Submitted |

If time tightens, cut decorative variants and AI flourish variety first. Preserve Health
correctness, fallback behaviour, native interaction, accessibility and the complete
verdict-to-appeal flow.
