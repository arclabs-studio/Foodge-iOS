---
title: "RenderPreview can snapshot before a preview's second `await` settles"
tags: [foodge, memory, troubleshooting, swiftui, previews, xcode-mcp]
date: 2026-09-22
ledger: WU-22-A
---

# `RenderPreview` can snapshot before a second `await` settles

`AppealSheetView`'s composed previews (in `AppealSheetView.swift`) drive `TodayViewModel` through
a multi-step async chain, e.g.:

```swift
AppealSheetView(vm: vm)
    .task {
        await vm.onAppear()
        await vm.proposeCraving(.burgers)   // a SECOND suspension point after mount
    }
```

`RenderPreview` intermittently captured the snapshot after `onAppear()` resolved but before
`proposeCraving(_:)`'s own internal `await` had resolved — showing the sheet still on its initial
`.choosingCraving` state instead of the negotiated result. This reproduced across many rebuilds
and several different mitigation attempts (`.task` vs `.onAppear` for the sheet's own internal
reset, an explicit `Task.sleep`, wrapping in a detached `Task`) — none of them fixed it.

## The actual pattern (confirmed by `arc-verify-ui`)

Previews with exactly **one** `await` after mount before reaching their target state rendered
correctly and consistently (e.g. `"Choosing craving"`: `await vm.onAppear()` only — the default
`appealStage` already is `.choosingCraving`; `"Free text"`: `await vm.onAppear()` then a
*synchronous* `vm.beginFreeText()`). Every preview with a **second** `await` after mount
(`await vm.onAppear(); await vm.proposeCraving(...)` or `await vm.submitFreeText(...)`) was the
one that sometimes rendered the wrong state. This correlation, not a `.task` re-firing bug, is
the best available explanation — `.task` (no `id:`) is documented to fire once per view identity,
not on a descendant's body re-evaluation from an unrelated `@Observable` property change, and this
is the only view in the codebase pairing an internal `.task`/`.onAppear` with an external
preview-driving `.task` on the same view, which is what exposes the tooling gap.

## What to do next time a composed preview needs 2+ sequential awaited VM calls

- Don't assume a snapshot showing the "wrong" (usually initial) state means the ViewModel logic
  is broken — check the ViewModel-level test suite first; if those pass, this is very likely the
  same rendering-timing gap, not a regression.
- Standalone leaf-component previews (that don't touch the ViewModel/`.task` chain at all) are
  unaffected and are the reliable fallback for visual review of each state's actual layout.
- A live device/simulator tap-through is the real tiebreaker, but see
  [[device-interaction-synthesize-session-not-found]] for that tool's own current reliability
  problems in this environment.
- Don't spend more than one or two rebuild cycles chasing this specific symptom — it did not
  resolve across many attempts in WU-22-A and is very likely an environment limitation, not
  something fixable from application code.

## See also

- [[device-interaction-synthesize-session-not-found]]
