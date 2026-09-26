# Foodge — artwork commission (app icon, judge, nine dishes)

The brief handed to the artwork agent for **WU-24-A**. `DESIGN.md` §"Visual identity" and
§"Asset naming" are the authority; this file is that authority written out as an executable
commission, with the exact palette values, file names and sizes the asset catalogue expects.

Everything below the rule is the prompt itself, verbatim — paste it whole.

---

You are producing the **final artwork set** for *Foodge*, a native iOS app. Deliver image
files plus a provenance manifest into a handoff folder. **Do not touch the Xcode project,
the asset catalogue, or any source file** — a separate engineering agent wires the assets in.

## 1. What Foodge is

Foodge turns your day into a dinner verdict. It reads what Apple Health actually recorded,
applies transparent rules, and a playful anthropomorphic **food judge** proposes one dinner in
one of three categories — **Treat**, **Balanced** or **Light**. The user can inspect the
reasoning, add context, or appeal with a craving.

Identity: **warm, playful "casefile"** — a courtroom joke played gently. The judge rules on the
*evidence*, never on the person. Spanish and English are equal first-class languages.

## 2. Hard constraints (violating any one = asset rejected)

- **No text, letters, numerals or glyphs inside any image**, in any language. Names are drawn
  by the app as system type next to the artwork.
- **No real brands, restaurant logos, or recognisable trademarked packaging.**
- **No human bodies, body shapes, scales, measuring tapes, "before/after", flames-as-calorie-burn,
  sweat, or gym imagery.** Nothing that jokes about a person's body, discipline or worth.
- **No guilt framing**: no forbidden-fruit halos/devil horns on "Treat" food, no green-tick /
  red-cross moralising, no "healthy vs bad" visual pairing. All nine dishes are drawn with
  exactly the same affection and quality. A burger is not a sin and a salad is not a reward.
- **No medical or nutritional authority signalling**: no stethoscopes, lab coats, charts, hearts
  with ECG lines, nutrition labels.
- **Original artwork only.** Preserve generation provenance (§8).
- The judge must read as **Foodge's own character**, not a generic mascot and not a variation of
  any existing ARC Labs character.

## 3. Palette (exact, from the shipped asset catalogue)

sRGB hex. Light/dark are the app's *surrounding UI* colours — artwork must sit on both.

| Token | Light | Dark | High-contrast light | High-contrast dark |
|---|---|---|---|---|
| AppBurgundy (primary) | `#7B1E3A` | `#E8899E` | `#5E1129` | `#F4B3C1` |
| AppGold (accent) | `#8A6A12` | `#E3B341` | `#6E540A` | `#F0C963` |
| AppBurgundyMuted (secondary text) | `#A85C72` | `#C98096` | `#8E4257` | `#E0A3B4` |
| AppOnBurgundy (on-burgundy) | `#FFFFFF` | `#1C0A11` | `#FFFFFF` | `#140509` |

Rules:

- **Burgundy is the identity colour; gold is an accent only** — never a large field, never the
  sole carrier of meaning, never assumed legible as small text-adjacent detail.
- Backgrounds in the app are **native system surfaces** (near-white `#FFFFFF`/`#F2F2F7` in light,
  near-black `#000000`/`#1C1C1E` in dark). Artwork is delivered on **transparent background** and
  must read clearly against *both* extremes. Test every asset on `#FFFFFF` and on `#000000`.
- Food may use its own natural colours. Keep them warm, slightly desaturated, and harmonised so
  the nine dishes look like one set — not nine stock images.

## 4. Style specification (one style, applied to everything)

- **Sculpted, tactile 3D look** — soft matte clay / glazed ceramic, gently rounded forms,
  minimal fine detail. Think small hand-made maquettes photographed in a studio, not
  photorealism and not flat vector.
- **One camera for all dishes**: identical ¾ elevated angle (~35° above horizon), identical
  focal feel (mild telephoto, low distortion), identical distance. A viewer flicking between two
  dishes should see only the food change.
- **One light rig for all assets**: soft key from upper-left, gentle warm fill, soft contact
  shadow directly beneath, no cast shadow leaving the frame, no rim-light drama.
- **Consistent physical scale**: every dish occupies roughly the same optical volume in frame.
  A pizza does not dwarf a soup bowl.
- **Centred composition**, subject fully inside frame, ~8% transparent margin on all sides.
- Artwork is **subordinate** to the dinner name and the primary button — it decorates, it never
  competes. Keep silhouettes simple and readable at **40 pt** (about 1 cm on screen).

## 5. The judge — character sheet + three poses

A small **anthropomorphic food judge**: a friendly, dignified character with a food-derived head
(your design call — it must be plausibly food, warm, and never a specific branded item), wearing
a minimal courtroom cue in **burgundy** with **gold** trim. The approved character is pizza-headed;
a restrained ivory judicial wig frames the pizza without covering the face, toppings or most of
the crust. A prominent dark-walnut gavel with one gold band must stay legible at small sizes.
Proportions: large head, small body, stable stance — a chess-piece-like silhouette.
Expression is **kind and amused**, never stern, never smug, never disappointed.

The same character, same construction, same materials in all three poses:

| Asset | Pose | Used on |
|---|---|---|
| `JudgeWelcome` | Greeting — open, welcoming gesture, slight bow or raised hand | Welcome screen, first launch |
| `JudgeVerdict` | Delivering the ruling — gavel raised clearly, confident, pleased | Today screen + the verdict/category header |
| `JudgeAppeal` | Considering an appeal — thoughtful, hand to chin, one eyebrow up, amused; gavel visible | Appeal sheet |

Each pose must be recognisable as the **same** judge at 76 pt. Deliver a character-sheet
contact image too (§8) so consistency can be checked at a glance.

## 6. The nine dishes — one illustration per family

Exactly nine, one per **family** (not per variant). The listed variants tell you what the family
must plausibly depict; draw the family's most representative, most legible form.

**Treat**

1. `DishBurger` — burger. Variants: beef, halloumi, black bean. Draw a classic stacked burger.
2. `DishPizza` — pizza. Variants: margherita, tuna & onion, vegetable. Whole round pie or a
   single wedge — pick one and keep it.
3. `DishTacos` — **Mexican** tacos. Variants: beef, prawn, black bean. Two or three filled
   soft/folded tacos.

**Balanced**

4. `DishRiceBowl` — rice bowl. Variants: chicken, salmon, tofu. A bowl of rice with toppings
   arranged in visible sections.
5. `DishTortilla` — **Spanish tortilla de patatas** (thick potato-and-egg omelette). Variants:
   potato, spinach, chorizo. **Not** a Mexican flatbread — this is the single most likely
   mistake in the set. Draw the round, deep omelette, ideally one wedge cut to show the layers.
6. `DishPasta` — pasta. Variants: bolognese, pesto, arrabbiata. A plate or shallow bowl of
   sauced pasta.

**Light**

7. `DishLentilSalad` — lentil salad. Variants: lentil & tomato, lentil & feta, lentil & tuna.
   A bowl of lentils with visible fresh components.
8. `DishVegetableSoup` — vegetable soup. Variants: garden vegetable with toast, tomato with
   toast, chickpea & spinach. A bowl of soup; a small piece of toast alongside is welcome.
9. `DishVegetableWrap` — vegetable wrap. Variants: hummus & vegetable, falafel, feta & roasted
   pepper. A rolled wrap, cut on the diagonal so filling is visible.

Cross-check before delivering: the three Treat dishes must not look richer-lit, larger or more
glamorous than the three Light dishes. Same love, same lighting, same size.

## 7. App icon

Three 1024×1024 variants, all sharing one composition: **the judge's head/bust**, burgundy-led,
one gold accent, no text, generous padding (subject inside the central ~80%), readable at 29 pt.

| Variant | Background | Notes |
|---|---|---|
| Light (default) | **Opaque**, full-bleed, no alpha anywhere | Warm burgundy field or a soft burgundy gradient |
| Dark | **Transparent background** | Subject only; the system composites it over dark material. Lighten the subject so it reads on near-black |
| Tinted | **Transparent background, grayscale** | Luminance-only; the system applies the user's tint. Rely on shape and value contrast, never hue |

Do **not** draw a rounded-rectangle mask, border, or drop shadow — the system applies the shape.

## 8. Delivery — files, sizes, folder

Handoff folder (create it): `~/Desktop/Foodge-Artwork/`

```
Foodge-Artwork/
  AppIcon/
    AppIcon-light-1024.png      1024×1024, opaque, no alpha
    AppIcon-dark-1024.png       1024×1024, alpha
    AppIcon-tinted-1024.png     1024×1024, alpha, grayscale
  Judge/
    JudgeWelcome@1x.png   200×200      JudgeWelcome@2x.png   400×400      JudgeWelcome@3x.png   600×600
    JudgeVerdict@1x.png   200×200      JudgeVerdict@2x.png   400×400      JudgeVerdict@3x.png   600×600
    JudgeAppeal@1x.png    200×200      JudgeAppeal@2x.png    400×400      JudgeAppeal@3x.png    600×600
  Dishes/
    DishBurger@1x.png     180×180      @2x 360×360      @3x 540×540
    DishPizza…            (same three sizes for all nine, names exactly as in §6)
    DishTacos… DishRiceBowl… DishTortilla… DishPasta…
    DishLentilSalad… DishVegetableSoup… DishVegetableWrap…
  Masters/                 2048×2048 PNG master per asset, same basenames
  ContactSheets/
    judge-poses.png        the three poses side by side
    dishes-grid.png        all nine in a 3×3 grid, Treat / Balanced / Light rows
    on-white.png  on-black.png   every asset composited on #FFFFFF and on #000000
  MANIFEST.md
```

Format rules:

- **PNG, sRGB, 8-bit, square, transparent background** (except the light app icon, which is opaque).
- Filenames are **exact and case-sensitive** — they become asset-catalogue names.
- The generous export sizes exist because the app scales this artwork with Dynamic Type up to
  AX5; the @3x file is what a large-text user actually sees.

`MANIFEST.md` must record, **per asset**: the generating tool and model version, the date, the
full prompt (and any seed / reference used), and any post-processing applied. Provenance is a
shipping requirement, not a nicety.

## 9. Acceptance checklist — self-verify before handing off

- [ ] No text, letters or numerals anywhere in any image.
- [ ] `DishTortilla` is a **Spanish potato omelette**, not a flatbread.
- [ ] All nine dishes share camera angle, lighting, materials, optical scale and margin.
- [ ] Treat dishes are not glamorised relative to Light dishes.
- [ ] Three judge poses are unmistakably the same character.
- [ ] Every asset is legible and clearly separated from the background at **40 pt**, composited
      on both `#FFFFFF` and `#000000` (contact sheets prove it).
- [ ] Meaningful shapes hold ≥ 3:1 contrast against both backgrounds.
- [ ] Tinted icon works in grayscale alone; light icon has **zero** alpha pixels.
- [ ] Filenames and sizes match §8 exactly; `MANIFEST.md` covers every file.
- [ ] Nothing in the Foodge repository was created, modified or deleted.

## 10. Out of scope

Wiring assets into `Assets.xcassets`, editing `Contents.json`, changing `JudgeBadgeView` or
`DishArtPlaceholderView`, building or running the app. Deliver the folder and the manifest; the
engineering agent does the rest.
