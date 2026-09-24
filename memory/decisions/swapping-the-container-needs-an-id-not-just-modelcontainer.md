---
title: Swapping the store under a running app needs .id(), not just .modelContainer()
tags: [foodge, decision, swiftui, swiftdata, demonstration]
date: 2026-09-24
ledger: D98
---

# Swapping the store under a running app needs `.id()`, not just `.modelContainer()`

## The failure this prevents

Demonstration mode replaces the whole session: an in-memory container, synthetic evidence, stub
reminders. The obvious implementation is to hand `FoodgeApp` a different container and a different
`AppDependencies` and let SwiftUI re-render.

That is not enough, and the way it fails is the worst outcome this feature can produce.
`.modelContainer(_:)` rebinds `@Query`, so `AppRootView`'s preferences read comes from the new
store — but `MainTabView` holds `today`, `history` and `settings` in `@State`, built once in its
`init` from the dependencies it was given (see its own doc comment, which explains why they are
held that way). SwiftUI keeps `@State` across a re-render of the same view identity. So the demo
would run the **live** `TodayViewModel` — real HealthKit, real store — underneath a banner reading
"Demonstration data".

`.id(session.id)`, applied *outside* `.modelContainer`, changes the view identity and is what
actually forces those view models to be rebuilt.

## Decision

`AppLaunch.State.ready` carries an `AppSession` (container + dependencies + optional scenario id,
with a `let id = UUID()`). `FoodgeApp` applies `.id(session.id)` as the outermost modifier. The
**live** session is retained in `AppLaunch`, never reopened, so exiting a demonstration is
synchronous and cannot fail — reopening would risk `storeUnavailable` on the way back from a
demonstration, which is the worst possible moment for it.

`AppLaunch.State.loading` carries a `Loading` payload (`.live` / `.demonstration`) rather than
gaining a second case, so `FoodgeApp` attaches `.task { await load() }` only for `.live` and
`load()` guards on `.loading(.live)`. Without that, entering a demonstration would re-enter
`.loading` and race a second live store open.

## What no test can prove

None of this is provable in the unit target: `@State` retention across a re-render is SwiftUI
runtime behaviour. The check is on a device — enter a scenario, open Evidence details, and confirm
the numbers match the scenario's doc comment rather than the device's own day. If they match the
device, `.id` is missing or in the wrong place.

## See also

- [[demo-preferences-must-be-seeded-from-the-scenario]]
- [[device-interaction-is-simulator-only]]
