---
title: The budget and the voice rules are decorators, not code inside the model call
tags: [foodge, decision, data, narration, testing, concurrency]
date: 2026-09-23
ledger: D73
---

# The budget and the voice rules are decorators, not code inside the model call

## The constraint that decides it

**The simulator has no Apple Intelligence at all.** Anything written inside
`FoundationModelsNarrator` — the timeout, the validation, the note-echo check — could only ever
be exercised on a physical device, by hand, once. That is not a test.

## Decision

Three `Sendable` types conform to the unchanged Day-18 `VerdictNarrator`, composed once in
`AppDependencies.init(container:)`:

```
DeadlineNarrator(budget: .seconds(8),
  wrapped: ValidatingNarrator(
    wrapped: FoundationModelsNarrator()))
```

Six of the eight required test-matrix scenarios then run off-device **against production code**,
with only the model itself scripted: timeout, malformed output, invented numbers, note echo,
refusal, unavailable. Device-only: a real generation and a real `refusal` /
`guardrailViolation` / `unsupportedLanguageOrLocale`.

## What this buys in the timeout, specifically

`DeadlineNarrator` races two children in a `withTaskGroup` and returns a private
`enum Outcome { case produced(String?), expired }` rather than two `String?`s — otherwise a
timeout and a genuine `nil` are indistinguishable, and both the log signal and any test that
tells them apart are gone.

`group.next()` is awaited **before** `group.cancelAll()`, so the wrapped narrator gets the whole
budget. `arc-audit-concurrency` caught that the two obvious tests (timed out, observed
cancellation) both still pass against a mutant that cancels immediately after `addTask` — robbing
every narrator of its budget. The test that actually pins the ordering is the third one:
a narrator that suspends for a *fifth* of the budget must return its text **and** report
`observedCancellation == false`.

## Cost accepted

`VerdictNarrator` ships byte-identical to Day 18 — no `prewarm`, no tone parameters. Widening a
reviewed protocol two days from feature freeze was not worth it, and the decorators need nothing
from it.

## See also

- [[audit-prompts-should-target-evidence]] — this finding is exactly the class that prompt asks for.
