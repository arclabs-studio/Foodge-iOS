---
title: "@Attribute(.unique) merges silently — it does not throw on save()"
tags: [foodge, memory, troubleshooting, swiftdata, testing]
date: 2026-09-21
ledger: WU-21-A
---

# `@Attribute(.unique)` does not throw on `save()`

WU-21-A's test plan assumed inserting a second `DailyCase` with the same `localDayKey` — via a
raw `ModelContext` pointed at the same container, bypassing `PersistenceActor`'s own
find-or-create path — and calling `save()` would throw a genuine unique-constraint violation,
the same "real, reachable failure" shape D34's `FixturePreferencesStore` needed a scriptable
double to fake for `PreferencesStore`.

It does not throw. SwiftData's `@Attribute(.unique)` implements **merge/upsert semantics**
(built for CloudKit-style de-duplication), not a throwing SQL `UNIQUE` violation. `save()`
returned normally, "Expectation failed: an error was expected but none was thrown" — the actual
observed failure that disproved the assumption, not a guess.

## What replaced it

A genuinely reachable save failure, using a real OS-level constraint instead:

1. Record a revision through a real on-disk container (`ContainerFactory.make(at:)`).
2. `chmod` the store file to `0o444` (read-only).
3. Open a **fresh** `PersistenceActor`/`ModelContainer` at the same URL and call
   `recordRevision` again.

This throws — but only because a *fresh* container is opened after the chmod. POSIX permission
is checked at `open()` time, not on every `write()`; the original container's already-open file
descriptor keeps its write access regardless of a later chmod. Reusing the first container
would silently succeed and reproduce this exact false confidence one level down.

Confirmed the failure surfaces specifically as `FoodgeError.saveFailed` (not a raw
Core Data/SwiftData error from container-open time) by first asserting `throws: (any Error).self`
to see it pass, then tightening to `throws: FoodgeError.saveFailed` and re-running — it still
passed, proving the throw comes from `PersistenceActor`'s own
`catch { throw FoodgeError.saveFailed }` around `modelContext.save()`, not from opening the
container.

## Applies to

Any future test that wants to prove "`@Attribute(.unique)` prevents a duplicate" — it does
prevent *duplicate rows*, it just doesn't fail loudly. Don't reach for it as a save-failure
trigger again. See [[case-store-schema-v1-shape]] for what this unit built instead.
