---
title: The reminder toggle needs a second flag, because onChange echoes the app's own revert
tags: [foodge, decision, presentation, settings, swiftui, regression-risk]
date: 2026-09-24
ledger: D89
---

# The reminder toggle needs a second flag, because `onChange` echoes the app's own revert

## The trap

`EveningReminderSection` binds a native `Toggle` to `SettingsViewModel.reminderEnabled` and
reports the change with `.onChange`. The honesty rule is that a refused permission must **not**
leave the switch on — so the failure path in `scheduleReminder()` sets `reminderEnabled = false`
itself.

That write is a change like any other. SwiftUI sends it straight back through the same
`.onChange`, as "the user switched the reminder off". The naive handler then runs the whole
disable path: cancel a reminder that was never scheduled, clear the stored time, save, **and
clear `reminderFailure`** — which erases the one sentence telling the user why their reminder
did not happen, a frame after it appeared.

A guard on "did the value change" does not help: it genuinely changed.

## Decision

Two pieces of state, not one:

- `reminderEnabled` — what the control shows.
- `isReminderScheduled` — what the system actually accepted. Only set after
  `ReminderService.schedule(at:)` returns without throwing.

The handler compares against reality, not against the control:

```swift
func reminderEnabledChanged(to isEnabled: Bool) async {
    guard isEnabled != isReminderScheduled else { return }
    ...
}
```

The echo of the revert arrives as `false` while `isReminderScheduled` is already `false`, so it
returns immediately and the explanation survives.

## Pinned by

`SettingsViewModelTests.theRevertedToggleKeepsTheRefusalVisible` — refuses permission, then
sends the revert's change notification by hand and asserts `reminderFailure` is still
`.reminderNotAuthorized` and `cancelCount == 0`. Collapse the two flags back into one and it
fails on both counts.

`SettingsViewModelTests.aRefusedReminderIsNeverReportedAsSet` covers the other half: the store
recorded nothing, so no reminder time is persisted for a reminder that does not exist.

## See also

- [[a-sixth-health-state-for-a-failed-request]] — the same family of rule: a refusal, a failure
  and an absence are three different things, and only one of them may be claimed.
