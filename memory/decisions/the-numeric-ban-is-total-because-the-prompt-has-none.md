---
title: The narration numeric ban is total, and one/una are deliberately excluded
tags: [foodge, decision, domain, narration, validation, localization]
date: 2026-09-23
ledger: D74
---

# The narration numeric ban is total, and `one`/`una` are deliberately excluded

## Why a total ban is legitimate rather than lazy

`NarrationPrompt` contains **no number of any kind** — no ratio, no median, no calorie figure, no
step count, no reason codes. That is the spec's "keep numerical explanations outside generation",
and it is what licenses the validator to reject *any* numeral: with none in the input, any number
in the output is necessarily invented.

The dependency runs the wrong way round from how it reads, so it is easy to break later. The test
that holds it up is `NarrationPromptTests.promptContainsNoNumbers`: it builds a prompt from a
decision carrying `ratio: 1.02` against a `median: 400` and asserts not one numeral survives.
**If a future change puts a number in the prompt, that test fails and the ban must be narrowed —
not the other way around.**

## What "any number" covers

- Any numeral via `Character.isNumber` — `430`, `٣`, `½`, `³`, not just ASCII digits.
- Number words on whole-word boundaries, EN and ES: `two…ten`, `hundred`, `dozen`, `twice`,
  `double`, `percent`; `dos…diez`, `cien`, `mil`, `docena`, `doble`, `por ciento`.
- Units with no digit in sight: `kcal`, `calorie(s)`, `caloría(s)`, `gram(o)`, `step(s)`,
  `paso(s)`, `minute(s)`, `minuto(s)`, `hour(s)`, `hora(s)`, `%`. "Plenty of calories" invents a
  measurement just as surely as "430 calories" does.

## The exclusion that matters

**`one`, `un`, `una` and `uno` are NOT in the list.** `una` is the Spanish indefinite article;
adding it rejects nearly every valid Spanish flourish while every other test in the suite still
passes — a silent kill of the Spanish path.

`NarrationValidatorTests.indefiniteArticlesAreAccepted` is a negative control for exactly that:
four sentences whose only "number word" is an article, asserted **accepted**. It fails the moment
someone tidily "completes" the list.

## The matching trap on the other side

`NarrationTemplateLocalizationTests.spanishTemplatesPassTheValidator` runs the shipped Spanish
templates — read from the built `es.lproj/Localizable.strings`, never `String(localized:locale:)`
(D37) — through the same validator. It catches the opposite collision: reviewed ES copy that the
ES banned list would reject, i.e. the app shipping a line it refuses to let the model say.

## See also

- [[dynamic-name-keys-need-a-shipped-strings-oracle]] — why the built artefact is the oracle here.
