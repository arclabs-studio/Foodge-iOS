# Foodge — screen and visual specification

> **Amended 2026-09-26 by D138–D141 — read this first.** The user rejected the app as built
> ("I dont choose meals, you do"). Everything below that describes the user *choosing* food is
> superseded: the craving, energy and dinner-time context controls, the free note, favourite
> families, the dinner routine, per-ingredient exclusions and the whole appeal flow are **deleted**,
> not deferred. What survives is the diet profile plus the answers the rule cannot compute (intake
> check-in, self-report, body basics). Selection order is now diet profile → category → avoid the
> last three days → date rotation, and there is no no-match outcome. `docs/implementation-tasks.md`
> carries the reasoning; the code is the authority where this file disagrees with it.
>
> **Amended 2026-10-10 by WU-29 (D145–D149):** the visual identity, the judge, motion and asset
> naming below are rewritten for the playful redesign.

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
| Health connection | Why Health helps, Apple's own authorization sheet, then which kinds came back with no readable data | Connect Apple Health · Continue without Health | idle · requesting · connected · no readable data · Health unavailable |
| Body basics | Sex, age, height and mass, and why they are asked for: on a day Health records no resting energy, they are the only way to estimate it | Continue · Skip for now | untouched · complete · half answered |
| Preferences | Diet, ingredient exclusions, favourite dish families, dinner routine | Save and finish | editing · saving · save failed |
| Today, before verdict | Date, judge, the evidence available today, optional context inputs, the *Eaten so far* check-in | **Give me a verdict** | evidence readable · partially missing · none |
| Missing evidence | What is unavailable, in absence wording, never denial wording | Only the relevant short check-in | per missing kind |
| Verdict | Category, dish artwork and name, deterministic explanation, optional AI flourish | See alternative · Appeal · Evidence details | deterministic only · narrated · narration failed |
| Evidence details | Sources, timestamps, tonight's allowance broken into its components — each line labelled recorded or estimated — sleep | Back | complete · partial |
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

> **Rewritten 2026-10-10 by WU-29 (D145–D148).** The app was "a settings screen with a pizza on
> it"; it is now a small courtroom game. The plan is `docs/migrations/2026-10-09-playful-redesign.md`.

Warm, playful casefile identity in the ARC Labs / FavRes family, with original Foodge artwork.
Native controls throughout; colour goes into backgrounds, the hero artwork, the category stamps and
the tint. **One deliberate exception:** every `Picker` is a `MenuPickerRow` — a `Menu` whose label is
the row, with the native `Picker` inside — because no `PickerStyle` can be written (D148). Do not copy
the pattern for another control; write its `*Style`.

### Two kinds of screen

| Kind | Screens | Surface |
|---|---|---|
| **Stage** — the ritual | Welcome, Today before the verdict, the deliberating state, the verdict | `StageBackground`: opaque dough washed from the top with the screen's accent at 15 % (burgundy; the verdict uses its category's tint). Content sits in native `GroupBox` cards (`StageCardGroupBoxStyle`, filled with `AppCard`, a hairline `separator` edge). |
| **Form** — data entry, settings and records | Apple Health, About you, Evidence details, History, Case detail, Settings, Demonstration | The system grouped background (D148, approved by the user). The palette, the rounded face and the judge where it heads a screen; section headers, footers and prompts in `appBurgundyMuted`. |

On a stage the **artwork leads**: the judge stands at 180–220 pt and the verdict's dish at 200 pt
(60 % of that at accessibility sizes); the judge heading the Apple Health form is 120 pt
(`StageArtworkSize`). The dinner name and the primary action stay the largest *text*. This
supersedes the old "artwork stays subordinate" line (D145).

A stage screen has **one primary action**, `primaryAction()` — `glassProminent`, the burgundy tint,
an `appOnBurgundy` label — pinned to the bottom edge with `pinnedPrimaryAction` at standard sizes and
placed inline at the end of the content at accessibility sizes (`DynamicTypeSize.pinsPrimaryAction`
decides both). Other actions in a card are `secondaryAction()`, `.bordered` with a primary label.

### Palette

Every colour lives in the asset catalogue with four appearances (light, dark, and both at Increased
Contrast); no hex or RGB literal appears in code. **Text in a colour the app sets sits on a pair
`PaletteContrastTests` measures** (≥ 4.5:1 in all four appearances): `appBurgundy`,
`appBurgundyMuted` and `label` on every system surface, `AppCard`, dough and every stage top, and each
*On* colour on its fill. Two labels sit on system fills no test can resolve — the primary action's
`glassProminent` fill and the secondary action's `.bordered` fill — and were measured from renders
(the figures are in `PrimaryActionModifier` and `SecondaryActionModifier`); re-measure them if the
tint or either style changes. Text the system draws itself (a `DatePicker`'s value, menu items,
dialogs) is the system's. The system's `.secondary` is about 3.4:1 on a light row and 3.3:1 on the
grouped background, so the app never uses it for text: `Form` headers, footers and text-field
prompts take `.formCaption()` (`appBurgundyMuted`) — a new `Section` must too, since nothing checks it —
and `LabeledContent` values take `.readableValue` at the root (D134, D135).
System red is about 3.6:1 as text on a light row, so a destructive row keeps the red on its symbol.

| Set | Light | Dark | Role |
|---|---|---|---|
| `AppBurgundy` (= `AccentColor`) | `#A3173F` | `#FF8FAB` | The brand, the tint, picker values |
| `AppOnBurgundy` | `#FFFFFF` | `#2A0A14` | Text on a burgundy fill |
| `AppBurgundyMuted` | `#8E3A55` | `#E3A3B6` | Secondary text: dates, footers, headers, prompts |
| `AppGold` | `#F2B200` | `#FFC83D` | **Decoration only** — the verdict's confetti |
| `AppTomato` / `AppOnTomato` | `#D7311F` / `#FFFFFF` | `#FF6B57` / `#2B0703` | Treat |
| `AppCheese` / `AppOnCheese` | `#FFBE2E` / `#3D2200` | `#FFC94D` / `#3D2200` | Balanced |
| `AppBasil` / `AppOnBasil` | `#1F8244` / `#FFFFFF` | `#4CC774` / `#06240F` | Light |
| `AppDough` | `#FFF4E2` | `#24170F` | The stage |
| `AppCard` | `#FFFFFF` | `#433C38` | Cards and speech bubbles on a stage — lighter than every stage top in dark |

A category is never told by colour alone: its stamp carries the name and a symbol
(`party.popper.fill`, `equal.circle.fill`, `leaf.fill`), and its badge always the name, with the
symbol where it fits. Tomato and basil share a luminance in light
appearance, and cheese and gold fall under 3:1 as *shapes* on light surfaces — accepted because
neither is ever the sole carrier of meaning.

### Type, symbols, glass

- **Type**: SF Rounded, set once at the window root with `.fontDesign(.rounded)`; semantic text styles
  only — `.system(size:)` is never written. Previews get the same face from `.sampleData`. Text the
  system draws in its own chrome (navigation titles, tab labels) keeps the system face.
- **Symbols**: SF Symbols for interface actions and the category marks.
- **Liquid Glass**: only where the system supplies it — bars, toolbars, the prominent primary action
  (`glassProminent`). Cards and bubbles are never glass.

### The judge

A small, sculpted pizza-headed judge with a restrained ivory wig and a dark-walnut gavel, in two poses
(`JudgeWelcome`, `JudgeVerdict`). Clearly distinct from FavRes.

- **Tappable on Welcome, on Today before the verdict, and at the head of Apple Health (D146).**
  `JudgeHeroView` is a `Button` named *The judge*: a tap hops, plays a light haptic and shows the next
  of eight quips in a speech bubble **below** it, so it never moves out from under the finger, and
  VoiceOver hears the quip. Quips speak
  in the flourish's voice and pass `NarrationValidator`; they reach no rule, dish or store.
- **Deliberating** while a verdict is worked out (`DeliberatingJudgeView`), above a native
  `ProgressView` that carries the status. Not tappable.
- **Decorative** everywhere else (`JudgeBadgeView`): the flourish on the verdict, History's empty state.

### Dishes

Nine sculpted illustrations, one per dish family, sharing lighting, materials, camera angle and
proportions, with no text inside any image; generation provenance is preserved. Large on the verdict
and case detail (`DishHeroView`), at row size in History (`DishArtworkView`). Always decorative: the
dish name is the text beside it.

### Motion (D147)

Every motion is decoration and has a still form. Motion nobody asked for stops within five seconds
(WCAG 2.2.2): the judge's breath (two 2.4 s breaths, none after a tap), the deliberating tilt (4.8 s),
the confetti (2.5 s).

The verdict's **reveal** — the stamp slams in with a heavy haptic, the dish pops with confetti, the
cards arrive — plays once per saved revision per launch. Returning from Evidence details shows it
settled, and case detail never plays it.

Under **Reduce Motion** the judge does not hop and its press dims instead of squashing; the stamp's
slam, the dish's pop, the dish swap, the cards' entrance and the bubble become fades; the confetti
draws nothing; the stamp's haptic drops from heavy to light, and the announcements stay. Where it is
read: by the screen, which passes `motion` down (the verdict's reveal is chosen in `VerdictView`), and
also by the judge components, the dish section and the confetti themselves, whose `motion` input can
only turn motion off (D147).

## Voice

The judge is witty, encouraging and concise. It jokes about the case, never about a person's body,
discipline or worth.

> "The court has reviewed the evidence. Tonight's leading candidate: tacos."

**Cheat-meal framing is allowed in English** — the judge grants a cheat meal, and a voice that could
not say so could not describe its own product. In Spanish the word is **capricho**, never *comida
trampa*: *trampa* is cheating-as-transgression and carries exactly the guilt that stays out.

Forbidden in both languages: "you earned this", "burn it off", guilty-food framing, any instruction
to skip a meal, any implied medical or nutritional authority.

The model's flourish may name the category and the dish. It may **never state a number** — the
allowance figures appear only in deterministic copy, where they can be checked against the
arithmetic that produced them, and each is labelled as an estimate.

Spanish and English are complete, equal experiences. Spanish is not a translation afterthought:
the judge's register in Spanish is warm and slightly formal courtroom, matching the English tone.
All user-facing strings live in `Localizable.xcstrings`; no literal is left in a view once localized.

## Accessibility gates

A screen is not done until it passes all of these:

- Every interactive element has an accessibility label, plus a hint where the action is not obvious.
- Decorative artwork is `.accessibilityHidden(true)`; informative artwork carries a label.
- Dynamic Type at AX5 with no truncation or overlap, in both languages.
- Contrast ≥ 4.5:1 for text, ≥ 3:1 for large text and meaningful shapes — except a shape that is
  never the sole carrier of meaning (cheese and gold, D145).
- Touch targets ≥ 44 pt.
- Reduce Motion and Reduce Transparency respected.
- VoiceOver reaches the verdict, its explanation and the appeal action in a sensible order.

## Asset naming

```
Assets.xcassets/
  AccentColor  (= AppBurgundy)
  Colors/      AppBurgundy, AppOnBurgundy, AppBurgundyMuted, AppGold,
               AppTomato, AppOnTomato, AppCheese, AppOnCheese, AppBasil, AppOnBasil,
               AppDough, AppCard          (light / dark / high-contrast variants)
  Artwork/
    Judge/     JudgeWelcome, JudgeVerdict
    Dishes/    DishBurger, DishPizza, DishTacos,
               DishRiceBowl, DishTortilla, DishPasta,
               DishLentilSalad, DishVegetableSoup, DishVegetableWrap
  AppIcon
```

Colours and images are referenced through the Xcode-generated symbols (`.appBurgundy`,
`.judgeWelcome`), never by string name, and hex and RGB literals never appear in code. A new colour
that carries text joins `PaletteContrastTests` with the surfaces it sits on, in the same change.
