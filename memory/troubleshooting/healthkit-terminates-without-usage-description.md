---
title: HealthKit terminates the app when the usage description is missing
tags: [foodge, troubleshooting, healthkit, xcode-mcp, info-plist]
date: 2026-09-18
ledger: D26
---

# HealthKit terminates the app when the usage description is missing

## Symptom

Tapping "Connect Health" on the device quit the app instantly. It looked like a crash in our
code. It was not.

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException',
reason: 'NSHealthShareUsageDescription must be set in the app's Info.plist in order to
request read authorization for the following types: HKQuantityTypeIdentifierDietaryEnergyConsumed,
HKCategoryTypeIdentifierSleepAnalysis, HKQuantityTypeIdentifierBasalEnergyBurned,
HKWorkoutTypeIdentifier, HKQuantityTypeIdentifierActiveEnergyBurned, HKQuantityTypeIdentifierStepCount'
```

This is documented behaviour: *"You must set the usage keys, or your app will crash when you
request authorization."* It is a hard termination, not a thrown Swift error, so no `catch` can
save you.

## Root cause

The real problem was one layer up. `AddInfoPlist` had been called during project setup and
returned:

```json
{"result": true}
```

…and persisted nothing. The key was absent from the build settings, absent from
`Foodge-InfoPlist.xcstrings`, and absent from the built `Info.plist`. A second, byte-identical
call worked. The cause of the first no-op is unknown.

## How it was found

Read the built product, not the project:

```bash
plutil -p .../Build/Products/Debug-iphoneos/Foodge.app/Info.plist | grep -i health
```

That immediately showed the key missing while the entitlement was present
(`com.apple.developer.healthkit => true` via `codesign -d --entitlements`), which narrowed it
from "HealthKit is broken" to "one key did not land" in one command.

## The rule that came out of it

**A tool reporting success is not evidence the project changed.** Every Info.plist key and
entitlement is verified against the built `Foodge.app` before it is relied on. The same applies
to build settings — see [[swift-6-language-mode-not-template-default]] for reading the compiler
command line instead of trusting the setting.

## Cost

About twenty minutes, one confusing device crash, and it would have resurfaced on Day 19 when
real onboarding requests authorization.
