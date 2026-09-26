---
title: UIStringLocalizationTests cannot pass on a physical device, by construction
tags: [foodge, troubleshooting, testing, localization, device]
date: 2026-09-26
---

# UIStringLocalizationTests cannot pass on a physical device

On 2026-09-26 the first real test run of the energy-allowance rebuild was done by hand with ⌘U
while Xcode's destination was **iPhone de CR**, a physical device. Result: **268 tests in 33
suites, 11 failures.**

One failure has a proven, structural root cause:

```swift
private static let sourceCatalogURL = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()   // …/Localization
    …
    .appendingPathComponent("Foodge/Resources/Localizable.xcstrings")
```

`#filePath` is the **build machine's** path, baked in at compile time. A simulator shares the
Mac's filesystem, so the file is there. **A physical device has no `/Users/…` tree**, so
`Data(contentsOf:)` fails, `declaredKeys` falls back to `[]`, and the test fails its own
`#require(!Self.declaredKeys.isEmpty)`.

So `everyDeclaredUIStringShipsASpanishTranslation` is **simulator-only by construction**. It is
not a regression and no amount of translating will fix it on a device.

## What was ruled out for the sibling failures

`NarrationTemplateLocalizationTests` reads `Bundle.main`'s built `es.lproj`, not `#filePath`.
Its three flourish-template keys were checked and are **fine at both ends**:

- present with Spanish values in `Foodge/Resources/Localizable.xcstrings`, none `stale`
- present in the **built** `es.lproj/Localizable.strings` of *both* `Debug-iphonesimulator` and
  `Debug-iphoneos` — 349 keys each

So the translations ship. Whatever `Bundle.main` resolved to during that device run, it was not
the freshly built app bundle. Consistent with [[xctestdevices-clone-keeps-its-own-locale]]: the
thing the test reads is not always the thing you just built.

## How to apply

**Run this project's tests on `iPhone 17 Pro (27.0)`.** The `foodge-verify` skill already says
so; this note is *why* it matters, with a failure that is impossible to fix any other way.
Before reading a localization failure as a missing translation, check the built artefact first —
`plutil -convert json -o - <app>/es.lproj/Localizable.strings` — per
[[foodge-verification-habits]].

Related: [[dynamic-name-keys-need-a-shipped-strings-oracle]],
[[stringcatalogedit-cannot-flatten-a-varied-string]].
