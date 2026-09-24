# Foodge Artwork — Provenance and Delivery Manifest

Generated: 2026-09-24

This manifest archives the original raster-artwork handoff for Foodge. The statement in the
generation record that no Xcode project files were touched describes the handoff phase before
the approved asset-catalogue integration.

## Tooling and provenance policy

- Generation tool: OpenAI built-in image generation tool.
- Model version: not exposed by the built-in tool.
- Seeds: not exposed by the built-in tool.
- Deterministic post-processing: FFmpeg 8-bit PNG scaling/compositing with Lanczos
  resampling, maximum lossless PNG compression, and mixed PNG prediction.
- Color management: every PNG is tagged sRGB IEC61966-2.1.
- Optimization: lossless only. No color quantization was used because preserving
  translucent edges, subtle ceramic shading, and Liquid Glass source quality was
  preferred over a smaller but visibly degraded file.
- Final generation sources were 1254 x 1254 PNG files with alpha.
- Masters were resampled to 2048 x 2048. Runtime assets were resampled from the
  masters to their exact requested @1x, @2x, and @3x dimensions.

## Brand and design ancestry

The early character exploration referenced these existing studio assets for family
resemblance only. Their marks, characters, and geometry were not copied:

- FavRes current app icon:
  /Users/arclabsstudio/Developer/Apps/FavRes-iOS/FavRes-iOS/FavRes-iOS/Resources/FavRes_Icon.icon/Assets/AppIcon_1024x1024.png
  SHA-256 2cc900338797e038f984d7dddb5915647403006bd91cd12e6778c2b4c742798b
- ARC Labs Studio boxed burgundy logo:
  /Users/arclabsstudio/Developer/Packages/ARCDesignSystem/Sources/ARCDesignSystem/Resources/ARCBrandAssets.xcassets/Logos/ARC_Logo_Boxed_Burgundy.imageset/ARC_Logo_Boxed_Burgundy.png
  SHA-256 9a3dc207fb4a87cda88884bf5e65c9d5adf1b7bacbe0f89bf3d83e63f0547937

The final original character is a circular margherita-pizza judge. It uses FavRes
only as a reference for centered silhouette, generous padding, and small-size
recognition, and ARC Labs Studio only as a reference for burgundy-led hierarchy and
restrained gold.

## Final palette

- Judicial burgundy robe: approximately #A85C72
- Oxblood collar and deep accents: approximately #5E1129
- Warm parchment neck tab
- Dark walnut gavel and shoes
- Aged brass accent, used sparingly
- Food uses natural warm, slightly desaturated colors

## Judge assets

### JudgeVerdict

Files:

- Masters/JudgeVerdict.png
- Judge/JudgeVerdict@1x.png
- Judge/JudgeVerdict@2x.png
- Judge/JudgeVerdict@3x.png

Generation source:

- Built-in output: exec-9d2bcfa7-055e-4f04-8c7c-4e476fa1bf82.png
- SHA-256: 600df61078650b26e4c8bd123df0dca933b8b46285aa4a643189d45ec7b55f5b
- Reference: approved pizza-judge color study

Full prompt:

Use case: identity-preserve.
Asset type: final Foodge JudgeVerdict master artwork for native iOS UI and app-icon
source. Image 1 is the approved pizza-judge character study; use the right-hand
burgundy judge as the sole identity reference. Render one isolated final
JudgeVerdict character, delivering the ruling after a gentle gavel tap, confident
and pleased. Preserve the approved pizza-head face, crust-ring silhouette, robe
construction, body, materials, and personality. Make the pizza head about 8 percent
smaller relative to the body; simplify the pizza to exactly three broad topping
accents total, placed away from the eyes and mouth; make cheese, crust, robe, and
body more matte ceramic/clay and less photorealistic; tune the robe for contrast on
both white and black. Same friendly original Foodge judge: whole round pizza head
with thick golden crust ring, warm matte cheese center, exactly three minimal
topping accents total—two small softened tomato-red shapes and one muted basil-green
leaf. Existing kind amused eyes, raised eyebrow, small smile and warm cheeks. Small
chess-piece-like body. Burgundy judicial robe with oxblood collar, small ivory neck
tab, restrained aged-brass piping and buttons. Walnut shoes. Tiny walnut gavel with
one small brass band held low immediately after a gentle tap. The free hand rests
confidently behind the back. Sculpted tactile 3D; soft matte clay and lightly glazed
ceramic; small handmade maquette; rounded forms; minimal fine detail; premium
original iOS character art; not photorealistic and not flat vector. Single full-body
character centered in a square canvas; front three-quarter view at about 35 degrees
elevation; mild telephoto and low distortion; stable stance; subject fully inside
frame with about 10 percent transparent margin on every side; simple silhouette
readable at 76 pt. Soft key from upper-left, gentle warm fill, compact soft contact
shadow directly beneath and contained inside the frame; kind, amused, confident,
never stern. Robe main muted judicial burgundy approximately #A85C72; collar and
deep accents oxblood approximately #5E1129; neck tab warm parchment; tiny aged-brass
accent; walnut gavel and shoes; pizza in warm slightly desaturated natural colors.
Genuinely transparent alpha, no backdrop, vignette, glow, border, or frame. Same
approved character identity; original Foodge character; clear separation on both
pure white and pure black; no text, letters, numerals, glyphs, logos, trademarks,
watermark, plate, pizza box, missing slice, ingredient clutter, realistic grease,
dripping cheese, human body shape, wig, scales, law book, medical, health, gym,
calorie, guilt, moralizing, horns, or halo. Avoid large head, realistic food
photography, glossy plastic, large gold fields, aggressive gavel pose, sternness,
smugness, disappointment, and cast shadow leaving the frame.

### JudgeWelcome

Files:

- Masters/JudgeWelcome.png
- Judge/JudgeWelcome@1x.png
- Judge/JudgeWelcome@2x.png
- Judge/JudgeWelcome@3x.png

Generation source:

- Built-in output: exec-50de55f1-1435-4c8a-9ea7-b56a52052e5e.png
- SHA-256: 523f24a87b97562f9df8d86edab52af992d47b7954dd3b6f84736c16f2531acf
- Reference: JudgeVerdict generation source

Full prompt:

Use case: identity-preserve. Asset type: final Foodge JudgeWelcome master artwork
for native iOS UI. Image 1 is the approved definitive JudgeVerdict character anchor.
Render the exact same Foodge pizza judge in a welcoming first-launch pose: small
friendly bow, one tiny open hand raised in greeting with palm visible, the other
hand holding the tiny walnut gavel low and relaxed. Expression open, kind and
amused. Preserve exactly the same whole round pizza head, thick crust-ring
silhouette, exactly three topping accents, eye shape and color, eyebrows, smile,
cheeks, body proportions, robe construction, neck tab, shoes, materials, and
palette from Image 1. Do not redesign the character. Identical sculpted tactile 3D
soft matte clay and lightly glazed ceramic handmade maquette from Image 1; rounded
forms; minimal detail. One full-body character centered in a square canvas; same
front three-quarter camera at about 35 degrees elevation, same mild telephoto feel
and optical scale; fully inside frame with about 10 percent transparent margin;
compact contact shadow directly beneath. Identical soft upper-left key and warm fill
from Image 1; welcoming and gently playful. Genuinely transparent alpha; no backdrop,
vignette, glow, border, or frame. Change only pose and greeting expression; retain
exact identity and colors. No text, letters, numerals, glyphs, logos, trademarks,
watermark, extra props, plate, pizza box, missing slice, ingredient clutter,
realistic grease, human body shape, wig, scales, law book, medical, health, gym,
calorie, guilt, moralizing, horns, or halo. Avoid waving gavel, aggressive pose,
sternness, smugness, disappointment, glossy plastic, photoreal food, and cast shadow
leaving the frame.

### JudgeAppeal

Files:

- Masters/JudgeAppeal.png
- Judge/JudgeAppeal@1x.png
- Judge/JudgeAppeal@2x.png
- Judge/JudgeAppeal@3x.png

Generation source:

- Built-in output: exec-2caded06-14e8-48c6-8843-754cab932523.png
- SHA-256: 34f8e310b3177c6b58e5d7bcefd5d156d66242b33e9cf08106957e66373bc48d
- Reference: JudgeVerdict generation source

Full prompt:

Use case: identity-preserve. Asset type: final Foodge JudgeAppeal master artwork for
native iOS UI. Image 1 is the approved definitive JudgeVerdict character anchor.
Render the exact same Foodge pizza judge considering an appeal: one tiny hand
resting thoughtfully at the chin, one eyebrow slightly higher, eyes glancing gently
upward, amused and curious; the other hand holds the tiny walnut gavel lowered
against the side. Stable stance, no dramatic movement. Preserve exactly the same
whole round pizza head, thick crust-ring silhouette, exactly three topping accents,
eye shape and color, smile, cheeks, body proportions, robe construction, neck tab,
shoes, materials, and palette from Image 1. Do not redesign the character.
Identical sculpted tactile 3D soft matte clay and lightly glazed ceramic handmade
maquette from Image 1; rounded forms; minimal detail. One full-body character
centered in a square canvas; same front three-quarter camera at about 35 degrees
elevation, same mild telephoto feel and optical scale; fully inside frame with about
10 percent transparent margin; compact contact shadow directly beneath. Identical
soft upper-left key and warm fill from Image 1; thoughtful, kind and amused, never
skeptical or judgmental. Genuinely transparent alpha; no backdrop, vignette, glow,
border, or frame. Change only pose and thoughtful expression; retain exact identity
and colors. No text, letters, numerals, glyphs, logos, trademarks, watermark, extra
props, plate, pizza box, missing slice, ingredient clutter, realistic grease, human
body shape, wig, scales, law book, medical, health, gym, calorie, guilt, moralizing,
horns, or halo. Avoid sternness, smugness, disappointment, finger-pointing,
aggressive gavel, glossy plastic, photoreal food, and cast shadow leaving the frame.

## Dish assets

The complete prompt for each dish is its category base prompt below followed by its
asset-specific prompt. Generation outputs were transparent 1254 x 1254 PNG.

### Treat base prompt

Use case: stylized-concept. Asset type: final Foodge dish master artwork for native
iOS UI. Image 1 is the approved Foodge judge, reference only for the exact studio
lighting, tactile matte clay/ceramic material language, rounded simplification, warm
slightly desaturated color harmony, and premium polish. Do not add a face, limbs,
clothing, gavel, or character features to the dish. Sculpted tactile 3D food
maquette; soft matte clay and lightly glazed ceramic; gently rounded forms; minimal
fine detail; appetizing but not photorealistic; warm slightly desaturated natural
food colors; same family as Image 1. One isolated dish only, centered in a square
canvas, fully inside frame with about 8 percent transparent margin on all sides;
identical three-quarter elevated camera about 35 degrees above horizon; mild
telephoto, low distortion; consistent physical scale and optical volume with the
rest of the set; simple silhouette readable at 40 pt. Soft key from upper-left,
gentle warm fill, compact soft contact shadow directly beneath, no cast shadow
leaving the frame; equal affection and polish across all categories. Genuinely
transparent alpha, no backdrop, surface, vignette, glow, border, or frame. No text,
letters, numerals, glyphs, logos, trademarks, branded packaging, watermark, face,
eyes, mouth, limbs, character features, human body, scales, measuring tape, flame,
sweat, gym, medical, chart, nutrition label, guilt, moralizing, halo, horns,
checkmark, or cross. Avoid stock-photo look, photorealism, excessive gloss, greasy
shine, dramatic rim light, category-coded lighting, clutter, garnish outside the
dish, and cropped edges.

### Balanced base prompt

Use case: identity-preserve. Asset type: final Foodge dish master artwork for native
iOS UI. Images 1–3 are the approved Treat dish style anchors. Match their shared
studio lighting, tactile 3D clay/ceramic material language, warm slightly desaturated
color harmony, centered isolated presentation, camera height, focal feel, optical
scale, and polish. Do not copy their ingredients. Do not add a face, limbs, clothing,
or character features. Sculpted tactile 3D food maquette; soft matte clay and lightly
glazed ceramic; gently rounded forms; simplified broad ingredients; appetizing but
not a photograph; warm slightly desaturated natural food colors. One isolated dish
only, centered in a square canvas, fully inside frame with about 8 percent
transparent margin on all sides; fixed three-quarter elevated camera about 35
degrees above horizon; mild telephoto, low distortion; same distance and roughly
same optical volume as the reference dishes; simple silhouette readable at 40 pt.
Identical soft key from upper-left, gentle warm fill, compact soft contact shadow
directly beneath, no cast shadow leaving the frame; exactly the same affection and
polish as Treat. Genuinely transparent alpha, no backdrop, surface, vignette, glow,
border, or frame. No text, letters, numerals, glyphs, logos, trademarks, branded
packaging, watermark, face, eyes, mouth, limbs, character features, human body,
scales, measuring tape, flame, sweat, gym, medical, chart, nutrition label, guilt,
moralizing, halo, horns, checkmark, or cross. Avoid stock-photo look, hyperrealism,
excessive gloss, greasy shine, dramatic rim light, category-coded lighting, clutter,
garnish outside the dish, and cropped edges.

### Light base prompt

Use case: identity-preserve. Asset type: final Foodge dish master artwork for native
iOS UI. Images 1–3 are approved Foodge dish style anchors. Match their exact shared
studio lighting, tactile 3D clay/ceramic material language, warm slightly desaturated
color harmony, centered isolated presentation, three-quarter camera height,
mild-telephoto focal feel, optical scale, and premium polish. Do not copy their
ingredients. Do not add a face, limbs, clothing, or character features. Sculpted
tactile 3D food maquette; soft matte clay and lightly glazed ceramic; gently rounded
forms; simplified broad ingredients; appetizing but not a photograph; warm slightly
desaturated natural food colors. One isolated dish only, centered in a square canvas,
fully inside frame with about 8 percent transparent margin on all sides; fixed
three-quarter elevated camera about 35 degrees above horizon; mild telephoto, low
distortion; same distance and roughly same optical volume as the references; simple
silhouette readable at 40 pt. Identical soft key from upper-left, gentle warm fill,
compact soft contact shadow directly beneath, no cast shadow leaving the frame;
exactly the same affection, size, saturation, contrast, and polish as Treat and
Balanced dishes—do not make Light greener, dimmer, smaller, plainer, or morally
superior. Genuinely transparent alpha, no backdrop, surface, vignette, glow, border,
or frame. No text, letters, numerals, glyphs, logos, trademarks, branded packaging,
watermark, face, eyes, mouth, limbs, character features, human body, scales,
measuring tape, flame, sweat, gym, medical, chart, nutrition label, guilt,
moralizing, halo, horns, checkmark, or cross. Avoid stock-photo look, hyperrealism,
excessive gloss, greasy shine, dramatic rim light, category-coded lighting, clutter,
garnish outside the dish, and cropped edges.

### DishBurger

- Files: Masters/DishBurger.png and Dishes/DishBurger@1x.png through @3x.png
- Built-in output: exec-dc6790f4-f691-41d2-82d8-f4974476b558.png
- SHA-256: ac1b9d42ace163dfe9d9cf2ac624ecff08c840f27684710b09c909accbc1b5f0
- Prompt suffix: DishBurger—a classic compact stacked burger, representative of the
  burger family. Warm golden top bun and bottom bun, one broad dark-brown patty, a
  softly folded cheddar layer, one restrained muted-green lettuce layer, and a
  subtle tomato-red layer. Keep the stack tidy, stable, rounded, and compact; no
  wrapper, plate, fries, flag, or skewer. Use few broad layers for clarity.

### DishPizza

- Files: Masters/DishPizza.png and Dishes/DishPizza@1x.png through @3x.png
- Built-in output: exec-e24cb0bd-150a-4061-acfd-03bd224a03b3.png
- SHA-256: 0f1f78a5c717882b14fb9b0c263ab65e475d0aa1b228d78b3973f6496818b453
- Prompt suffix: DishPizza—one whole round margherita pizza, representative of the
  pizza family. A low round pie at the fixed three-quarter elevated angle, thick
  softly rounded golden crust, warm cheese surface, restrained tomato showing
  subtly beneath, exactly five broad topping accents total distributed naturally:
  three softened tomato-red shapes and two small muted basil-green leaves. No
  missing slice, plate, cutter, box, or extra garnish. This is a dish, not the judge:
  absolutely no face or character features.

### DishTacos

- Files: Masters/DishTacos.png and Dishes/DishTacos@1x.png through @3x.png
- Built-in output: exec-150190b4-77e5-4760-bcce-39135c45d26c.png
- SHA-256: c909bfba886f19031a55499e3af959d0d51b05607974c8e950b4eb5f33e17e5f
- Prompt suffix: DishTacos—exactly three Mexican soft folded tacos, representative
  of beef, prawn, and black-bean variants as one coherent taco family. Three warm
  corn tortillas in a compact fan arrangement, each visibly folded and filled with
  broad simplified layers of savory filling, muted green leaves, and small tomato
  accents. Make them unmistakably Mexican tacos, not hard-shell American fast-food
  tacos and not wraps. No plate, basket, paper liner, lime wedge, flag, or extra
  garnish.

### DishRiceBowl

- Files: Masters/DishRiceBowl.png and Dishes/DishRiceBowl@1x.png through @3x.png
- Built-in output: exec-a4f0327a-d66e-49ec-9d96-13cd030fb365.png
- SHA-256: 1fbd10e053f7660fdd9e7d0110c0c8b9cea4f3cd4fa4da0477bb30b0fddc69c9
- Prompt suffix: DishRiceBowl—a compact shallow ceramic bowl of rice with
  representative toppings arranged in broad visible sections. Warm off-white rice
  base visible around three clear topping sections: simple glazed salmon cubes,
  muted-green vegetables, and golden tofu cubes, with a small warm-red vegetable
  accent. Use broad simplified pieces, not tiny grains or garnish clutter. One
  burgundy ceramic bowl with a thin restrained parchment rim. No chopsticks, spoon,
  sauce bottle, side dish, or loose garnish.

### DishTortilla

- Files: Masters/DishTortilla.png and Dishes/DishTortilla@1x.png through @3x.png
- Built-in output: exec-a54f7b4a-ffd4-4cd3-8151-27683555411b.png
- SHA-256: d3e88ad7447c34ee985dad87ad0fac9e40f0e9fc784b092dae1759aff3dddafc
- Prompt suffix: DishTortilla—unmistakably Spanish tortilla de patatas, a thick
  round potato-and-egg omelette. This must not resemble a Mexican tortilla,
  flatbread, wrap, pancake, quiche, or cake. One deep, thick, round golden Spanish
  potato omelette with a softly browned matte surface. Cut one clean wedge and pull
  it only slightly outward to reveal distinct broad layered slices of tender potato
  bound with egg inside. Present directly with no plate, pan, cutlery, sauce, herbs,
  flag, or garnish. Preserve a compact circular silhouette and substantial depth.

### DishPasta

- Files: Masters/DishPasta.png and Dishes/DishPasta@1x.png through @3x.png
- Built-in output: exec-a569b48f-4b54-4d31-8e95-d432007bea91.png
- SHA-256: 5cf09fd62ae0cc0c93653503da82252c4b7060e19fbb1288c7da942af8c0f1c9
- Prompt suffix: DishPasta—a shallow ceramic bowl of warmly sauced pasta,
  representative of the pasta family. Broad short curled pasta pieces coated in a
  warm tomato-burgundy sauce, arranged in one simple mound inside a shallow
  parchment ceramic bowl with a thin burgundy rim. Add only three small muted-green
  basil accents total. No fork, spoon, grated-cheese dust, meatballs, bread, side
  dish, or garnish outside the bowl. Use simplified broad shapes that remain
  legible at 40 pt.

### DishLentilSalad

- Files: Masters/DishLentilSalad.png and Dishes/DishLentilSalad@1x.png through @3x.png
- Built-in output: exec-d6dd3d08-5073-4780-a1c3-26228e6f6ba2.png
- SHA-256: 5c56fd6ead6ccf80ee6ab5a0b4836efba5ec7d843cd821c26b85c621a8a43e01
- Prompt suffix: DishLentilSalad—a compact shallow ceramic bowl of lentil salad,
  representative of the lentil-salad family. Broad visible brown-green lentils with
  restrained fresh components: softened tomato-red pieces, a few warm ivory
  feta-like cubes, and several muted-green leaves. Keep ingredient count low and
  grouped in clear sections rather than confetti-like scatter. Use a burgundy
  ceramic bowl with a thin parchment rim. No fork, spoon, tuna can, dressing bottle,
  bread, side dish, or loose garnish.

### DishVegetableSoup

- Files: Masters/DishVegetableSoup.png and Dishes/DishVegetableSoup@1x.png through @3x.png
- Built-in output: exec-7fbfaa81-b6db-45ea-8782-52e6103dd6e1.png
- SHA-256: c55636710cbd8de92edf0d744d1157104127c19199bd26d888d4a9c338dee48b
- Prompt suffix: DishVegetableSoup—a warm bowl of garden vegetable soup with one
  small piece of toast alongside. A compact parchment ceramic bowl with a burgundy
  rim, filled with warm amber-red broth. Show only a few broad rounded vegetable
  pieces—muted green, orange, warm red, and chickpea gold—clearly visible at the
  surface. One small triangular piece of golden toast rests close beside the bowl
  within the same compact silhouette. No spoon, steam lettering, herbs outside the
  bowl, saucer, napkin, or extra side dish.

### DishVegetableWrap

- Files: Masters/DishVegetableWrap.png and Dishes/DishVegetableWrap@1x.png through @3x.png
- Built-in output: exec-7911afa0-8b35-479b-891e-e4a8ce1e1a13.png
- SHA-256: 8791c930147946674f10182245280e9981a0ba2f6dc835f9001c665b4a1d944f
- Prompt suffix: DishVegetableWrap—one rolled vegetable wrap cut diagonally into
  exactly two compact halves so the filling is visible. Warm lightly toasted
  flatbread wrap exterior, clean diagonal cut faces showing broad simplified layers
  of hummus beige, muted-green vegetables, roasted pepper red, and a few golden
  falafel-like pieces. Arrange the two halves in a stable compact crossed/leaning
  presentation with consistent optical volume. No plate, basket, paper, toothpick,
  sauce cup, fries, or loose garnish. This is a wrap, not a taco or burrito in foil.

## App icon

### Generated foreground

Generation source:

- Built-in output: exec-d23d74a4-19a1-4591-970a-f25eb88005d1.png
- SHA-256: 423d552bcef2b4759c76d46b429e67fa7227960e0b83ae5bb74d0186fdd1b21f
- Reference: JudgeVerdict generation source

Full prompt:

Use case: identity-preserve. Asset type: final Foodge app icon foreground source for
Apple Icon Composer. Image 1 is the definitive approved Foodge JudgeVerdict
character; preserve its exact identity. Render a clean isolated head-and-shoulders
bust of the exact same pizza judge for an app icon. No hands and no gavel. Preserve
the pizza face, circular crust-ring silhouette, exactly three topping accents, eye
shape, eyebrows, smile, cheek warmth, burgundy judicial collar, ivory neck tab, and
restrained brass trim. Identical sculpted tactile 3D soft matte clay and lightly
glazed ceramic from Image 1; rounded simplified forms; premium original iOS icon
artwork; slightly simplify microtexture so it stays crisp at 29 pt. Single bust
centered in a square 1024-style canvas; face looking directly toward the viewer with
only subtle three-quarter volume; circular head dominates but remains entirely
inside the central 78 percent of canvas; shoulders and collar fill the lower portion;
generous transparent padding; strong, balanced silhouette; no rounded-rectangle
mask. Soft upper-left studio key, gentle warm fill, kind amused confidence;
controlled highlights suitable for Icon Composer material effects. Same warm pizza
colors and muted judicial burgundy approximately #A85C72; oxblood collar shadow
approximately #5E1129; warm parchment neck tab; exactly one restrained aged-brass
accent. Genuinely transparent alpha; no backdrop, vignette, glow, border, frame,
drop shadow, or contact shadow. Exact approved character identity; readable at
29 pt. No text, letters, numerals, glyphs, logos, trademarks, watermark, hands,
arms, gavel, body below shoulders, plate, pizza box, missing slice, ingredient
clutter, realistic grease, human body shape, wig, scales, law book, medical, health,
gym, calorie, guilt, moralizing, horns, or halo. Avoid photoreal food, glossy
plastic, excessive microtexture, large gold field, ornate costume, sternness,
smugness, disappointment, and cropped crust.

### Flattened variants

- AppIcon/AppIcon-light-1024.png: foreground scaled to 820 x 820 and centered on an
  opaque diagonal gradient from #A85C72 to #5E1129; RGB, zero alpha pixels.
- AppIcon/AppIcon-dark-1024.png: foreground scaled to 820 x 820, centered on
  transparent 1024 x 1024, brightness +0.055 and saturation 0.88 for near-black
  separation.
- AppIcon/AppIcon-tinted-1024.png: foreground scaled to 820 x 820, centered on
  transparent 1024 x 1024, luminance-only grayscale.

### Icon Composer source

Foodge_Icon.icon is a working Apple Icon Composer package and was opened
successfully in Icon Composer from Xcode 27. It contains:

- Assets/JudgeBust_1024x1024.png
- icon.json with a burgundy automatic gradient fill, one JudgeBust layer, a neutral
  0.25 shadow annotation, and 0.12 translucency.

Icon Composer previews were visually checked in Default, Dark, and Mono modes. The
source is intentionally one image layer plus Composer's background fill, mirroring
the proven FavRes package structure and keeping project weight low.

IconComposer-Sources also contains explicit default, dark, and mono PNG sources for
future manual annotation or replacement.

## Contact sheets

- ContactSheets/judge-poses.png: Welcome, Verdict, Appeal.
- ContactSheets/dishes-grid.png: Treat, Balanced, Light rows.
- ContactSheets/on-white.png: all three icon variants, all judge poses, and all nine
  dishes composited on #FFFFFF.
- ContactSheets/on-black.png: the same assets composited on #000000.

No labels were added to contact sheets so the no-text rule remains true for every
image in the handoff.

## Validation

Automated checks passed:

- 59 PNG files.
- PNG, 8-bit, sRGB IEC61966-2.1.
- Exact requested dimensions for all app icon, judge, dish, and master files.
- Alpha present for every judge, dish, master, dark icon, and tinted icon.
- Light app icon is RGB with no alpha channel.
- Icon Composer package opens successfully in Apple's Icon Composer.

Visual checks passed:

- No text, letters, numerals, logos, or trademarked packaging.
- DishTortilla is clearly a Spanish potato omelette with visible potato layers.
- Treat, Balanced, and Light rows share presentation, lighting, and scale.
- The three poses read as the same pizza judge.
- Small-size silhouettes remain distinguishable.
- White and black contact sheets show clear subject separation.

## Xcode integration and size guidance

The Xcode project was intentionally untouched.

Preferred modern integration:

1. Add only Foodge_Icon.icon to the Xcode project for the app icon.
2. Use Judge and Dishes runtime files at the needed scales.
3. Do not add Masters, ContactSheets, IconComposer-Sources, or flattened AppIcon
   compatibility PNGs to the application target.
4. Let Xcode's asset compiler select and package device-appropriate renditions.

Keeping masters and review sheets outside the target prevents the 2048-pixel
production sources from increasing the application bundle.
