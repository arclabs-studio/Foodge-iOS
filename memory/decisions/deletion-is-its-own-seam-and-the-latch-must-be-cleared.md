---
title: Deletion is its own Domain seam, and the onboarding latch has to be cleared with it
tags: [foodge, decision, data, app, settings, privacy]
date: 2026-09-24
ledger: D87, D93
---

# Deletion is its own Domain seam, and the onboarding latch has to be cleared with it

## The seam

`LocalDataErasing` (`Domain/Services/`) rather than a sixth method on `PreferencesStore`.
`PersistenceActor` conforms to it alongside `PreferencesStore` and `CaseStore`, so there is still
exactly one writer over the container. The reason to keep it apart is blast radius: a screen that
only edits preferences should not be able to reach a wipe at all.

It deletes by fetching and deleting each `UserPreferences` and `DailyCase`, **not** with
SwiftData's batch `delete(model:)` — a batch delete does not run the model layer's cascade rules,
so `VerdictRevision` and `Appeal` rows would survive with no case to belong to. It throws the
existing `FoodgeError.saveFailed`; a deletion that does not commit is a write that did not
complete, and a new error case would have bought nothing but a second sentence to translate.

## The latch

`AppRootView` decides which experience is shown from

```swift
preferences.first?.hasCompletedOnboarding == true || onboarding.didFinish
```

The second term is a within-session latch. Someone who onboards and then deletes in the same
session would keep it `true` and stay in the tab bar with no profile behind it. So `MainTabView`
now takes an `onLocalDataErased` closure, `SettingsView` calls it when `deleteState` becomes
`.deleted`, and `AppRootView` answers by rebuilding the onboarding view model — `didFinish`
starts `false` again.

**What is still unproven:** whether `@Query` re-reads after `PersistenceActor`'s *separate*
`ModelContext` deleted the record. If it does not, the first term stays stale-`true` until the
next launch, and the reset does nothing visible. That is the same open question
`AppRootView`'s own comment has carried since WU-19-D, and only a device answers it. Check it on
the phone before claiming "delete returns you to onboarding" anywhere user-facing.

## See also

- [[protocol-seams-for-the-onboarding-viewmodel]] — why the fixture-driven failure path exists
  at all (D34): the real actor's save throws only when the context does, which an in-memory
  container never will.
