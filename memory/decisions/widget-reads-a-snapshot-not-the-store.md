---
title: The widget reads an App Group snapshot file, never the SwiftData store
tags: [foodge, decision, widget, security, persistence]
date: 2026-10-23
ledger: D158
---

# The widget reads a snapshot, not the store

## What happened

Widgets moved into scope with monetization (free small widget; more families in Foodge+). A
widget extension cannot open the store where it is now: the store lives in the app's own
container, with no App Group, under `.completeUnlessOpen` file protection
([[file-protection-complete-unless-open]], D29, D107).

## Decision (taken with the user, 23 Oct 2026)

The store does not move. After a saved verdict, the app writes a small `Codable` snapshot file
to an App Group container: the local day, the category, the dish ID and the provenance label.
**No Health figures.** The widget reads only that file and never links or calls HealthKit.

## Why

- Moving the store to a shared container widens who can open a Health-derived database, for a
  widget that only needs a category and a dish name.
- The snapshot is small enough to reason about: what is in it is exactly what a widget shows.

## Still open

Under `.completeUnlessOpen` a widget's content is hidden while the phone is passcode-locked.
That is fine for the free Home Screen widget, and WU-30-G writes the snapshot `.completeUnlessOpen`
and backup-excluded, asserted on the file — the store's protection is set on its own files (D107), so a new
file in another container gets nothing from it. Lock Screen widgets (Foodge+, Phase 1) need a
decision on the snapshot's protection class — plan open question Q6. Do not weaken the class
without that decision.
