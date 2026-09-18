---
title: The Xcode 27 template ships Swift 5, and hides it
tags: [foodge, decision, swift, build-settings, concurrency]
date: 2026-09-18
ledger: D18
---

# The Xcode 27 template ships Swift 5, and hides it

## What happened

`com.apple.dt.unit.multiPlatform.app` in Xcode 27.0 creates targets with
`SWIFT_VERSION = 5.0`. Nothing announces this. The consequence is not cosmetic:

- `SWIFT_STRICT_CONCURRENCY` resolves to its default, which under Swift 5 is **`minimal`**,
  not the `complete` the project claims to require.
- Every `SWIFT_UPCOMING_FEATURE_*` flag evaluates to `NO`.

So a project can look configured for strict concurrency while compiling under the old rules,
and the first real data race would be found by a user rather than the compiler.

## Decision

`SWIFT_VERSION = 6.0` is set explicitly on all three targets.

The session plan said "confirm `SWIFT_VERSION` is the language mode value the template set,
never `6.4`". That wording guarded against confusing the *compiler* version (6.4) with the
*language mode*. It was right about the trap and wrong about the remedy: the value the
template set was 5.0, and confirming it would have locked in Swift 5.

## How to verify it stuck

Not from the build settings alone — read what the compiler was actually invoked with:

```
GetBuildLog(severity: "remark", pattern: "swift-version 6")   → matches every compile task
GetBuildLog(severity: "remark", pattern: "swift-version 5")   → matches nothing
```

That is evidence. A build setting can be overridden per configuration; the command line cannot lie.

## See also

- [[healthkit-terminates-without-usage-description]] — same lesson, different tool: verify the
  artefact, not the tool's return value.
