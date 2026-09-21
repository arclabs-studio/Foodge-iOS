# Foodge — project instructions

**Foodge turns your day into a dinner verdict.** It reads what Apple Health actually recorded,
applies transparent rules, and has a playful food judge propose one dinner — Treat, Balanced or
Light. You can inspect the reasoning, add context, or appeal with a craving.

The ritual is: **review today → add optional context → request a verdict → see dinner and
reasoning → optionally appeal.**

Built for the ACoding Hackathon 2026. Internal submission deadline:
**27 Sep 2026, 21:00 Europe/Madrid** (the organizer says 23:00 CET; we use the earlier time to
dodge the ambiguity).

This file is committed. It names no local paths and no internal material, so it is safe in a
public repository — keep it that way when editing.

## Governing documents

| What | Where |
|---|---|
| Engineering constitution | `~/.claude/CLAUDE.md` — machine-level, loaded automatically every session |
| Product specification | `docs/foodge-plan.md` |
| Screens, visual identity, voice | `DESIGN.md` |
| Work units + numbered decisions log | `docs/implementation-tasks.md` |
| Decisions, troubleshooting, session log | `memory/` |

Foodge decisions in `docs/foodge-plan.md` beat general studio conventions where they conflict.
Apple's HIG governs interaction and presentation.

### How the rules are actually enforced

Not by this file. The binding rules load from the studio's machine-level configuration at the
start of every session, independently of anything in the repository:

1. **The constitution** — always in context, never opt-in.
2. **Doctrine skills** — `swiftui-doctrine`, `swift-concurrency-strict`, `swift-testing-doctrine`,
   `swiftdata-architecture`, `ios-accessibility-wcag`, `apple-app-security`, `swift-modern-apis`,
   `foundation-models`. Read the matching one *before* working in its area.
3. **Audit agents** — `arc-test-engineer`, `arc-audit-concurrency`, `arc-verify-ui`,
   `arc-audit-hig`, `arc-audit-accessibility`, `arc-audit-security`, `arc-constitution-review`.
   These are the external verifier: a work unit closes on their green, not on your own reading.

So the rules hold whether or not a repository file mentions them. **The converse is the risk:**
an agent working from a clone on a machine without that configuration gets only what this file
restates. That is why the Non-negotiables and Product rules below are written out in full here
rather than referenced — treat them as the floor if nothing else is loaded, and say so plainly
rather than proceeding as if the full doctrine were in effect.

## Toolchain and targets

| Item | Value |
|---|---|
| Xcode | 27.0 (27A266a), Swift 6.4 compiler, **Swift 6 language mode** |
| Deployment | iOS 26.0 minimum, iPhone only. Validated on iOS 27 so far; iOS 26 still owed |
| Targets | `Foodge` (app), `FoodgeTests` (Swift Testing), `FoodgeUITests` (XCTest) |
| Signing | Team `4W652PD582`, bundle `com.arclabs.Foodge`, automatic |
| Storage | Local SwiftData, versioned schema V1, in-memory store for demo mode |
| AI | Optional on-device Foundation Models; the app must work fully without it |

Compiler version and language mode are different things — never write `SWIFT_VERSION = 6.4`.
The Xcode 27 template ships `5.0`, which silently downgrades strict concurrency to minimal; it
is set to `6.0` on every target.

## Non-negotiables

- Module default isolation is `nonisolated`. Every View and ViewModel is explicitly `@MainActor`.
- `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` plus complete strict concurrency are the lint gate.
  There is no SwiftLint here; a warning is a build failure.
- Apple frameworks only. No third-party packages, no ARC packages.
- No force unwrap, force cast, `try!`, implicitly unwrapped optionals.
  Test **fixtures** may fail loudly — that is the one carve-out.
- No `@unchecked Sendable`, `nonisolated(unsafe)` or `@preconcurrency`. Fix isolation properly.
- Xcode MCP is the only route for build, test, preview, file and project operations.
  Never run `xcodebuild`/`swift build` unless asked for the CLI by name.
- Never hand-edit `project.pbxproj` or any `.xcstrings`. If tooling cannot do it, stop and ask.
- **Missing Health data stays missing.** Never turn an absent sample into zero. Never claim
  permission was "denied" — HealthKit cannot distinguish absence from denial, so the wording is
  always "no readable data".
- Never log Health values, user notes or model prompts. Health-derived storage is
  backup-excluded and file-protected.
- Verify Info.plist keys and entitlements against the **built** `Foodge.app/Info.plist`. A tool
  returning success is not evidence the project changed — this one cost a device crash (D26).

## Product rules that bite

**Category decision table.** Ratio of today's activity to the recorded pattern:

| Evidence | Category |
|---|---|
| Above 125% | Treat |
| 75%–125%, **both inclusive** | Balanced |
| Below 75% **and** the user confirms tracking reflects the day | Light |
| No usable measurement, user reports more / usual / less | Treat / Balanced / Light, labelled self-reported |
| Nothing at all, check-in skipped | Provisional Balanced |

Below 75% with tracking unconfirmed returns `needsTrackingConfirmation` — ask before ruling,
because a forgotten watch looks exactly like a quiet day. A recorded comparison always outranks
a self-report.

**Baseline ("your recorded pattern").** Previous 14 completed days, each cut at the *same local
clock time* as the evaluation. At least 7 non-missing, finite, non-negative observations, median
strictly positive. Energy preferred; steps take over when energy cannot supply a usable
comparison — including when its median is zero (D23). Never used when the user marked tracking
unrepresentative.

**Health aggregation.** Use HealthKit statistics, not summed raw samples. Never add workout
calories to active energy again. Sleep is the **union** of asleep intervals, never their sum.
Calendar-aware windows: a day is not 86,400 seconds.

**Calories.** Active, resting and dietary energy stay three separate facts. A comparison is only
shown when the components share a cutoff and intake is confirmed complete. Manual intake
*replaces* the Health total, never adds to it. A dish shows calories only against a verified
portion reference. Negative results never suppress a dinner suggestion.

**Catalogue.** Nine families: burgers, pizza, tacos (Treat) · rice bowls, tortilla, pasta
(Balanced) · lentil salad, vegetable soup, vegetable wraps (Light). Selection order is fixed:
exclusions → category → craving and convenience → avoid the last three days → favourites →
stable order rotated by date. Never silently relax an exclusion; show an honest no-match.

**Voice.** Witty, encouraging, concise. Jokes about the case, never about a person's body,
discipline or worth. Banned in both languages: "you earned this", "burn it off", guilt framing,
any instruction to skip a meal.

These are prototype product heuristics, not nutritional advice, and the explanation says so.

## Layout

```
Foodge/Foodge/App/          composition root, app entry, root view
Foodge/Foodge/Domain/       Entities, Services (protocols), UseCases, Errors, Catalogue — Foundation only
Foodge/Foodge/Data/         Health, Persistence, Narration, SampleData — implements domain protocols
Foodge/Foodge/Presentation/ Features/<Screen>/{View, ViewModel, Components}
Foodge/Foodge/Resources/    Assets.xcassets, Localizable.xcstrings
Foodge/FoodgeTests/         mirrors Domain/Data structure, Swift Testing
```

Dependency direction is one-way: Presentation → Domain ← Data. One *concept* per file: a type
may share its file with the small value types that exist only as its members, named after the
primary type (D27). No file mixes unrelated types.

## Skills to read before working

| Area | Skill |
|---|---|
| Any SwiftUI view, navigation, toolbar, preview | `swiftui-doctrine` |
| async/await, actors, Sendable, isolation | `swift-concurrency-strict` |
| `@Model`, containers, `@Query`, migrations | `swiftdata-architecture` |
| Any test | `swift-testing-doctrine` |
| VoiceOver, Dynamic Type, contrast | `ios-accessibility-wcag` |
| On-device narration | `foundation-models` |
| Any Xcode operation | `arc-mcp-xcode` |

## Session protocol

1. Read `docs/implementation-tasks.md` (ledger + decisions) and skim `memory/`.
2. Take **one** work unit. Do not start the next before the current closes green.
3. A unit closes on: zero-warning build + green tests + (for UI) preview/device verification.
   The verifier's green is the exit condition, never your own judgement of the work.
   Use the `foodge-verify` skill — it encodes the exact sequence, including the warning check
   that is easy to skip.
4. **Write the memory note when the decision is made, not at the end of the session.** You are
   already writing the D-number; the note costs nothing extra then, and it is the only version
   that survives an unexpected compaction. A session that ends abruptly with unwritten notes
   loses the reasoning permanently — the code survives, the *why* does not.
5. Record evidence in the ledger as actual numbers, never "tests pass".
6. Any change to a product rule needs a new numbered decision in the ledger.
7. Push at the end of a session. Unpushed commits exist on one machine only.

## Verification notes learned the hard way

- `GetBuildLog` defaults to `severity: "error"`. Proving zero warnings needs a **second** call
  at `severity: "warning"`.
- Device interaction is **simulator-only** in this Xcode. Physical-device checks go through
  `RunProject` plus `GetConsoleOutput` (D21).
- Agents are the external verifier: `arc-test-engineer` before implementing, then
  `arc-audit-concurrency`, `arc-verify-ui`, `arc-audit-hig`, `arc-audit-accessibility`,
  `arc-constitution-review`. Every one of them has caught something real so far.
- **Ask the auditors the right question.** Their most valuable findings here have not been bugs
  in working code — they have been *evidence problems*: a test that could not fail, a fixture
  that never suspended so a concurrency test would have passed against a serial loop, a comment
  claiming an actor serialises when actors are reentrant, and two false statements in the ledger
  itself. So every audit prompt should say explicitly:
  **"check whether each test could actually fail, and whether any comment, doc or ledger entry
  claims more than the code does."**
  Also give them the context to avoid reporting intended state as a defect — deliberate stubs,
  temporary debug code, and the decisions log.
