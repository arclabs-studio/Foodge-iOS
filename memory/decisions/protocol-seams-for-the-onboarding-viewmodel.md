---
title: Two protocol seams, and why the draft moved to Domain
tags: [foodge, decision, architecture, testing]
date: 2026-09-19
ledger: D34
---

# Two protocol seams, and why the draft moved to Domain

## The problem with the ledger's dependency list

WU-19-D's entry named `HealthAuthorizationService` and `PersistenceActor` — both **concrete** —
as `OnboardingViewModel`'s dependencies. Each is untestable for a different reason:

- `HealthAuthorizationService.requestReadAuthorization()` presents Apple's own system sheet.
  There is nothing to assert off-device, and a test that called it would hang or no-op.
- `PersistenceActor.savePreferences(_:)` throws `FoodgeError.saveFailed` only when
  `modelContext.save()` throws, which an in-memory container never does. The failure path — the
  one that must never report a failed save as a save — would have been **unreachable in tests**.

## Decision

`Domain/Services/HealthAuthorizing.swift` and `Domain/Services/PreferencesStore.swift`. Both
existing concrete types conform with **no API change at all** — the protocols were written from
the methods that already existed.

`PreferencesStore` names `PreferencesDraft`, so the draft moved from
`Data/Persistence/PreferencesDraft.swift` to `Domain/Entities/PreferencesDraft.swift`. It was
always Foundation-only with no persistence API in it; leaving it in Data would have forced
`OnboardingViewModel` to `import`-depend on Data and broken the one-way direction
`Presentation → Domain ← Data` that `arc-constitution-review` checks.

## The part worth remembering: a `#Preview` is a composition root

`Data/SampleData/PreviewDependencies.swift` names `AppDependencies`, which lives in `App/`.
Data referring to App is backwards for production code. It is allowed here because a preview
*is* a composition root — the same role `FoodgeApp` plays — and the file is `#if DEBUG`, so it
never reaches the shipped binary.

`PreviewDependencies` vends **Domain-typed seams only** (`healthUnavailable()`,
`connected(_:)`, `savingFails()`), never a ready-made ViewModel. Vending a ViewModel would put
presentation logic in Data and quietly become a second place where a screen's state is decided.

## See also

- [[colour-sets-before-artwork]]
- [[audit-prompts-should-target-evidence]]
