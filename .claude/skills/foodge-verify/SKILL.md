---
name: foodge-verify
description: Use when closing any Foodge work unit, or whenever asked to build, test, or confirm Foodge is green. Encodes the exact Xcode MCP sequence that proves a zero-warning build and green tests, including the two calls that are easy to skip and the traps that have already cost this project time.
---

# Foodge verification

Project-only. The definition of done for a Foodge work unit is **zero-warning build + green
tests + (for UI) visual verification**. This is the sequence that proves it.

## The gate

Run in order. Stop at the first failure and fix it before continuing.

```
1. mcp__xcode__BuildProject        { buildForTesting: true }
2. mcp__xcode__GetBuildLog         { severity: "warning" }        ← MUST be a separate call
3. mcp__xcode__RunSomeTests        { tests: [ …the suites… ] }
```

**Step 2 is the one that gets skipped.** `GetBuildLog` defaults to `severity: "error"`, so a
log that looks clean proves nothing about warnings. `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` means
a warning would fail the build anyway — but the explicit check is what makes "zero warnings" a
claim backed by evidence rather than an assumption. `totalFound: 0` is the evidence.

## Current suites

```json
[
  {"targetName": "FoodgeTests", "testIdentifier": "DinnerCategoryRuleTests"},
  {"targetName": "FoodgeTests", "testIdentifier": "ActivityBaselineCalculatorTests"},
  {"targetName": "FoodgeTests", "testIdentifier": "SleepIntervalUnionTests"},
  {"targetName": "FoodgeTests", "testIdentifier": "EvidenceWindowPlannerTests"},
  {"targetName": "FoodgeTests", "testIdentifier": "HealthEvidenceReaderTests"},
  {"targetName": "FoodgeTests", "testIdentifier": "ContainerFactoryTests"},
  {"targetName": "FoodgeTests", "testIdentifier": "OnboardingViewModelTests"},
  {"targetName": "FoodgeTests", "testIdentifier": "DishCatalogueTests"},
  {"targetName": "FoodgeTests", "testIdentifier": "CatalogueNameLocalizationTests"},
  {"targetName": "FoodgeTests", "testIdentifier": "DishSelectionTests"}
]
```

104 tests as of Day 20 (`OnboardingViewModelTests` was already present at Day 19 but missing from
this list — added along with the three Day 20 suites). Prefer this over `RunAllTests`, which
also runs the XCTest UI bundle. Add new suites here as they land.

## Destination

Tests and previews run on **iPhone 17 Pro (27.0)**. Switch with
`XcodeSwitchRunDestination { displayTitle: "iPhone 17 Pro (27.0)" }`.

Switch to `iPhone de CR` only for a real device run, and switch back afterwards. Changing
destination while the app is running on the phone disturbs that session.

## Verifying things the build log does not show

**Build settings** — read the compiler's own command line, not the settings table:

```
GetBuildLog { severity: "remark", pattern: "swift-version 6" }   → every compile task
GetBuildLog { severity: "remark", pattern: "swift-version 5" }   → nothing
```

**Info.plist keys and entitlements** — read the built product. A tool returning
`{"result": true}` is not evidence the project changed; that exact false positive cost a device
crash here (D26):

```bash
plutil -p ~/Library/Developer/Xcode/DerivedData/Foodge-*/Build/Products/Debug-iphoneos/Foodge.app/Info.plist | grep -i health
codesign -d --entitlements - --xml <app path> | plutil -p -
```

**Physical device** — device interaction is simulator-only in this Xcode (D21). Use
`RunProject`, have the user tap, then `GetConsoleOutput { pattern: "PROBE" }`. Anything logged
for verification emits **state labels only**, with `privacy: .public` or it is redacted — never
a Health value, never model output.

## Closing a unit

After the gate is green:

1. Run the audit the constitution requires for that unit — `arc-audit-concurrency` after
   concurrent code, `arc-verify-ui` + `arc-audit-hig` + `arc-audit-accessibility` after UI,
   `arc-constitution-review` before the day's last commit.
   Ask each one explicitly to check **whether each test could fail** and **whether any comment
   or doc claims more than the code does**. That is where they have found the real problems.
2. Record evidence in `docs/implementation-tasks.md` — actual numbers, not "tests pass".
3. Write any non-obvious decision into `memory/` **now**, not at end of session.
4. Commit.

## Do not

- Do not run `xcodebuild`, `swift build` or `xcrun simctl`. Xcode MCP only, unless the user names
  the CLI.
- Do not hand-edit `project.pbxproj` or any `.xcstrings`.
- Do not report a unit closed on your own reading of the code. The verifier's green is the exit
  condition.
