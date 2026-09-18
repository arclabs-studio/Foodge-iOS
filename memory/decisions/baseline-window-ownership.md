---
title: The calculator cannot own calendar correctness
tags: [foodge, decision, domain, calendar, dst]
date: 2026-09-19
ledger: D24
---

# The calculator cannot own calendar correctness

## The problem the test auditor found

`ActivityBaseline` carries a `window: DateInterval`, and the brief demands calendar-aware
intervals that survive daylight-saving changes. But
`ActivityBaselineCalculator.baseline(from:trackingRepresentative:)` receives only
`[DailyActivityObservation]` — no `Calendar`, no time zone, no evaluation cutoff. It physically
cannot do calendar reasoning. Nothing in the suite asserted `window` at all.

Left alone this would have produced an unspecified field that some later screen displayed.

## Decision

Split the responsibility along the seam that already exists:

- **`EvidenceWindowPlanner`** (Data) owns calendar correctness. It cuts each previous day at the
  same *local clock time* as the evaluation, using
  `date(bySettingHour:minute:second:of:matchingPolicy:.nextTime, repeatedTimePolicy:.first)`.
  Midnight is special-cased, because searching forward for a time the day already starts at
  steps into the next day.
- **`ActivityBaselineCalculator`** (Domain) stays pure. Its `window` is simply the span from the
  first to the last day it actually used.

The daylight-saving tests therefore live with the planner, where the calendar is.

## Evidence it works

Europe/Madrid, 2026: 29 March (clocks forward) gives a **3-hour** window from midnight to 04:00,
25 October (clocks back) gives a **5-hour** one. Both asserted. A seconds-based implementation
returns 4 hours for both and passes no test.
