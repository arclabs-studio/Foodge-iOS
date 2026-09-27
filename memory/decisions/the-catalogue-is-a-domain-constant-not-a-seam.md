---
title: The dish catalogue is a Domain constant, not a protocol seam
tags: [foodge, decision, catalogue, architecture]
date: 2026-09-20
ledger: D36
---

# The dish catalogue is a Domain constant, not a protocol seam

## What happened

WU-20-A needed to decide how the 27-variant catalogue is represented. The obvious
Clean-Architecture instinct is a protocol (`DishCatalogueProviding` or similar) with a `Data/`
implementation, mirroring `HealthAuthorizing` / `PreferencesStore` (D34).

## Decision

`DishCatalogue` is a caseless `enum` in `Domain/Catalogue/` — `static let`s for the nine `Dish`
values, the flattened `[CatalogueEntry]`, the de-duplicated `[Ingredient]`, and a `version`
string. No protocol, no conformer, no `AppDependencies` field.

## Why

D34's seam test is "does this thing have I/O or a failure mode a test needs to drive?" The
catalogue has neither — it is 27 literal Swift values, known at compile time. A protocol here
would create a seam nothing can meaningfully fake: the only "implementation" would be the same
static data restated behind an interface. A JSON resource is worse, not better: it would convert
a compile-time guarantee about diet nesting and ingredient de-duplication into a runtime decode
path, days before submission, for zero testability gain.

## Consequences

- Adding a variant is a plain code edit + a coverage-test failure if its name isn't localized —
  never a migration, a fixture update, or a fake-repository change.
- `DishCatalogue.version` exists for Day 21 (persisted with a saved case) but has no consumer or
  test yet — deliberately: a test that cannot fail is worse than no test.

## See also

- [[dynamic-name-keys-need-a-shipped-strings-oracle]]
- [[protocol-seams-for-the-onboarding-viewmodel]]
