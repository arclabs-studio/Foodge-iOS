---
title: The pescatarian profile is removed, and a stored one reads as omnivore
tags: [foodge, decision, catalogue, diet, persistence]
date: 2026-10-23
ledger: D162
---

# Pescatarian removed, maps to omnivore

## What happened

The owner saw *Pescetariana* in the Spanish diet picker and did not know the word. They asked
for the option to be removed, not renamed.

## Decision

`DietProfile` loses `.pescatarian`. The fish variants now serve omnivores only. Nothing is
migrated: the store keeps the diet as a raw string, and `UserPreferences.dietProfile` already
reads an unknown value as `.omnivore`.

Vegetarian was offered as the safer mapping, because it never adds meat. The owner chose
omnivore, so a former pescatarian keeps the fish dishes and also gets meat.

## Why it matters

Everywhere else the rule is "never silently relax the diet". This is the one deliberate
exception. A later reader who sees a pescatarian receiving a burger should find this note, not
a bug.

## Gap

The fallback is untested. `dietProfileRawValue` is `private(set)`, so a test cannot store
`"pescatarian"` without a production seam.
