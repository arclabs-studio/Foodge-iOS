---
title: A wedged test runner decided which pass shipped
tags: [foodge, decision, verification, catalogue, testing]
date: 2026-09-25
ledger: D125
---

# A wedged test runner decided which pass shipped

Pass C of the energy-allowance rebuild — the catalogue collapse from 9 families / 27 variants
to ten dishes, one per kind (ledger D115, D116, D120) — was **dropped** at the Checkpoint-B
review. The catalogue ships unchanged.

## What actually decided it

Not the size of the edit. The edit is mechanical: delete `DishVariant` and `CatalogueEntry`,
fold the variant's fields into `Dish`, collapse D41's two-level recency to one.

The deciding fact is that **`DishSelectionTests` is 466 lines, 25 tests, and every fixture is
built on `CatalogueEntry`.** The collapse breaks the entire suite in one stroke — by design,
since the type the fixtures name stops existing. Recovering from that means iterating red→green
across 25 tests.

And the MCP test runner is wedged on this machine: `RunSomeTests` has stalled on four
consecutive attempts, `.xcresult` created and then no progress for 30+ minutes, while
`BuildProject` and `GetTestList` answer in seconds. See
[[device-interaction-is-simulator-only]] for the sibling constraint. So each red→green attempt
costs a hand-driven ⌘U from the user, roughly 24 hours from the deadline.

**The alternative's cost was a selection algorithm rewritten blind** — recency, exclusion and
rotation behaviour verified by 25 tests, replaced with no observed test run. That is the trade,
and it is not close.

## What this means for the log

D115, D116 and D120 are **decided-but-unbuilt**. They stay in `docs/implementation-tasks.md`
as the reasoning of a pass that was not taken, and a later reader must not take them as
describing shipped code. D120's `DishFamily` naming debt never arises: the name is only a
misnomer under one-dish-per-kind.

`CLAUDE.md`'s Catalogue paragraph and `DESIGN.md`'s catalogue sections were deliberately left
untouched during Pass B for exactly this reason — they already describe what ships.

## The lesson

**A verification loop you cannot close is a scope constraint, not an inconvenience.** When the
external verifier is unavailable, the honest move is to shrink the work to what the remaining
verifiers can still prove, rather than to keep the scope and downgrade the evidence. Cost of
dropping Pass C: dish cards show no calorie figure — which is [[calorie-references-stand-alone-until-a-meal-picks-one]]'s
existing, deliberate behaviour (D50), not a regression.
