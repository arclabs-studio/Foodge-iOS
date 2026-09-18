---
title: Energy before steps, and which refusal gets reported
tags: [foodge, decision, domain, baseline]
date: 2026-09-19
ledger: D23
---

# Energy before steps, and which refusal gets reported

## The gap in the brief

The brief says: *"Prefer active energy; use steps when energy cannot supply a usable
comparison."* It does not say whether a **zero median** counts as "cannot supply".

It matters. Someone whose watch reports zero active calories but real step counts is exactly
the person who should still get a pattern.

## Decision

1. Try active energy: at least 7 usable observations **and** a strictly positive median.
2. If it fails for *either* reason — too few, or a zero median — try steps on the same rules.
3. If steps also fail, report the **energy** failure, not the steps one.
4. `insufficientHistory(found:)` carries the count of usable **energy** observations.

Point 3 is the subtle one. Reporting whichever attempt happened to run last makes the error
depend on evaluation order, which is untestable and confusing. Reporting the preferred metric's
refusal is deterministic and matches what the user would be told: "we do not have enough of the
thing we wanted to use".

## Pinned by

`ActivityBaselineCalculatorTests.aZeroEnergyMedianFallsBackToSteps` — eight recorded energy days
with a zero median plus seven usable step days, expecting a steps baseline of 8200 rather than a
refusal.

## See also

- [[baseline-window-ownership]]
