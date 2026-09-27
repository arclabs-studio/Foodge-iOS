---
title: HistoryViewModel.load() must never guard on the current stage
tags: [foodge, decision, presentation, history, regression-risk]
date: 2026-09-23
ledger: D69
---

# `HistoryViewModel.load()` must never guard on the current stage

## The trap

`TodayViewModel.onAppear()` starts with `guard case .gathering = stage else { return }` — correct
there, because Today's `.gathering` stage is the *initial* state and reopening only matters once,
on first appearance; re-entering an in-progress verdict flow must not restart it.

The tempting, wrong move when writing `HistoryViewModel.load()` is to copy that shape — a
`guard case .loading = stage else { return }`, or similar — because it "looks like the same kind
of screen-entry method." It is not. History exists purely to reflect whatever Today most recently
saved: the whole point of the tab is that visiting it again after saving a new verdict shows the
new case. A stage guard here would silently freeze the list at whatever it first loaded.

## Decision

`load()` fetches unconditionally, every call, regardless of `stage`:

```swift
func load() async {
    do {
        let cases = try await caseStore.allCases()
        transition(to: .loaded(cases))
    } catch {
        transition(to: .error(.storeUnavailable))
    }
}
```

No stage check anywhere in the method.

## Pinned by

`HistoryViewModelTests.reloadingReflectsTheNewResult` — loads once, changes the fixture's
scripted result, loads again, and asserts the *second* result is what `stage` shows. Every other
test in the suite would still pass with an accidental `guard case .loading = stage else { return
}` added later (they only ever call `load()` once from `.loading`); this is the one test that
would fail, which is exactly why it exists. That test proves `load()` itself has no stage guard —
it says nothing about whether SwiftUI's `.task { await vm.load() }` on `HistoryListView` actually
*re-invokes* on tab reselect, which is the other half of the claim.

## Verified live

`arc-constitution-review` flagged that second half as unverified (MAJOR, then downgraded to MINOR
once shown the evidence below — the real gap was that the evidence existed only in the session
transcript, not here). Device-interaction session on simulator `iPhone 17 Pro`, tapping
Today → History → Today → History and reading `GetConsoleOutput(pattern: "HISTORY")`:

```
12:58:26.248 [history] HISTORY stage=loaded(0)
12:58:37.114 [history] HISTORY stage=loaded(0)
```

`stage`'s initial `.loading` value is set by the property initializer, never through
`transition(to:)`, so it never logs — meaning exactly one `HISTORY stage=` line per completed
`load()` call. Two lines for two History-tab visits is exactly what a re-firing `.task` predicts,
and exactly what a *non*-refiring one would falsify (one line total, no matter how many revisits).

## See also

- [[tracking-confirmation-must-discard-not-replay]] — the same class of trap: a state-machine
  method whose obvious-looking guard is correct in one sibling view model and wrong in this one.
