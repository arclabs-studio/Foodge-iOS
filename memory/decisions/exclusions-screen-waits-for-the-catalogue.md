---
title: The exclusions screen waits for the catalogue
tags: [foodge, decision, onboarding, catalogue]
date: 2026-09-19
ledger: D31
---

# The exclusions screen waits for the catalogue

## The situation

WU-19-D's scope named five onboarding screens, one of them `IngredientExclusionsView`. But
`Ingredient` (`Domain/Entities/Dish.swift`) is a declared type with **zero construction sites**
in the repository. The nine-family catalogue that will actually contain ingredients is WU-20-A,
the next day's work.

## Decision

WU-19-D ships four screens — Welcome, Health connection, Preferences, and the flow that holds
them. `IngredientExclusionsView` moves to WU-20-A and is built against the real catalogue.
`PreferencesDraft.excludedIngredientIDs` **stays in the model** and is written as an empty set,
so nothing is owed when the screen arrives.

## Why, and what the alternative cost

A picker over invented identifiers produces exclusions that reference nothing. On Day 20 the
catalogue arrives with its own identifiers, and any that do not match are exclusions the user
set that silently never bite. The brief forbids exactly that: *never silently relax an
exclusion*. A migration would not save it either — there is nothing to migrate the old
identifiers *to*.

The design pass argued for shipping the seam now so the flow is complete. Overruled: an empty
screen still has to be localized into both languages, audited for accessibility, and then
rewritten on Day 20 — two passes of the expensive work for one screen's worth of completeness.

No schema change is involved. The field was already in V1.

## See also

- [[schema-v1-grows-tracking-representative]] — the one model change WU-19-D *did* make
