# Foodge — product, design and implementation plan

## 1. Product direction and project foundation

**Foodge turns your day into a dinner verdict.** It reads the available evidence from Apple Health, applies transparent rules, and proposes one dinner with a playful food judge. You can inspect its reasoning, add context, or appeal with a craving.

Health data is the primary driver. Preferences constrain suitable dishes, and AI supplies personality. The result should feel like a small, polished Apple app with an original character.

The core experience is:

**Review today → add optional context → request a verdict → see dinner and reasoning → optionally appeal.**

### Committed hackathon scope

- iPhone app with complete Spanish and English experiences.
- Read-only Apple Health integration.
- Health-first onboarding and optional manual fallback.
- Three dinner categories: **Capricho / Treat**, **Equilibrado / Balanced**, **Ligero / Light**.
- A small, curated dish catalogue, known dietary variants and transparent calorie references.
- Optional on-device Foundation Models narration.
- Appeals, saved daily cases and settings.
- Optional evening reminder.
- Original artwork drawing on ARC Labs Studio and FavRes branding.
- Clearly labelled demonstration scenarios using synthetic data.

Recipes, meal photography analysis, conversational chat, accounts, cloud services, payments, widgets, Apple Watch apps and App Intents are deferred until after the hackathon.

### Governing standards

The studio’s engineering constitution, kept outside this repository, governs engineering practice. Foodge-specific decisions in this plan take precedence over conflicting general ARC conventions. Apple’s HIG governs platform interaction and presentation.

Apple Coding Academy materials inform coding patterns; Paul Hudson’s materials inform clarity and testability. Neither substitutes for current Apple documentation. Licensed course materials and books must remain outside the submission repository.

Use Apple documentation MCPs first, with official documentation and Markdown documentation URLs as fallbacks. Verify unfamiliar APIs before implementation.

### Verified technical baseline

| Item | Decision |
|---|---|
| Development toolchain | Installed Xcode 27.0, build 27A266a |
| Compiler | Installed Apple Swift 6.4 |
| Language mode | Swift 6 |
| Minimum deployment | iOS 26 |
| Validation | iOS 26 and iOS 27 |
| UI | SwiftUI, native controls and navigation |
| Dependencies | Apple frameworks only; no third-party or ARC packages |
| Storage | Local SwiftData |
| AI | Optional on-device Foundation Models |

Compiler version and Swift language mode are distinct; do not invent a `SWIFT_VERSION = 6.4` setting.

The event requires a native project created during the hackathon, with source supplied through GitHub. Implementation begins September 18. The organizer lists September 27 at **23:00 CET** as the deadline; use **21:00 Europe/Madrid** as the internal submission deadline to avoid the timezone ambiguity. [Hackathon rules](https://acoding.academy/hackaton26/)

---

## 2. Experience, interface and visual identity

### Navigation

Use a native `TabView` with **Today** and **History**, each containing a `NavigationStack`. Settings opens from a toolbar button. Appeals and short check-ins use native sheets.

The Today screen is the product’s centre. Avoid a dashboard of unrelated metrics or a chat interface.

| Screen or state | Content and behaviour |
|---|---|
| Welcome | One clear explanation, the judge, and a continue action. |
| Health connection | Explain the benefit, then present Apple’s authorization interface; allow continuation without data. |
| Preferences | Diet, ingredient exclusions, favourite dish families and dinner routine. |
| Today, before verdict | Date, judge, available evidence, optional context and **Give me a verdict**. |
| Missing evidence | Explain what is unavailable; offer only the relevant short check-in. |
| Verdict | Category, dinner artwork and name, deterministic explanation, optional AI flourish, alternative and appeal action. |
| Evidence details | Sources, timestamps, recorded activity comparison, sleep and optional calorie arithmetic. |
| Appeal | Choose a craving, inspect a compatible option and accept or keep the original. |
| History | Daily case summaries; detail preserves the evidence and decisions used at the time. |
| Settings | Preferences, reminder, Health connection guidance, AI narration toggle, demo mode and data deletion. |

### Progressive onboarding

Request only Health types used by the product: active energy, resting energy, steps, sleep, workouts and dietary energy.

Read available information before asking the user to supply missing information. Do not ask for measurements already available, and do not introduce unused weight, BMI, medical history or weight-loss goals.

Dietary preferences and ingredient exclusions always require user input; Foodge must not infer them from Health.

Show the recent recorded activity pattern with an action to mark it unrepresentative. Keep missing-data questions optional. Notification permission comes later, when the user enables a reminder.

HealthKit deliberately prevents apps from distinguishing denied read permission from absent data. Use wording such as **“No readable sleep data is available”**, never an unsupported assertion that permission was denied. [Health authorization](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)

### Daily context

Offer structured inputs for:

- Available dinner time: quick or relaxed.
- Current energy: low or normal.
- Optional craving.
- Missing activity or sleep information.
- An optional note, limited to 240 characters.

Structured choices may affect selection within the category. Free text can influence humour but cannot change measurements, dietary constraints, calorie values or decision rules.

### Visual direction

Create a warm, playful casefile identity using the established ARC/FavRes family:

- Burgundy and gold brand accents.
- Native system backgrounds and semantic text colours.
- A small, sculpted anthropomorphic food judge.
- Matching sculpted food illustrations.
- SF typography and SF Symbols for interface actions.

Use the inspected ARC branding guide and FavRes assets as references, while creating original Foodge artwork during the event. The judge and icon must be distinguishable from FavRes.

**Asset set:** one app icon, three judge poses and nine dish-family illustrations. Generate consistent lighting, materials, camera angle and proportions. Keep text out of images and preserve generation provenance. Use the image-generation tool during implementation.

Keep artwork subordinate to the dinner and primary action. Use native Liquid Glass navigation and controls where the system supplies them; do not turn content cards into glass panels.

Use semantic typography, light/dark/high-contrast asset variants, at least 44-point touch targets, VoiceOver labels, and layouts that work at AX5. Gold is an accent, not an assumed accessible text colour. Verify contrast. Respect Reduce Motion and Reduce Transparency.

### Voice

The judge is witty, encouraging and concise. It can joke about the case, never about someone’s body, discipline or worth.

Example tone:

> “The court has reviewed the evidence. Tonight’s leading candidate: tacos.”

Avoid “you earned food,” “burn this off,” guilty-food language and instructions to skip meals.

---

## 3. Deterministic verdict and food rules

These are **prototype product heuristics**, not validated nutritional recommendations. Their purpose and limitations must be visible in the explanation.

### Evidence contract

Each evaluation receives a dated snapshot containing:

- Available Health aggregates and their provenance.
- Optional user-reported replacements or context.
- A comparison baseline.
- Dietary constraints and preferences.
- Evidence availability and any tracking concerns.
- A fixed evaluation time and timezone.

Missing values remain missing. Never convert absent samples into zero activity or zero intake.

Use HealthKit statistics for cumulative activity rather than summing raw overlapping samples. Do not add workout calories to active energy again. For sleep, count the union of asleep intervals; do not add “in bed” and individual sleep stages together. [Health queries with Swift concurrency](https://developer.apple.com/documentation/healthkit/running-queries-with-swift-concurrency)

### Activity baseline

Use these implementation defaults:

1. Examine the previous 14 completed local calendar days.
2. Compare each day’s accumulated activity at the same local time as today’s evaluation.
3. Require at least seven nonmissing, finite, nonnegative observations.
4. Use their median, which must be strictly positive.
5. Prefer active energy; use steps when energy cannot supply a usable comparison.
6. If tracking has been marked unrepresentative, do not use that comparison.

Label this **“your recorded pattern.”** Recorded samples do not establish complete physiological measurement.

Use calendar-aware intervals for daylight-saving and timezone changes. Do not compare today’s partial day with previous full days or assume every day contains 86,400 seconds.

### Category decision table

| Evidence | Category |
|---|---|
| Today exceeds 125% of the usable baseline | Capricho / Treat |
| Today is between 75% and 125%, inclusive | Equilibrado / Balanced |
| Today is below 75%, and the user confirms tracking represents the day | Ligero / Light |
| Usable measurements unavailable; user reports more/usual/less activity | Corresponding Treat/Balanced/Light category, labelled self-reported |
| Evidence unavailable and check-in skipped | Provisional Balanced verdict |

Before issuing a low-activity verdict, ask whether the recorded activity reflects the day. If tracking was incomplete, use the fallback check-in.

Sleep, workouts and daily context refine the explanation and the choice within the category. Shorter sleep or low reported energy favours an easier dinner; it does not deduct calories or punish the user.

### Dish catalogue

Bundle nine dish families:

| Category | Families |
|---|---|
| Treat | Burgers, pizza, tacos |
| Balanced | Rice bowls, tortilla, pasta |
| Light | Lentil salad, vegetable soup with toast, vegetable wraps |

Each family has explicit ingredient-defined variants, including plant-based coverage. Store stable identifiers, localized names, category, ingredients, diet compatibility, convenience tags and optional nutrition-reference identifiers.

These categories are editorial; “Light” does not claim a verified calorie value.

Selection order is fixed:

1. Apply diet and ingredient exclusions.
2. Restrict to the selected category.
3. Match structured craving and convenience preferences.
4. Prefer dishes not selected in the previous three days.
5. Prefer favourites.
6. Break ties using stable catalogue order rotated by the local date.

Return one recommendation and one distinct eligible alternative where available. If nothing matches, show an explicit no-match state and allow preference editing; never silently relax exclusions.

Generic dish descriptions cannot guarantee restaurant ingredients or absence of cross-contact. Show ingredient information and prompt users to check the actual product when relevant.

### Calories: recorded context, never invented precision

Keep three quantities separate:

- Recorded active energy.
- Recorded resting energy.
- Recorded dietary intake.

A numerical comparison is available only when expenditure components are present for the same cutoff and intake has been confirmed complete for that period. A manually supplied intake total **replaces** the Health total; it is not added to it.

The calculation is:

**Recorded active + recorded resting − confirmed recorded intake**

Label it as a comparison of recorded values, not a remaining food allowance or a full-day energy requirement. Negative values do not suppress dinner suggestions.

For a dish, display calories only when the user chooses a known portion reference or supplies a known value and source. A generic burger has no automatic calorie value.

The initial reference set can use these verified Spanish product portions:

| Reference | Calories for one listed burger |
|---|---:|
| [McDonald’s Spain Big Mac](https://mcdonalds.es/productos/sandwiches-principales/bigmac) | 544 kcal |
| [McDonald’s Spain hamburger](https://mcdonalds.es/productos/happy-meal/hamburguesa-happy-meal1) | 258 kcal |
| [McDonald’s Spain cheeseburger](https://mcdonalds.es/productos/happy-meal/hamburguesa-con-queso-happy-meal1-new) | 306 kcal |

These were checked September 17, 2026. They exclude drinks and sides. Preserve country, product, portion, URL and verification date. Do not apply them to other burgers or imply endorsement.

Numerical context does not override the agreed activity-category rule.

### Appeals

Appeals negotiate a preference:

- A compatible catalogue craving can be accepted, including one from a different category.
- An excluded ingredient leads to a known compatible variant.
- No compatible variant produces an honest no-match result.
- A free-text dish outside the catalogue receives no invented nutritional analysis.

Keep the original category and evidence visible. The appeal records the user’s chosen dinner rather than rewriting the day’s facts.

### Saved-case lifecycle

Maintain one case per local day.

- Reopening an unchanged case returns the saved verdict without regenerating it.
- **Update evidence** explicitly creates a new revision.
- Preserve prior evidence, rule version, selected dish and narration.
- Attach each appeal to its corresponding revision.
- Changing preferences affects future evaluations, not historical facts.
- A failed save keeps the result visible with a retry action; never claim it was saved.

---

## 4. Architecture, AI and privacy

### Architecture

Use one app target, a unit-test target and a UI-test target. Organize code into app composition, presentation, domain logic and data/services without introducing unnecessary packages.

Use Clean Architecture with lightweight MVVM coordination:

- Views render state and invoke actions.
- `@Observable`, `@MainActor` view models coordinate screen behaviour.
- Native navigation owns presentation; typed routes describe destinations.
- A pure verdict engine evaluates immutable input.
- Data services implement protocols defined at the application/domain boundary.
- Inject dependencies at the composition root.

The dependency relationship is **presentation uses domain contracts; data implements those contracts**. Domain decision logic must not depend on HealthKit queries or Foundation Models.

Persisted `@Model` types are the persisted domain model under the studio’s SwiftData carve-out. Do not build duplicate entity hierarchies. Small immutable snapshots used across actor boundaries are intentional transport values.

### Internal interfaces

| Interface | Responsibility |
|---|---|
| `HealthEvidenceProvider` | Read dated aggregates and availability through real or synthetic implementations. |
| `VerdictEngine` | Produce category, reason codes, eligible dishes and comparison results deterministically. |
| `VerdictNarrator` | Produce optional localized personality text for an already completed verdict. |
| `CaseStore` | Save cases, revisions and appeals through the persistence actor. |
| `ReminderService` | Manage the single optional evening reminder. |
| Injected clock/calendar | Make time windows and daily identity testable. |

There is no public server API.

### Concurrency and persistence

Use complete strict concurrency checking, Approachable Concurrency and the current nonisolated async execution behaviour. Keep the module’s default isolation nonisolated and mark UI-facing types explicitly `@MainActor`.

Use actors for shared mutable state, structured concurrency for independent reads, cancellation on abandoned work, and compiler-checked values across actor boundaries. No unsafe sendability suppression.

Configure one SwiftData container at app composition. Use `@Query` for view reads and one `@ModelActor` for writes. Do not pass live model objects across actors.

Persist:

- User preferences.
- Daily cases and immutable verdict revisions.
- Minimum aggregate evidence needed to explain each verdict.
- Appeals and localized narration.
- Rule and catalogue versions.

Keep the catalogue bundled and versioned. Start with schema V1 and test store reopening. Any later schema change requires a migration plan.

### Foundation Models

The deterministic engine completes before narration starts.

Give the model the chosen category, approved dish name, limited tone/context tags and optional user note. Keep numerical explanations and evidence text outside generation.

Request a short, structured flourish. Treat the note as untrusted content; it cannot issue instructions or call tools. Do not expose persistence or decision-making tools to the model.

Validate output length and reject unexpected numeric claims or unsuitable content. Structured generation guarantees shape, not factual correctness, so generated prose remains visibly separate from the authoritative explanation.

Use a reviewed ES/EN template immediately when the model is unavailable, disabled, not ready, unsupported for the language, refuses, fails validation or exceeds eight seconds. Discard stale results after navigation or a newer evaluation. Save successful narration so reopening a case is stable.

Core functionality must work with AI disabled and without a network connection. [Foundation Models guidance](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models)

### Privacy and reminders

- Request Health read access only; never write demonstration data to Health.
- No backend, third-party analytics, advertising SDK or CloudKit.
- Keep Health-derived storage protected and excluded from device backups.
- Never log Health values, notes or model prompts.
- Store no raw Health time series or full model conversations.
- Provide deletion of local profile/history and cancellation of pending reminders; do not delete Apple Health records.
- Use a separate in-memory store for labelled demonstration mode.

Schedule one optional local evening notification. Its content is generic and contains no Health information. Tapping it opens Today; it does not promise background Health evaluation or AI generation. [Local notifications](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)

---

## 5. Verification and acceptance criteria

Tests use independent expected outcomes, not values recomputed with production helpers. Use Swift Testing for unit and integration tests, and XCTest for UI automation.

| Area | Required scenarios |
|---|---|
| Category rules | Below, exactly at and above both thresholds; self-reported fallback; skipped check-in. |
| Baseline | Insufficient history, missing days, zero median, invalid values, incomplete tracking, steps fallback. |
| Time | Same-time comparison, midnight, daylight-saving changes and timezone changes. |
| Health aggregation | Overlapping sleep records, absent versus zero values, workout energy not counted twice. |
| Calories | Missing resting energy, unconfirmed intake, manual replacement, negative differences, unknown portions and verified references. |
| Catalogue | Diet/exclusion filtering, deterministic selection, repeat avoidance, no-match and distinct alternatives. |
| Appeals | Compatible craving, compatible variant, different-category choice and unsupported dish. |
| Persistence | Reopening, revisions, appeal linkage, failed-save recovery and local deletion. |
| AI | Unavailable, disabled, refusal, malformed output, numerical invention, note injection, timeout and stale response. |
| UI | First launch, Health-unavailable path, verdict, appeal, history, settings and reminder navigation. |

Target at least 80% app coverage, with complete coverage of critical decision branches. Coverage is supporting evidence, not a substitute for meaningful tests.

### Device and visual gates

Validate on iOS 26 and 27, including a physical Apple Intelligence-capable iPhone:

- Real Health authorization and reading whatever data is actually available.
- Real Foundation Models generation and unavailable-state behaviour.
- No Watch dependency.
- Spanish and English, including longer text.
- Light/dark mode, increased contrast, AX5 and VoiceOver.
- Reduce Motion and Reduce Transparency.
- Small supported iPhone layouts.
- Offline launch, decision and history access.

Synthetic fixtures validate scenarios; they do not replace physical Health integration testing.

Every completed feature requires a zero-warning build, green relevant tests and visual verification. Use the studio’s testing, concurrency, HIG, accessibility, security and constitution checkpoints. Xcode MCP remains the default for project operations; do not silently substitute prohibited CLI workflows.

The planning review identified and resolved the zero-baseline guard. No implementation, build or test result is being claimed by this plan.

---

## 6. Delivery schedule and agent handoff

### September 18–27

| Date | Deliverable and exit condition |
|---|---|
| **18** | Persist the plan and original Foodge instructions; create the project; verify Health and Foundation Models feasibility on the target iPhone; establish sample data and first failing engine tests. |
| **19** | Health reader, baseline calculation, missing-data handling and progressive onboarding. |
| **20** | Deterministic engine, curated catalogue, calorie provenance and passing rule tests. |
| **21** | Native Today flow, evidence details and saved verdicts. |
| **22** | Appeals, History and explicit revision behaviour. |
| **23** | Foundation Models narration, templates, cancellation and adversarial-note tests. |
| **24** | Final artwork, reminders, complete ES/EN copy and feature freeze. |
| **25** | Accessibility, privacy, regression and performance verification. Fix defects only. |
| **26** | Release candidate, clean-checkout validation, README, demo rehearsal and submission package. |
| **27** | Contingency buffer and final verification; user submits by 21:00 Europe/Madrid. |

If time tightens, reduce decorative variants and AI flourish variety first. Preserve Health correctness, fallback behaviour, native interaction, accessibility and the complete verdict-to-appeal flow.

### Handoff package

At the beginning of implementation, persist this plan as `docs/foodge-plan.md`, the screen/design specification as `DESIGN.md`, and executable work units as `docs/implementation-tasks.md`.

Add compact, original project instructions referencing the locally available constitution. Do not copy proprietary source documents into the repository.

Each work unit records:

- Objective and permitted scope.
- Required inputs and relevant documentation.
- Observable acceptance criteria.
- Tests and external verifier.
- Completion evidence and the next task.

Use short implementation sessions with checkpoint commits. The next agent must read the saved plan, current task and decisions before editing. Changes to product rules require an explicit recorded decision.

### Demonstration

Prepare a 90-second English walkthrough:

1. Introduce the dinner-decision problem and Foodge’s judge.
2. Show Health evidence and request a verdict.
3. Explain the deterministic category and dinner choice.
4. Appeal for a burger and show preference-aware negotiation.
5. Show a labelled missing-data scenario and the reliable fallback.
6. Close with native implementation, on-device processing and accessible design.

Use clearly labelled synthetic scenarios for reproducibility, alongside proof that real Health and Foundation Models integrations were tested. Do not present synthetic values as the demonstrator’s actual health data.

### Final acceptance

Foodge is ready when a fresh installation can complete its central ritual without a Watch, network connection or available language model; readable Health data meaningfully drives its verdict; every numerical claim has provenance; appeals and history work; both languages are complete; and build, tests, accessibility and visual gates pass.

The workspace remains unimplemented during this planning session. This plan is the specification for the next agentic session.
