---
title: Narration has its own stage, never a TodayViewModel.Stage case
tags: [foodge, decision, presentation, today, narration]
date: 2026-09-23
ledger: D72
---

# Narration has its own stage, never a `TodayViewModel.Stage` case

## The tempting, wrong move

`TodayViewModel.Stage` already models "where the flow stands", so adding `.narrating` and
`.narrated(String)` to it looks like the tidy choice — one state machine, one `transition(to:)`,
one log line.

## Why it is wrong here, three times over

1. **Navigation.** `transition(to:)` appends `.verdict` to the nav `path` for `.verdict` and
   `.saveFailed`. A narration case would need a carve-out in that switch — the exact wall appeals
   hit in D65.
2. **`Stage` is the save-integrity machine.** `.saveFailed` means *"your verdict was not saved,
   here is a retry."* A narration failure means *"nothing happened, and the user must never
   know."* Those are opposites. Folding them into one enum puts "narration failed" one careless
   refactor away from the user's eyes, which decision 3 of this unit forbids outright.
3. **The verdict must stay visible and unchanged while narration runs** — literally the sentence
   D65 exists to satisfy, restated for a second background activity.

## Decision

```swift
enum NarrationStage: Hashable, Sendable {
    case idle, narrating, narrated(String), template
}
private(set) var narrationStage: NarrationStage = .idle
```

## The benefit that falls out of the type

`.idle`, `.narrating` and `.template` all render as "no model text", because only `.narrated`
has a `text`. So `NarrationSection` needs no spinner, no pending flag and no error branch — the
silent-failure rule is enforced by the type rather than by remembering to honour it in the view.

## See also

- [[narration-persistence-is-write-once-and-silent]] — the other half of "failure is invisible".
- [[tracking-confirmation-must-discard-not-replay]] — same class: a state machine whose obvious
  shape is wrong for this particular flow.
