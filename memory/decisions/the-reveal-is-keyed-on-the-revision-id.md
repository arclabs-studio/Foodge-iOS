---
title: The reveal is keyed on the revision id
tags: [foodge, decision, motion, swiftui]
date: 2026-10-10
ledger: D147
---

# The reveal is keyed on the revision id

`TodayViewModel.claimReveal()` answers `true` once per `SavedRevision.id`, and the verdict screen
plays its stamp → dish → cards reveal only then.

## Why the id, and not a flag or the value

- **A `Bool` flag** reveals the first verdict of the launch and never another. A mutation run with
  exactly that (`revealedRevisionID == nil`) failed `newRevisionPlaysTheRevealAgain`.
- **The `SavedRevision` value** changes when narration arrives: `attachNarration` returns a new
  value with the same id, and `transition(to: .verdict(updated))` swaps it in. Keying on the value
  would replay the whole reveal the moment the flourish lands. `narrationArrivingDoesNotReplay`
  pins it.
- **Navigation** cannot reset it, because `claimReveal()` takes no path input at all — returning
  from Evidence details or from Today simply finds the claim spent.

## What it is not

It lives in memory, so it is once per revision **per launch**: a cold start that reopens tonight's
verdict reveals it once more. Persisting it would be a schema change for decoration.

## The frame before the claim

`.task(id:)` runs after the first frame, so the view would draw a new revision fully and then
collapse it into the reveal. `isRevealPending` — a read with no side effect — lets the view draw
nothing of an unclaimed revision until `play` starts, and `VerdictReveal` starts `.settled` so an
already-claimed verdict in a fresh screen shows at once. Both found by `arc-audit-concurrency`
reading the code, not by any test.

## See also

- [[a-tappable-character-must-not-move-under-the-finger]]
