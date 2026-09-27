---
title: StringCatalogEdit marks everything as machine-translated
tags: [foodge, troubleshooting, localization, xcode-mcp]
date: 2026-09-19
---

# StringCatalogEdit marks everything as machine-translated

## What happened

All 67 Spanish strings for WU-19-D were written through `mcp__xcode__StringCatalogEdit`, one call
per key, as the rules require (`.xcstrings` is generated and must never be hand-edited).

Reading the catalogue back afterwards:

```
machineTranslatedCount: 67
translatedCount: 0
newCount: 0
```

Every string landed in the **machine-translated** state, not "translated". In Xcode's String
Catalog editor those rows carry the robot badge and read as needing review.

## Why, and why it was left that way

`StringCatalogEdit` has no state parameter — its schema says it "only writes translations; there
is no operation/state parameter". The state is the tool's choice, not the caller's.

The only way to change it would be to edit `Localizable.xcstrings` directly, which is exactly
what the project forbids. So the state stands.

**This is cosmetic, not functional.** Verified against the built artefact rather than the tool's
own report (D26):

```
Foodge.app/es.lproj/Localizable.strings   → 67 keys, all present
Foodge.app/es.lproj/InfoPlist.strings     → CFBundleName + NSHealthShareUsageDescription
```

The strings ship and resolve at runtime. Rendering the screens with
`previewLocalizationOverride: "es"` showed real Spanish, not the English fallback.

## What to do next time

- Do not chase the state. Marking 67 rows "reviewed" by hand in Xcode is the only honest fix, and
  it is a human's call, not an agent's.
- Do keep verifying the **built** `.app`, not the tool's `{"success": true}`. That is the same
  lesson as [[healthkit-terminates-without-usage-description]].
- `LocalizationPlanner("es")` also prepares `Foodge-InfoPlist.xcstrings`, which is easy to miss —
  `NSHealthShareUsageDescription` is user-facing text and needs translating too.
