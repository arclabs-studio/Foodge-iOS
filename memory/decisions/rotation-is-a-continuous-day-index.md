---
title: The dish-rotation tie-break is a continuous day index, mod the full catalogue count
tags: [foodge, decision, catalogue, selection]
date: 2026-09-20
ledger: D40
---

# Rotation is a continuous day index

## What happened

WU-20-B needed a last-resort, deterministic tie-break so `sorted(by:)`'s lack of a stability
guarantee never affects which dish is recommended. The natural-seeming shortcut — day-of-year mod
the candidate count — has two independent bugs.

## Decision

```swift
let epoch = calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0)) // 1 Jan 2001
let days  = daysBetween(epoch, date, calendar: calendar)
let rotated = ((catalogueIndex - days % count) % count + count) % count
```

`count` is always the **full catalogue count** (27), never the filtered candidate count.

## Why, and what each rejected alternative breaks

- **Day-of-year, not a continuous index**: jumps backwards by 364 positions every New Year.
  Pinned by `newYearRotatesByOne`, which computes 31 Dec 2026 → 1 Jan 2027 and asserts the
  rotation differs by exactly one — a day-of-year implementation fails this outright.
- **Candidate count, not catalogue count**: the moment a user excludes one ingredient and the
  candidate set shrinks by one, everyone's rotation for that category would shift — a stable
  rotation is supposed to feel like "today's turn in an unchanging queue," not something that
  moves when unrelated preferences change.
- **Calendar day, not clock time**: computing on `calendar.startOfDay(for:)` on both ends means
  08:00 and 23:30 the same local day produce the same rotation, and the day Spain loses or gains
  an hour still advances by exactly one — both pinned by dedicated tests against
  `TestCalendar.madrid`.
- **Negative modulo**: a pre-2001 date makes `days` negative, and Swift's `%` preserves the sign
  of the dividend — the final `+ count) % count` normalizes this back into `[0, count)`. Pinned
  by a test using a 1990 date.

## See also

- [[the-catalogue-is-a-domain-constant-not-a-seam]]
