# Foodge — screen and visual specification

Derived from `docs/foodge-plan.md` §2. This file is the authority for navigation, screen content,
visual identity, voice and asset naming. Product rules live in the plan; engineering rules in `CLAUDE.md`.

## Navigation

A native `TabView` with two tabs — **Today** and **History** — each owning its own `NavigationStack`.
Settings opens from a toolbar button. Appeals and short check-ins are native sheets.
Typed routes describe destinations; navigation is never rebuilt with a custom router.

Today is the centre of the product. It is not a dashboard of unrelated metrics, and it is not a chat.

## Screens

| Screen or state | Content | Primary actions | States |
|---|---|---|---|
| Welcome | One sentence explaining what Foodge does, the judge | Continue | — |
| Health connection | Why Health helps, then Apple's own authorization sheet | Connect Apple Health · Continue without Health | idle · requesting · connected · no readable data · Health unavailable |
| Recorded pattern | The recent activity pattern read from Health, shown after connection | Mark as unrepresentative | available · unavailable |
| Preferences | Diet, ingredient exclusions, favourite dish families, dinner routine | Save and finish | editing · saving · save failed |
| Today, before verdict | Date, judge, the evidence available today, optional context inputs | **Give me a verdict** | evidence readable · partially missing · none |
| Missing evidence | What is unavailable, in absence wording, never denial wording | Only the relevant short check-in | per missing kind |
| Verdict | Category, dish artwork and name, deterministic explanation, optional AI flourish | See alternative · Appeal · Evidence details | deterministic only · narrated · narration failed |
| Evidence details | Sources, timestamps, recorded activity vs baseline, sleep, optional calorie arithmetic | Back | complete · partial |
| Appeal | Craving choice, the compatible option found, the original kept visible | Accept this instead · Keep the original | compatible · no match |
| History | One case per local day, summarized | Open a case | populated · empty |
| Case detail | The evidence, rule version, dish and narration used at the time | — | read-only |
| Settings | Preferences, evening reminder, Health guidance, AI narration toggle, demo mode, delete local data | Each row | — |

Every list-shaped empty state uses `ContentUnavailableView`. Every failure keeps the result visible
with a retry action — a failed save is never reported as saved.

## Daily context inputs

Structured, all optional:

- Available dinner time: quick · relaxed.
- Current energy: low · normal.
- Craving (from the catalogue).
- Replacement for missing activity or sleep information.
- A free note, 240 characters maximum.

Structured choices refine selection inside the decided category. Free text may colour the judge's
humour only; it can never move a measurement, a dietary constraint, a calorie value or a rule.

## Visual identity

Warm, playful casefile identity in the ARC Labs / FavRes family, with original Foodge artwork.

- **Brand accents**: burgundy and gold, from the asset catalogue. Gold is an accent, never assumed
  to be accessible as text colour — contrast is verified per use.
- **Surfaces**: native system backgrounds and semantic text colours throughout. No custom greys.
- **Judge**: a small, sculpted pizza-headed judge with a restrained ivory judicial wig and a
  prominent dark-walnut gavel, in three poses. Clearly distinct from FavRes.
- **Dishes**: nine sculpted illustrations, one per dish family, sharing lighting, materials, camera
  angle and proportions. No text inside any image. Generation provenance is preserved.
- **Type**: SF system typography through semantic styles only — `.system(size:)` is never written.
- **Symbols**: SF Symbols for interface actions.
- **Liquid Glass**: only where the system supplies it (navigation bars, toolbars, standard controls).
  Content cards are never turned into glass panels.

Artwork stays subordinate to the dinner name and the primary action.

## Voice

The judge is witty, encouraging and concise. It jokes about the case, never about a person's body,
discipline or worth.

> "The court has reviewed the evidence. Tonight's leading candidate: tacos."

Forbidden in both languages: "you earned this", "burn it off", guilty-food framing, any instruction
to skip a meal, any implied medical or nutritional authority.

Spanish and English are complete, equal experiences. Spanish is not a translation afterthought:
the judge's register in Spanish is warm and slightly formal courtroom, matching the English tone.
All user-facing strings live in `Localizable.xcstrings`; no literal is left in a view once localized.

## Accessibility gates

A screen is not done until it passes all of these:

- Every interactive element has an accessibility label, plus a hint where the action is not obvious.
- Decorative artwork is `.accessibilityHidden(true)`; informative artwork carries a label.
- Dynamic Type at AX5 with no truncation or overlap, in both languages.
- Contrast ≥ 4.5:1 for text, ≥ 3:1 for large text and meaningful shapes.
- Touch targets ≥ 44 pt.
- Reduce Motion and Reduce Transparency respected.
- VoiceOver reaches the verdict, its explanation and the appeal action in a sensible order.

## Asset naming

```
Assets.xcassets/
  Colors/      AppBurgundy, AppGold, AppBurgundyMuted   (light / dark / high-contrast variants)
  Judge/       JudgeWelcome, JudgeVerdict, JudgeAppeal
  Dishes/      DishBurger, DishPizza, DishTacos,
               DishRiceBowl, DishTortilla, DishPasta,
               DishLentilSalad, DishVegetableSoup, DishVegetableWrap
  AppIcon
```

Colours are referenced by asset name only — hex and RGB literals never appear in code.
Until the final artwork lands (Day 24), `JudgeBadgeView` will stand in with an SF Symbol so the
swap touches exactly one file. Neither it nor the asset groups above exist yet: the placeholder
arrives with onboarding on Day 19, the artwork on Day 24.
