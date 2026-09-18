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
| D17 | `.DS_Store` added to `.gitignore`; the in-repo constitution copy deleted (the original stays at outside the repository). | Hygiene, and licensed material must remain outside the submission repository. |
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

---

## Day 18 — foundation

### WU-18-A ✅ Repo hygiene and handoff documents

- **Objective / scope**: persist the plan, design specification and this ledger. Delete the in-repo
  constitution copy. No Xcode project work.
- **Inputs / docs**: `docs/foodge-plan.md` §2 and §6.
- **Acceptance**: `git status` shows only `CLAUDE.md`, `DESIGN.md`, `docs/`, `.gitignore`.
  No constitution content anywhere in the repo. `CLAUDE.md` ≤ 80 lines.
- **Tests / verifier**: `git status`, manual read-through.
- **Evidence**: 2026-09-18. In-repo constitution copy verified byte-identical to the original
  (`diff -rq`, no differences) before deletion; original intact at outside the repository.
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

### WU-19-A ⬜ Baseline calculator, category rule and sleep union

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
- **Evidence**:
- **Next**: WU-19-B.
- **Commit**: `feat(domain): implement activity baseline calculator, category rule and sleep union`

### WU-19-B ⬜ Health reader

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
- **Evidence**:
- **Next**: WU-19-C.
- **Commit**: `feat(health): add HealthKit sample source and evidence reader with same-local-time windows`

### WU-19-C ⬜ Schema V1 and persistence actor

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
- **Evidence**:
- **Next**: WU-19-D.
- **Commit**: `feat(persistence): add schema V1 with user preferences and persistence actor`

### WU-19-D ⬜ Progressive onboarding

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
- **Next**: Day 20 backlog.
- **Commits**: `feat(onboarding): add progressive Welcome, Health connection and Preferences flow`
  · `chore(debug): remove feasibility probe`

---

## Day 20–27 backlog (stubs — expand when the day is taken)

| Day | Unit | Deliverable | Exit condition |
|---|---|---|---|
| 20 | WU-20-A | Curated nine-family dish catalogue with variants, diets, ingredients, convenience tags | Catalogue tests green |
| 20 | WU-20-B | Deterministic selection (exclusions → category → craving → repeat avoidance → favourites → rotated tie-break), distinct alternative, explicit no-match | Selection tests green |
| 20 | WU-20-C | Calorie provenance: three separated quantities, comparison only when components share a cutoff, verified Spanish portion references | Calorie tests green |
| 21 | WU-21-A | Schema V1 grows `DailyCase`, `VerdictRevision`, `Appeal` (D10); `CaseStore` implementation | Reopen + revision tests green |
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
