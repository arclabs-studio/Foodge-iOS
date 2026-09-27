---
title: Colours are authored before the artwork
tags: [foodge, decision, design, assets]
date: 2026-09-19
ledger: D33
---

# Colours are authored before the artwork

## Why now and not Day 24

The constitution forbids hex and RGB literals in code, so the asset catalogue has to exist the
moment anything is tinted — and `JudgeBadgeView` is tinted the moment onboarding exists. Day 24
then swaps *artwork* only, never the palette, which keeps that day's change small.

`AppBurgundy`, `AppGold` and `AppBurgundyMuted` are authored with all four appearances (any,
dark, high-contrast light, high-contrast dark), plus a real value for `AccentColor`, which the
Xcode template ships empty.

Gold is an **accent**, never assumed legible as text — contrast is verified per use, not per
colour.

## How they were written, and why that is inside the rules

The Xcode MCP exposes no asset-catalogue tool. There is no `AddColorSet`. The colour sets are
therefore authored by writing `.colorset/Contents.json` directly under
`Foodge/Foodge/Resources/Assets.xcassets/Colors/`.

That is allowed here, and the reason is specific: the target uses a
`PBXFileSystemSynchronizedRootGroup`, so files appearing on disk are already in the target —
**no `project.pbxproj` edit is involved**. The prohibition is on hand-editing `project.pbxproj`
and `.xcstrings`, both of which are generated. An `.xcassets` folder is a plain directory of
JSON that Xcode's own UI edits in place.

Colours are referenced through the Xcode-generated symbols (`Color.appBurgundy`), never
`Color("AppBurgundy")` — a typo in the string form is a blank colour at runtime instead of a
compile error.

## See also

- [[a-preview-is-a-composition-root]]
