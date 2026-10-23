> **Status: planned on 23 Oct 2026; the strategy was decided on 22 Oct 2026, from the owner's
> private monetization study, which is not in this repository. Figures taken from it (the ads
> estimate in D152, the thresholds in D159) are the owner's estimates. Decisions D152–D161 are recorded in
> `docs/implementation-tasks.md`, and the work units are WU-30-0 → WU-30-I in its section
> "Post-launch — monetization Phase 0 (WU-30)". Questions Q1–Q7 below are open: they are
> recorded with a recommendation each and are not decided.**
>
> **The judgement call everything follows from: monetization may never reach the rule or the
> dish.** Entitlement is derived (D161), and a pack widens the pool, never the person's choice
> (D138, D156). If a future idea lets money change what the person eats tonight, it is the thing
> this app was rejected for once already.

# Foodge — monetization Phase 0

## Context

Foodge has left the hackathon and is on TestFlight (`0.1.0`, `beta/20261015-4`). The strategy:
no ads, a free app plus a Foodge+ non-consumable, a tip jar, raw StoreKit 2, and widgets and App
Intents on the roadmap. This document turns that into an architecture, a verified set of Apple
facts, and the open questions. It was written as documentation only: no Swift, no
`project.pbxproj`, no `.xcstrings`.

## Decisions

| # | Decision (summary — the ledger has the full text and rationale) |
|---|---|
| D152 | No ads, ever. No ad SDK, no affiliate links. Only packaged editorial sponsorship shipped in an update, considered from about 5k MAU. |
| D153 | Free app + one non-consumable "Foodge+" (3.99 € at launch → 4.99 €) + a tip jar. No subscription; "Foodge Chef" is reconsidered at the 90-day review only as an extra tier. |
| D154 | Raw StoreKit 2, Apple frameworks only. No RevenueCat, no ARCPurchasing. |
| D155 | The free tier is complete: verdict, dish, evidence, 7-day history, standard judge, flourish, one small widget, the "What's for dinner?" intent. **History beyond 7 days hides, never deletes.** |
| D156 | Foodge+ unlocks packs, alternative judges and icons, the full case file, extra and Lock Screen widgets, a Watch complication and a Live Activity. **A pack joins the pool automatically; no per-pack toggle.** |
| D157 | Tip jar "bribe the judge": three consumables (0.99 / 2.99 / 4.99 €), cosmetic reward only, derived from `Transaction.all` with `SKIncludeConsumableInAppPurchaseHistory`. |
| D158 | Widgets, App Intents, Siri and Shortcuts in scope. **The widget reads an App Group snapshot file, never the store.** No Health figures in it. |
| D159 | Phases 0–3 and the 90-day gate, measured with App Store Connect Analytics and sales reports only. |
| D160 | Defect: "avoid the last three days" was never wired into `TodayViewModel.finish`. Fixed first, in WU-30-0. |
| D161 | Entitlement is derived from `Transaction.currentEntitlements` + `Transaction.updates`, never persisted. |

### Contradictions found and settled with the user (23 Oct 2026)

| Found | Evidence | The user's call |
|---|---|---|
| "Avoid the last three days" is **not wired** in the app | `TodayViewModel.finish` (`Presentation/Features/Today/TodayViewModel.swift:391`) builds `DishSelectionRequest` without `recentSelections`, so it defaults to `[]`. Only `DishSelectionTests` exercise it. CLAUDE.md and D139 describe it as live. | Bugfix unit **first** (WU-30-0), before any pack |
| History has **no 7-day limit** today | `PersistenceActor.allCases()` has no `fetchLimit`, and nothing prunes | The free tier **hides, never deletes**. The store keeps every case. |
| Widget data source vs the `.completeUnlessOpen` store (D29, D107) | The store is in the app container with no App Group, and HealthKit data is unavailable while the device is locked | The widget reads a small App Group **snapshot file**. The store does not move. |
| "Rigged verdict" vs D138 ("any new control that shapes the dish…") | CLAUDE.md product rule | Kept as open question Q1, flagged as a rule conflict |

## Verified Apple facts

Checked on 23 Oct 2026 against Apple's pages. **Confirmed** = the source says it. **Unverified** =
no Apple source found; the unit that depends on it starts by finding out. **Inference** = our reading
of several sources together, labelled as such.

### StoreKit 2

| Fact | Status | Source |
|---|---|---|
| `Product.products(for:)` (iOS 15+) | Confirmed | [products(for:)](https://developer.apple.com/documentation/storekit/product/products(for:)) |
| `Product.purchase(options:)` is `@MainActor` | Confirmed | [purchase(options:)](https://developer.apple.com/documentation/storekit/product/purchase(options:)) |
| `@Environment(\.purchase)` / `PurchaseAction` (iOS 17+), preferred in SwiftUI | Confirmed | [PurchaseAction](https://developer.apple.com/documentation/storekit/purchaseaction) · [EnvironmentValues.purchase](https://developer.apple.com/documentation/swiftui/environmentvalues/purchase) |
| `Transaction.currentEntitlements` excludes refunded/revoked products and consumables | Confirmed — *"Products that the App Store has refunded or revoked don't appear in the current entitlements. Consumable … In-App Purchases also don't appear"* | [currentEntitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements) |
| `Transaction.updates`, `.unfinished`, `.all`, `finish()`, `revocationDate` | Confirmed | [updates](https://developer.apple.com/documentation/storekit/transaction/updates) · [unfinished](https://developer.apple.com/documentation/storekit/transaction/unfinished) · [all](https://developer.apple.com/documentation/storekit/transaction/all) · [finish()](https://developer.apple.com/documentation/storekit/transaction/finish()) · [revocationDate](https://developer.apple.com/documentation/storekit/transaction/revocationdate) |
| `AppStore.sync()` only behind an explicit user action (Restore) | Confirmed — *"Call this function only in response to an explicit user action, like tapping or clicking a button."* (an Important aside; it shows in the page's raw doc JSON) | [AppStore.sync()](https://developer.apple.com/documentation/storekit/appstore/sync()) |
| `AppTransaction.shared` (iOS 16+) | Confirmed | [AppTransaction.shared](https://developer.apple.com/documentation/storekit/apptransaction/shared) |
| `StoreView` / `ProductView` (iOS 17+) | Confirmed. Apple declares both `@preconcurrency`, which is Apple's annotation, not ours | [StoreView](https://developer.apple.com/documentation/storekit/storeview) · [ProductView](https://developer.apple.com/documentation/storekit/productview) |
| `.storeButton(.visible, for: .restorePurchases)` works only in `StoreView` / `SubscriptionStoreView` | Confirmed — *"This button type is available for StoreView and SubscriptionStoreView only."* So a `ProductView` sheet needs our own Restore button | [StoreButtonKind.restorePurchases](https://developer.apple.com/documentation/storekit/storebuttonkind/restorepurchases) |
| `.onInAppPurchaseCompletion` with no handler → successes arrive through `Transaction.updates` | Confirmed | [onInAppPurchaseCompletion(perform:)](https://developer.apple.com/documentation/swiftui/view/oninapppurchasecompletion(perform:)) |
| `SKIncludeConsumableInAppPurchaseHistory` puts finished consumables in `Transaction.all` (iOS 18+) | Confirmed; it also covers `latest(for:)` and `Product.latestTransaction` | [SKIncludeConsumableInAppPurchaseHistory](https://developer.apple.com/documentation/bundleresources/information-property-list/skincludeconsumableinapppurchasehistory) |
| `SKTestSession`; tests that reconfigure it must run serially | Confirmed | [SKTestSession](https://developer.apple.com/documentation/storekittest/sktestsession) |
| `SKTestSession` used from **Swift Testing** | **Unverified** — no Apple page mentions it. WU-30-A starts with a spike (`.serialized` suite) | — |

### Privacy label and App Review

| Fact | Status | Source |
|---|---|---|
| *"'Collect' refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it…"*; *"You are not responsible for disclosing data collected by Apple"*; payment info entered outside the app *"is not collected and does not need to be disclosed"* | Confirmed. The page has **no IAP-specific statement**, and *Purchase History* is still a data type on it | [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) |
| "Data Not Collected" holds with StoreKit purchases as long as Foodge runs no server and receives nothing | **Inference** from the three quotes above, not an Apple statement. Re-check at WU-30-H | — |
| 3.1.1: tips through IAP allowed; restore needed for *restorable* purchases (so not for consumable tips) | Confirmed | [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) |
| 2.5.1: mention HealthKit integration in the app description | Confirmed | same |
| 2.5.18: no targeted or behavioural advertising based on health data | Confirmed | same |
| 5.1.2(vi): HealthKit data may not be used for marketing, advertising or use-based data mining | Confirmed | same |
| 5.1.3(i): disclose the health data collected; (ii): no false data into HealthKit, no personal health information in iCloud | Confirmed | same |
| HealthKit use must be clear *"in both your marketing text and your user interface"* | Confirmed | [Protecting user privacy](https://developer.apple.com/documentation/healthkit/protecting-user-privacy) |
| The HealthKit store is encrypted while the device is locked | Confirmed | same |

### Widgets, App Intents, icons

| Fact | Status | Source |
|---|---|---|
| Extension data protection through `com.apple.developer.default-data-protection` | Confirmed (the entitlement page only says to enable Data Protection) | [default-data-protection](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.default-data-protection) |
| Widgets under Complete / CompleteUnlessOpen: *"WidgetKit hides these widgets' content when the device is passcode locked…"* | Confirmed — from **Apple Platform Security**, not the developer docs | [Apple Platform Security — WidgetKit](https://support.apple.com/en-ca/guide/security/secbb0a1f9b4/web) |
| `supportedModes` / `IntentModes` (iOS 26); `openAppWhenRun` deprecated in 26.0 | Confirmed — *"This property is deprecated. Use supportedModes instead."* | [supportedModes](https://developer.apple.com/documentation/appintents/appintent/supportedmodes) · [IntentModes](https://developer.apple.com/documentation/appintents/intentmodes) · [openAppWhenRun](https://developer.apple.com/documentation/appintents/appintent/openappwhenrun) |
| `IntentDialog` / snippet forms on iOS 26; authentication policy for running while locked | **Unverified** — WU-30-G inputs, checked before code | — |
| `setAlternateIconName(_:completionHandler:)`; `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS`, `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` | Confirmed. UIKit with no SwiftUI replacement — a documented exception | [setAlternateIconName](https://developer.apple.com/documentation/uikit/uiapplication/setalternateiconname(_:completionhandler:)) · [Build settings reference](https://developer.apple.com/documentation/xcode/build-settings-reference) |

### Admin

| Fact | Status | Source |
|---|---|---|
| Paid Apps Agreement required to sell apps or offer IAP | Confirmed for paid IAP (Foodge's case) | [Sign and update agreements](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/) |
| Small Business Program: 15 % commission (≤ 1M USD proceeds) | Confirmed | [Small Business Program](https://developer.apple.com/app-store/small-business-program/) |
| EU: 26 % standard commission for apps using IAP, effective 1 Oct 2026 (15 % for Small Business Program members) | Confirmed | [Apps in the EU](https://developer.apple.com/support/apps-in-the-eu/) · [Apple Newsroom, Aug 2026](https://www.apple.com/newsroom/2026/08/apple-announces-changes-for-apps-in-the-european-union/) |

## Architecture (built in WU-30-A unless stated)

- **Domain** (Foundation only): an enum `FoodgeFeature` and a value `Entitlements` (owned features
  plus tip history as `[TipRecord(day, tier)]`). Protocol `EntitlementProviding: Sendable`:
  `current() async -> Entitlements`, `updates() -> AsyncStream<Entitlements>`,
  `restore() async throws`. Gating rules are pure Domain functions:
  `HistoryWindow.visible(cases:entitlements:today:calendar:)` (WU-30-D) and
  `DishCatalogue.entries(for: entitlements)` for selection (WU-30-F), while name lookup always uses
  the full catalogue, so a past pack dish still renders after a refund.
- **Data:** `actor StoreKitEntitlementService` maps verified transactions to `Entitlements`, owns the
  `Transaction.updates` listener task, finishes transactions, and implements Restore with
  `AppStore.sync()`. Other implementations: `DemonstrationEntitlements` (fixed per scenario,
  purchases off), `PreviewEntitlements`, and the test `FixtureEntitlements` (an actor, D11).
- **Composition root:** `AppDependencies` gains `entitlements`. `AppLaunch` starts the listener
  once, for the live session only.
- **Presentation:** `ProductView` / `StoreView` import StoreKit in Presentation only; view models
  see the protocol. Any `@preconcurrency` inside Apple's own declarations is Apple's, not ours, and
  does not breach the rule against writing it.
- **Schema:** packs, the case file, streaks, summaries and the tip seal are all **derived and need
  no schema change**. Only the **selected judge** needs persistence. TestFlight testers hold V1
  stores, so this is the first real **`FoodgeSchemaV2`** (a lightweight added optional,
  `selectedJudgeRawValue: String?`), with a migration test from a V1 store fixture. That is a
  constitution requirement, and D10/D140 (rewrite V1 in place) no longer apply. V2 lands in
  WU-30-E only.
- **Widget (WU-30-G):** the app writes a `Codable` snapshot — local day, category, dish ID,
  provenance label — to an App Group container after a saved verdict. The extension reads only
  that file, links no HealthKit, and does not default to MainActor isolation.

## Work units

The ledger holds the six-field units. In order: **WU-30-I (admin, start now, in parallel) →
WU-30-0 recency → A StoreKit foundation → B Foodge+ sheet and Restore → C tip jar → D case file →
E judge + icon / F first pack → G free widget + intent → H listing and privacy.** Phases 1–3 are
stubs there.

## Open questions for the user

Each has a recommendation. None is decided.

1. **Rigged verdict.** It conflicts with D138 and with the transparency promise; it is
   pay-to-pick-food; and the evidence screen would show a verdict that the dish contradicts.
   **Recommendation: no.** If wanted, make it a purely cosmetic "bribe accepted" stamp on the real
   verdict, which leaves the dish unchanged.
2. **Launch Foodge+ features, ranked by value/effort.** (1) The full case file + streaks: low
   effort, no art. (2) An extra plant-based pack as variants in existing families: low–medium, no
   new artwork. (3) One alternative judge + matching icon: medium–high — 2 artworks, 8 quips and 3
   templates × 2 languages, a persona, and the **first V2 migration**. **Recommendation: case file +
   plant-based pack + alternate icons at launch, the judge first in Phase 1.** The user's hypothesis
   (pack + judge + history) is viable if the artwork exists.
3. **Packs vs the selection rules.** A pack can be **partial** (for example, only Balanced and
   Light), because the invariant is tested over the base catalogue and over base + each pack, and the
   base stays complete alone. It joins the pool automatically (no toggle, D138). Recency and rotation
   run over the entitled pool — **but which count rotation is taken modulo is Q7, not settled
   here.** New *families* need artwork and a `DishFamily` case, so they are not
   the launch pack. **Recommendation: as written.**
4. **Refund / revocation.** Derived entitlement locks features at the next update. Nothing is
   deleted: history beyond 7 days is hidden, the stored judge selection is kept but renders as the
   standard judge, past pack dishes still display, future picks exclude the pack, the icon resets to
   the primary at launch, extra widgets show a "Foodge+" placeholder, and the seal is removed for
   revoked tips. **Recommendation: exactly this.**
5. **Demonstration mode entitlement.** **Recommendation:** demonstration mode shows the Foodge+
   features unlocked, as a showcase, with every purchase and tip UI hidden. It never touches StoreKit.
6. **Lock Screen widget protection (Phase 1).** Under `CompleteUnlessOpen` widget content is
   redacted while the phone is locked. The alternative is a weaker protection class on the snapshot
   file only, which holds a category and a dish name and no figures. **Decide before that unit;**
   no recommendation yet beyond "do not weaken it by default". The free Home Screen widget's
   snapshot is written `.completeUnlessOpen` and backup-excluded (WU-30-G), like the store.
7. **Rotation modulus once packs exist** (raised by `arc-constitution-review`). D40 takes rotation
   modulo the **full catalogue count**, never the candidate count, so that an unrelated change
   never shifts everyone's pick. With packs, the "full catalogue" grows when a pack ships, and the
   entitled pool changes on a purchase or a refund. Options: (a) modulo the **base** catalogue
   count only, so purchases and refunds never move the base rotation; (b) modulo the full catalogue
   including every pack, owned or not, accepting one shift per pack release; (c) amend D40 to the
   entitled-pool count, accepting a shift on every purchase and refund. **Recommendation: (b)** —
   it keeps D40's intent (a purchase or refund never moves the pick) and a release-time shift is
   rare and explainable. Needs a new D-number before WU-30-F.

## Proposed README wording (applied in WU-30-H, not now)

> Foodge has **no networking code of its own**: no analytics, no accounts, no backend. Purchases
> and tips go through Apple's StoreKit, which talks to the App Store on Foodge's behalf. Foodge
> never sees payment details and sends nothing anywhere. App Store privacy label: **Data Not
> Collected.**

"Known limits" also loses "no widgets" once WU-30-G ships.
