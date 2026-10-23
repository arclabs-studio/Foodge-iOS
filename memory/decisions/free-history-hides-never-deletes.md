---
title: The free 7-day history hides older cases; it never deletes them
tags: [foodge, decision, history, monetization, persistence]
date: 2026-10-23
ledger: D155
---

# Free history hides, never deletes

## What happened

The monetization strategy (decided 22 Oct 2026) put "7-day history" in the free tier and "full case file" in Foodge+.
Checking the code while planning found that **there is no 7-day limit today**:
`PersistenceActor.allCases()` has no `fetchLimit`, and nothing prunes old cases. So the limit
is new, and it could be built two ways: prune the store, or filter at read time.

## Decision (taken with the user, 23 Oct 2026)

Filter at read time. Every case stays in the store. A pure Domain function,
`HistoryWindow.visible(cases:entitlements:today:calendar:)` (WU-30-D), shows the last 7 local
days plus a locked "case file" row on the free tier, and everything for an owner.

## Why

- Pruning destroys data the person may want back. A refund followed by a repurchase would lose
  history for good, and so would a free user who buys a month later.
- Read-time filtering composes with [[entitlement-is-derived-never-persisted]]: a refund hides,
  a repurchase or restore shows everything again, with no store change.

## How to check it stays true

WU-30-D's acceptance asserts the case count through `CaseStore` on an in-memory store, before and
after gating and across an entitlement change — a test on the pure function alone could not fail. Day math is local-calendar
and DST-safe (a day is not 86,400 seconds), the same rule as the rest of Foodge.
