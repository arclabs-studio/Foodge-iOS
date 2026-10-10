> **Status: approved by the user on 10 Oct 2026, including the four calls under "Decisions taken
> with the user" and the burgundy re-tint, the `.menu` picker style and D145's reversal of
> "artwork stays subordinate". Start at WU-29-A on `feature/WU-29-playful-redesign`.** A fresh
> session must call `XcodeOpenWorkspace` on `Foodge/Foodge.xcodeproj` before any other Xcode MCP
> tool — that call is what asks the user to approve the agent.
>
> **Read this before taking any work unit.** This plan amends `DESIGN.md` §"Visual identity" and
> the screen table. `DESIGN.md` is updated by this plan (WU-29-G), not before it. **No product
> rule changes**: the category rule, selection order, copy rules and D138/D144 stay exactly as
> they are.
>
> **The two judgement calls everything else follows from:**
> 1. **Colour goes into backgrounds, the hero and the stamps — text always sits on a system surface
>    or on a measured "On" pair.** That is how the app gets louder without a single contrast
>    regression.
> 2. **Every new interaction is decoration.** Tapping the judge, the reveal, the confetti — none of
>    them can reach the rule, the dish or the diet. If a future idea would widen the set of dishes
>    the person can reach, it is the thing this app was rejected for (D138, D144).

# Foodge — a playful, game-like look on native SwiftUI

## Context

Foodge works, but it looks like Settings. Today and the verdict are `Form`s, the judge renders at
76 pt and the dishes at 64 pt, and the palette is a muted burgundy/gold. The 3D artwork, the best
asset the app has, is tucked into a row.

The goal: an app that feels closer to a game than to a utility — large, animated, tappable
characters, brighter colours — **while following Apple's HIG and using only native SwiftUI**.

### Decisions taken with the user (9 Oct 2026)

| # | Decision |
|---|---|
| 1 | **Palette: hybrid.** Burgundy and gold stay as the brand (the judge's robe), made more vivid. The pizza colours — tomato, cheese, basil, dough — join as supporting and category colours. |
| 2 | **Animation: the existing artwork, animated in SwiftUI.** No new assets. Layered artwork (separate gavel, blink) may come later and must slot in without rework. |
| 3 | **Scope: practically the whole app**, guided by the HIG. Ritual screens become a stage; data-entry and settings screens stay `Form` and inherit the palette and type. |
| 4 | **Layout: stage + cards** for Today and the verdict — a native `ScrollView` with a large hero and `GroupBox` cards. |

## Acceptance criteria (verifiable)

1. The judge renders at **≥ 180 pt** on Welcome, Today and the loading state at default Dynamic
   Type; the verdict's dish renders at **≥ 200 pt**.
2. Tapping the judge plays a hop, a haptic, and shows a quip in a speech bubble. The quip is
   announced to VoiceOver. Nothing about the verdict, the dish or the stored data changes.
3. A new verdict plays a reveal **once per revision**: stamp slam → dish pop → confetti → cards.
   Returning from Evidence details does not replay it.
4. With **Reduce Motion** on: no idle motion, no hop, no confetti, no slam — everything arrives as
   an opacity change. Verified in a preview that forces it, or on the simulator.
5. Every text/background pair in the new palette measures **≥ 4.5:1** in all four appearances, and
   a test reading the shipped colour sets fails if any pair drops below.
6. **AX5** in English and Spanish: no truncation, no overlap; hero art shrinks, cards stack.
7. Zero warnings, full suite green, `arc-audit-hig` and `arc-audit-accessibility` with **0
   BLOCKER** on every unit that touches UI.
8. No `.glassEffect` on content; no custom tab bar, toolbar, picker or font file; no hex/RGB
   literal in code.

## Design system

### Palette (all in `Assets.xcassets/Colors`, four appearances each)

Values were measured with the WCAG 2.x relative-luminance formula against white, black,
`secondarySystemGroupedBackground` (`#FFFFFF` / `#1C1C1E`) and `AppDough`.

| Colour set | Light | Dark | HC light | HC dark | Role |
|---|---|---|---|---|---|
| `AppBurgundy` *(changed)* | `#A3173F` | `#FF8FAB` | `#7A0F2E` | `#FFB8CA` | Brand, tint, text-capable |
| `AccentColor` *(changed)* | = AppBurgundy | | | | System tint |
| `AppOnBurgundy` *(changed)* | `#FFFFFF` | `#2A0A14` | `#FFFFFF` | `#1A050C` | Label on a burgundy fill |
| `AppBurgundyMuted` *(changed)* | `#8E3A55` | `#E3A3B6` | `#6E2440` | `#F2C4D2` | Secondary text (D134 role kept) |
| `AppGold` *(changed)* | `#F2B200` | `#FFC83D` | `#D19A00` | `#FFD76E` | Decoration only — sparkles, confetti, the gavel ring. **Never text, never the only carrier of meaning** |
| `AppTomato` *(new)* | `#D7311F` | `#FF6B57` | `#B8281B` | `#FF8E7E` | Treat |
| `AppOnTomato` *(new)* | `#FFFFFF` | `#2B0703` | `#FFFFFF` | `#1A0402` | Label on tomato |
| `AppCheese` *(new)* | `#FFBE2E` | `#FFC94D` | `#FFB000` | `#FFD670` | Balanced |
| `AppOnCheese` *(new)* | `#3D2200` | `#3D2200` | `#2A1700` | `#2A1700` | Label on cheese |
| `AppBasil` *(new)* | `#1F8244` | `#4CC774` | `#1A6E3A` | `#7BDB98` | Light |
| `AppOnBasil` *(new)* | `#FFFFFF` | `#06240F` | `#FFFFFF` | `#031A0A` | Label on basil |
| `AppDough` *(new)* | `#FFF4E2` | `#24170F` | `#FFF8EC` | `#1A100A` | Stage background veil |

Measured minimums across the four appearances: Burgundy text **6.84**, BurgundyMuted **6.52**,
OnBurgundy/Burgundy **7.63**, OnTomato/Tomato **4.83**, OnCheese/Cheese **8.87**, OnBasil/Basil
**4.84**, primary label on Dough **17.44**.

> **Corrected in WU-29-A.** The 6.84 / 6.52 minimums are on `systemGroupedBackground`; at the top of
> a stage, where the accent wash is strongest, burgundy text bottoms out at **5.41** and
> burgundy-muted at **5.16** (both light, burgundy stage). `PaletteContrastTests` holds the measured
> table now, and a card fill (`AppCard`) was added after `arc-audit-hig` — see D145.

**Known, accepted:** cheese and gold fail 3:1 as *shapes* against light surfaces (1.5–1.8:1). Neither
is ever the sole carrier of meaning — the stamp's meaning is its text and symbol, which meet 4.5:1
against the fill — so WCAG 1.4.11 does not apply. Recorded as part of D145.

### Typography

`.fontDesign(.rounded)` once at the root (`AppRootView`). Semantic styles only. The category stamp
uses `.largeTitle.weight(.black)`, with `.fontWidth(.expanded)` if the preview shows it has an
effect on the rounded face. No `.system(size:)`, no custom font file.

### Surfaces

- **Stage screens** sit on `StageBackground`: `AppDough` plus a soft gradient of the screen's
  accent (burgundy on Today/Welcome, the category colour on the verdict) at low opacity.
  Opaque, so Reduce Transparency has nothing to remove.
- **Cards** are native `GroupBox` with a `StageCardGroupBoxStyle`:
  `secondarySystemGroupedBackground`, continuous corner radius 24. Text inside them is on a
  system surface, so system label colours keep their guaranteed contrast.
- **No Liquid Glass on content** (HIG: glass belongs to the navigation and control layer). Glass
  arrives only through native toolbars, the tab bar and, where the API allows, the prominent
  button style.

### Motion policy (D147)

| Motion | Default | Reduce Motion |
|---|---|---|
| Judge idle "breathing" (scale 1 → 1.03, slight tilt) | `keyframeAnimator(repeating: motion)`; the screen stops it once a verdict is requested | none |
| Judge tap hop (squash → jump → land) | `keyframeAnimator(trigger:)` + `.sensoryFeedback(.impact, trigger:)` | haptic only, quip still shown |
| Stamp slam (scale 2.2 → 1, rotate −8°) | keyframes, heavy impact haptic | fade in |
| Dish pop | spring, bounce 0.4 | fade in |
| Confetti | `Canvas` + `TimelineView(.animation)`, ~2.5 s, then paused and removed | not rendered |
| Card entrance | staggered offset + opacity | opacity only |
| Dish swap (See alternative) | scale + crossfade | crossfade |

All artwork stays `accessibilityHidden(true)` except the judge, which becomes a button.

## Components (new files, one type each)

| File | Purpose |
|---|---|
| `Presentation/Components/Stage/StageBackground.swift` | The dough veil plus accent gradient. Takes a `Color` accent. |
| `Presentation/Components/Stage/StageCardGroupBoxStyle.swift` | The card look on native `GroupBox`. |
| `Presentation/Components/Judge/JudgeHeroView.swift` | Large judge as a `Button` with idle animation, hop, haptic and quip bubble. Replaces `JudgeBadgeView` on stage screens; `JudgeBadgeView` stays for small uses. |
| `Presentation/Components/Judge/JudgeButtonStyle.swift` | Squash-on-press `ButtonStyle` (native press state, no gesture). |
| `Presentation/Components/Judge/JudgeReaction.swift` | `@Observable @MainActor` component model: which quip is showing, how many taps, deterministic rotation. **Unit-tested.** |
| `Presentation/Components/Judge/SpeechBubble.swift` | The quip bubble (a `Shape` + `Text`). Reused by the verdict flourish. |
| `Presentation/Components/Verdict/CategoryStampView.swift` | Rubber stamp: category colour fill, On-colour text, SF Symbol. |
| `Presentation/Components/Verdict/DishHeroView.swift` | Large dish art with pop/float. Wraps `DishArtworkView`'s family → image mapping (that mapping stays the single source, D60). |
| `Presentation/Components/Verdict/ConfettiView.swift` | Finite particle burst in the category palette. |
| `Presentation/Localization/DinnerCategory+Appearance.swift` | `tint`, `onTint`, `symbolName` — display helpers, not logic. |
| `Presentation/Localization/JudgeQuip.swift` | The bilingual quip deck as `LocalizedStringResource`s. |

### The judge's quips (new copy, EN source + ES)

Six to eight lines, written to D118/D119: about the *case* or the court, never the person's body,
discipline or worth; no numbers; no instruction to eat or skip anything. Spanish register: warm,
slightly formal courtroom. Examples to be finalised in WU-29-B:

- "Order in the kitchen!" / «¡Orden en la cocina!»
- "The court does not accept bribes. Unless it's garlic bread." / «Este tribunal no acepta sobornos. Salvo pan de ajo.»
- "Objection noted. And overruled." / «Protesta anotada. Y denegada.»

## Screen by screen

| Screen | Treatment |
|---|---|
| **Root** | `.fontDesign(.rounded)`; tint comes from `AccentColor`. Tab bar stays native. |
| **Welcome** | Stage. `JudgeHeroView` (welcome pose) ~220 pt, interactive. Title and sentence below; prominent extra-large Continue. Keeps the AX-size inline-button fallback already there. |
| **Health connection** | `Form` kept (permission explanation + per-kind results are list content). A clear hero section at the top with the judge at ~120 pt; `StageBackground` behind the form via `.scrollContentBackground(.hidden)`. |
| **About you** (body basics) | `Form` kept — data entry. Tint, rounded type and stage background only. |
| **Today, before verdict** | Stage + cards. Hero judge (interactive), one-line intro, **Eaten so far** card with the three native `Picker`s (style changes from `.navigationLink` to `.menu`, because a navigation-link picker needs a list container), self-report card with large native buttons, failure card, and a big prominent **Give me a verdict** pinned with `safeAreaInset` (inline at AX sizes, the Welcome pattern). |
| **Loading** (`CourtLoadingView`) | The judge "deliberating": a repeating gavel-tap tilt. Native `ProgressView` kept as the accessible status. |
| **Verdict** | Stage tinted by category. Reveal: `CategoryStampView` slams in → `DishHeroView` pops → `ConfettiView` → cards (dish name + family, **Why** with the disclaimer, the judge's flourish in a `SpeechBubble`, See alternative, Evidence details, save-failure + retry). Reveal plays once per revision — `TodayViewModel` records the last revealed revision id. |
| **Evidence details** | `Form`, unchanged except palette and type. |
| **History** | Native `List` kept. Rows gain the dish art (~56 pt), the date and a mini category stamp. Empty state stays `ContentUnavailableView`, with the judge image as its icon. |
| **Case detail** | Static version of the verdict hero (stamp + dish, no reveal, no confetti) at the top of the existing `Form`. |
| **Settings, Demonstration** | `Form`, unchanged except palette and type. |

## Work units

Each unit closes on the `foodge-verify` sequence: zero-warning build (`GetBuildLog` at
`severity: "warning"` → `totalFound: 0`), tests green, previews rendered (light, dark, increased
contrast, AX5, `es`). Then `arc-verify-ui`, `arc-audit-hig`, `arc-audit-accessibility` and
`arc-constitution-review`, each told to check **whether every test could actually fail, and whether
any comment, doc or ledger entry claims more than the code does**.

| Unit | Deliverable | Tests first (`arc-test-engineer`) |
|---|---|---|
| **WU-29-A** Foundations | Branch `feature/WU-29-playful-redesign` off `develop`. Colour sets (5 changed, 7 new), `DinnerCategory+Appearance`, `StageBackground`, `StageCardGroupBoxStyle`, rounded type at the root. Ledger **D145**. | `PaletteContrastTests`: resolves each shipped colour set in four trait collections and asserts every declared text pair ≥ 4.5:1 against an independent WCAG implementation. Must fail if a value is darkened/lightened past the floor. |
| **WU-29-B** The judge | `JudgeHeroView`, `JudgeButtonStyle`, `JudgeReaction`, `SpeechBubble`, quip deck EN + ES. Ledger **D146**. | `JudgeReactionTests`: the first tap shows quip 0; taps rotate deterministically; the deck wraps; a quip is never repeated twice in a row. |
| **WU-29-C** Today + loading | `TodayBeforeVerdictView` to stage + cards; `CourtLoadingView` deliberating. | None new — view-only. Existing `TodayViewModelTests` must stay green. |
| **WU-29-D** Verdict reveal | `CategoryStampView`, `DishHeroView`, `ConfettiView`, `VerdictView` to stage; reveal-once. Ledger **D147** (motion policy). | `TodayViewModelTests` additions: `shouldPlayReveal` is true on the first ask for a revision, false after, true again for a new revision; survives the evidence push/pop. |
| **WU-29-E** Welcome + onboarding | Welcome stage; hero section on Health connection; palette on About you. | None new. |
| **WU-29-F** History + case detail | Rich rows, judge empty state, static hero on case detail. | None new. |
| **WU-29-G** Close | Palette pass on Settings, Evidence, Demonstration; `DESIGN.md` §"Visual identity" rewritten; fresh-install walk on the simulator in both languages, light and dark. | Full suite (⌘U by hand if the MCP runner wedges again). |

### New numbered decisions

- **D145** — Visual identity v2: the hybrid palette and its contrast table, rounded type, stage +
  cards for ritual screens, `Form` kept for data entry and settings. Supersedes `DESIGN.md`'s
  "artwork stays subordinate" line for stage screens: the artwork leads, the dinner name and the
  primary action stay the largest *text* on screen.
- **D146** — The judge is tappable. Quips are decoration with the same voice rules as the flourish;
  they never touch the rule, the dish or stored data.
- **D147** — Motion policy (table above), Reduce Motion behaviour, reveal once per revision.

## Out of scope

New artwork or poses, sound effects, a custom tab bar, custom fonts, an iPad layout, changes to
the app icon, any product rule.

## Risks

- **The MCP test runner wedges** (WU-27-A, WU-28-C). Probe with one test first; fall back to ⌘U by
  hand and record the number.
- **RenderPreview snapshots before `.task` completes** (the verdict preview renders a spinner).
  Components take an explicit `revealed` input so previews can render the settled end state.
- **Reduce Motion cannot be chosen as a RenderPreview variant, and the environment value is
  get-only.** Components take `motion: Bool`; previews render both states; the simulator walk
  checks the real setting once.
- **Idle animation energy.** Idle motion stops after a few cycles; confetti pauses its timeline
  when finished.

## API verification (9 Oct 2026)

Every API checked against Apple's own documentation (apple-docs / cupertino MCPs, HIG, WWDC
sample code). Target iOS 26.0 — everything below is available.

| API | Min iOS | Consequence for this plan |
|---|---|---|
| `phaseAnimator(_:trigger:content:animation:)` | 17 | Used for the **triggered** judge idle. The continuous variant has **no pause parameter**, so it is not used — Reduce Motion would need a conditional modifier, which the doctrine forbids. |
| `keyframeAnimator(initialValue:repeating:content:keyframes:)` / `(…trigger:…)` | 17 | Hop, slam, deliberating tilt. `repeating: !reduceMotion` is the built-in off switch. **Its `content` closure is `@Sendable`**: copy any main-actor value into a `let` before the closure. |
| `sensoryFeedback(_:trigger:)` | 17 | `.impact` and `.success` confirmed. `.impact(weight: .heavy)` **not found** in the docs — use the confirmed cases only. |
| `GroupBoxStyle` | 14 | The card style. Declare the conformance on the type, not in an extension, so it keeps `@MainActor`. |
| `ControlSize.extraLarge` | 17 | **Sources disagree** — the symbol page says it resolves to `.large` outside visionOS; WWDC25 says iOS 26 supports it. Check in a preview; `.large` is the fallback. |
| `.buttonStyle(.glassProminent)` + `.tint` | 26 | Allowed on the primary **button** (a control). Apple's sample tints it with `.tint`. Contrast of its label is measured in the preview. |
| `Canvas` + `TimelineView(.animation(minimumInterval:paused:))` | 15 | Confetti. `paused: true` once the burst ends; `.accessibilityHidden(true)`. |
| `fontDesign(.rounded)` | 16.1 | Applied at the root. Dynamic Type retention is inferred from `Font` being late-binding — **verified at AX5 in the previews**. |
| `fontWidth(.expanded)` | 16 | May not produce an expanded *rounded* face. Checked visually; dropped if it does nothing. |
| `accessibilityReduceMotion` / `ReduceTransparency` | 13 | **Get-only**, so no preview can inject them. Components therefore take a `motion: Bool` input, read once from the environment by the screen; previews render both values directly. |
| `MeshGradient` | 18 | Not documented as `Animatable`. `StageBackground` uses it **static**. |
| `symbolEffect(.bounce / .wiggle / .breathe, value:)` | 17 / 18 | Stamp symbol bounce on reveal. |
| `spring(duration:bounce:)`, `.bouncy`, `.snappy` | 17 | Pops and entrances. |
| `contentTransition(.numericText())` | 16 | Not needed — no animated figures. |
| `backgroundExtensionEffect()` | 26 | **Not used** — meant for split-view detail columns. |
| HIG › Materials | — | "Don't use Liquid Glass in the content layer." Cards use `secondarySystemGroupedBackground`. |
