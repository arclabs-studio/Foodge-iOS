---
title: Dynamic nameKey lookup needs the built es.lproj as its oracle — and String(localized:locale:) cannot be trusted for it in a hosted test
tags: [foodge, decision, localization, string-catalog, testing, troubleshooting]
date: 2026-09-20
ledger: D37
---

# Dynamic name-key lookup needs a shipped-strings oracle

## What happened

WU-20-A resolves ~75 display names dynamically: `LocalizedStringResource(String.LocalizationValue
(stringLiteral: nameKey))`, where `nameKey` is a runtime string, not a literal at the call site.
Two separate problems showed up around this, in the same work unit.

## Problem 1 — `StringCatalogEdit` cannot create a key from nothing

Proven in a Phase-0 gate before spending the real ~75 keys on it: `StringCatalogEdit` on a
`stringKey` that was never extracted from a source literal fails outright ("String key ... not
found"). A dynamic key has no literal at its use site, so nothing ever gets extracted for it
automatically.

**Resolved with seed-and-delete**: a temporary file lists every new name as a
`LocalizedStringResource("English text", comment: "…")` literal purely so the build's extractor
adds the key to `Localizable.xcstrings`; translate every key; delete the file. Separately proven
(same gate): a key whose literal is later deleted **still survives**, translated, in the built
`es.lproj` — read directly with `plutil`/`NSDictionary(contentsOf:)`, not trusted from a tool
return value (D26's own standard). This is what makes seed-and-delete safe rather than merely
convenient — nothing is lost when the seed file is removed.

Cost accepted: a future catalogue addition repeats the seed step; `CatalogueNameLocalizationTests`
("every catalogue name ships a Spanish string") fails loudly if it's forgotten.

## Problem 2 — `String(localized:locale:)` lies inside a hosted unit test

`Ingredient.localizedName(in:)` originally called `String(localized: String.LocalizationValue
(stringLiteral: nameKey), locale: locale)`. Every single call returned the **English** source
string — for every ingredient, every variant, in a hosted `FoodgeTests` run — despite the built
`Foodge.app/es.lproj/Localizable.strings` on disk being correct throughout (confirmed with
`plutil`). Deterministic, not a race: rerunning the identical test twice failed on the same 37
keys both times. `RunCodeSnippet` against the app target's own code (no test host) confirmed the
same API, same key, same locale resolved **correctly** there.

**Root cause**: `String(localized:locale:)`'s bundle resolution does not follow the same
`TEST_HOST` redirection chain as `Bundle.main.url(forResource:)` inside a hosted unit test —
`Bundle.main.url(...)` correctly finds the host app's `es.lproj` (proven — the coverage test using
it passes), but the high-level `String(localized:)` API resolves through different, apparently
test-runner-scoped machinery that never finds it.

**Fix**: resolve directly —

```swift
static func localizedString(for key: String, in locale: Locale) -> String {
    guard
        let languageCode = locale.language.languageCode?.identifier,
        let lprojURL = Bundle.main.url(forResource: languageCode, withExtension: "lproj"),
        let bundle = Bundle(url: lprojURL)
    else {
        return key // the English/source-language case: no en.lproj ships at all
    }
    return bundle.localizedString(forKey: key, value: key, table: "Localizable")
}
```

`displayName` (`LocalizedStringResource`, resolved by SwiftUI at render time against the ambient
­locale) was never affected — only the explicit-locale `localizedName(in:)` used for sorting and
search needed this.

## Consequences

- Never trust `String(localized:locale:)` inside a `TEST_HOST`-hosted test target without a
  built-artifact oracle backing it up — this is exactly the class of bug `CatalogueNameLocalization
  Tests`'s "dynamic resolution actually works" test exists to catch, and it caught it.
- When a locale-explicit lookup misbehaves only in tests, isolate with `RunCodeSnippet` (runs in
  the app target's own process, no test host) before assuming the API or the built resource is
  wrong.

## See also

- [[the-catalogue-is-a-domain-constant-not-a-seam]]
- [[audit-prompts-should-target-evidence]]
