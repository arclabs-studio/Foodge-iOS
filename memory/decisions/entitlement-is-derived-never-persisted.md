---
title: Foodge+ entitlement is derived from StoreKit, never stored
tags: [foodge, decision, storekit, monetization]
date: 2026-10-23
ledger: D161
---

# Entitlement is derived, never persisted

## What happened

Planning Foodge+ (WU-30, plan `docs/migrations/2026-10-23-monetization-phase-0.md`) raised the
usual first idea: an `isPlus` flag in `UserPreferences`, set after a purchase. That flag would
need a schema change, a migration for the TestFlight testers' V1 stores, and code to clear it
on a refund.

## Decision

The app never stores whether the person owns Foodge+. It reads
`Transaction.currentEntitlements` and keeps the value current with one `Transaction.updates`
listener, started once at launch, for the live session only. Domain sees an `Entitlements`
value through `EntitlementProviding`; demonstration, preview and test modes supply fixed values
through the same protocol.

## Why

- **Nothing to tamper with.** A flag on disk can be edited. A verified transaction cannot.
- **Nothing to migrate.** Packs, the case file, streaks and the tip seal are all read-time
  rules over this value, so none of them needs a schema field.
- **Revocation applies itself.** A refund arrives through `Transaction.updates`; the features
  lock at that update with no clean-up code.

## The consequence to remember

Anything Foodge+ shows must be a function of `Entitlements` at read time. If a future feature
seems to need "remember that they had it", stop: that is the flag this decision rejected.
The one thing that *is* persisted is the person's **selected judge** (WU-30-E, `FoodgeSchemaV2`)
— a choice, not an entitlement — and it renders as the standard judge while not entitled.

## See also

- [[free-history-hides-never-deletes]]
- [[widget-reads-a-snapshot-not-the-store]]
