---
title: Calorie references stand alone until a meal picks one
tags: [foodge, memory, decision, calories, catalogue]
date: 2026-09-21
ledger: D47-D50
---

`CalorieReferenceCatalogue` (WU-20-C) encodes the three verified Spain McDonald's items from the
brief — Big Mac 544 kcal, hamburger 258 kcal, cheeseburger 306 kcal — as `Domain/Catalogue/`
constants, the same shape [[the-catalogue-is-a-domain-constant-not-a-seam]] already uses for the
dish catalogue. But **zero of the 27 `DishCatalogue+Dishes.swift` variants claim one of these
ids.** That is deliberate, not an oversight, and it is enforced by a regression test
(`noCatalogueDishVariantIsWiredToAReference`) so a future catalogue edit can't silently wire one
in without someone noticing.

**Why:** the three references are specific fast-food menu items in one market — an exact product,
portion, URL and verification date. None of the catalogue's 27 variants (home-style burgers,
pizza, tacos, etc.) are that product. The brief is explicit: "do not apply them to other burgers
or imply endorsement." Wiring `DishCatalogue`'s beef-burger variant to the Big Mac reference would
be exactly that violation, dressed up as a convenience.

**How to apply:** the dataset exists so a *future* flow — a user picking "I had a McDonald's Big
Mac" as their dietary intake, or a meal log entry — has something correct to attach to. Do not
wire a `calorieReferenceID` onto an existing catalogue variant just to make a demo path work end
to end; that is a product-scope decision (whether to add a new catalogue variant that genuinely
is one of these products, or build a manual-entry picker) and was deliberately left open rather
than decided silently. See also [[recorded-intake-is-an-enum-not-two-fields]] for the sibling
decision about how a manual entry (once one exists) is supposed to reach the comparison.
