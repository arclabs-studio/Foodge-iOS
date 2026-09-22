//
//  DishSelection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 20/09/2026.
//

import Foundation

/// One dish the user was shown on a recent day, kept only long enough to steer the next choice
/// away from a repeat.
///
/// Carries the family alongside the variant id so history stays readable after a catalogue
/// version renames a variant (D39). A parameter rather than a `CaseStore` method: there is no
/// history to read until `DailyCase` lands in WU-21-A, but the rule about *which* history counts
/// belongs with the rule, not with a store that has no conformer yet.
struct RecentDishSelection: Hashable, Sendable {
    let variantID: String
    let family: DishFamily
    let date: Date
}

/// Everything about the user's own state that ``DishSelection`` needs, bundled to keep
/// `select(from:request:on:calendar:)` under the constitution's parameter-count ceiling. `entries`
/// and the clock stay separate top-level parameters: they describe the catalogue and the moment
/// being evaluated, not the user.
struct DishSelectionRequest: Sendable {
    let category: DinnerCategory
    let constraints: DietaryConstraints
    let context: DailyContext
    let favouriteFamilies: [DishFamily]
    let recentSelections: [RecentDishSelection]

    init(
        category: DinnerCategory,
        constraints: DietaryConstraints,
        context: DailyContext,
        favouriteFamilies: [DishFamily] = [],
        recentSelections: [RecentDishSelection] = []
    ) {
        self.category = category
        self.constraints = constraints
        self.context = context
        self.favouriteFamilies = favouriteFamilies
        self.recentSelections = recentSelections
    }
}

/// Everything an appeal's craving negotiation needs, bundled for the same reason
/// ``DishSelectionRequest`` bundles tonight's own pick: keeping
/// `negotiateAppeal(from:request:on:calendar:)` under the constitution's parameter-count ceiling.
struct AppealNegotiationRequest: Sendable {
    let craving: DishFamily
    let constraints: DietaryConstraints
    let context: DailyContext
    let favouriteFamilies: [DishFamily]
    let recentSelections: [RecentDishSelection]

    init(
        craving: DishFamily,
        constraints: DietaryConstraints,
        context: DailyContext,
        favouriteFamilies: [DishFamily] = [],
        recentSelections: [RecentDishSelection] = []
    ) {
        self.craving = craving
        self.constraints = constraints
        self.context = context
        self.favouriteFamilies = favouriteFamilies
        self.recentSelections = recentSelections
    }
}

/// What ``DishSelection`` decided.
enum DishSelectionOutcome: Hashable, Sendable {
    /// A dish to recommend, and — when a second family or variant survived filtering — a
    /// distinct alternative to offer alongside it (D42).
    case selected(recommendation: CatalogueEntry, alternative: CatalogueEntry?)
    /// Nothing in the catalogue satisfies every constraint. Carries the ingredient ids that are
    /// each **individually** sufficient to unblock at least one on-diet candidate — un-excluding
    /// just that one id, with every other exclusion left in place, would let that candidate
    /// through. An id blocking a candidate only *together with* another excluded ingredient is
    /// deliberately left out: naming it would tell the user removing it alone helps, when it
    /// would not. A correct consequence of the user's own choices, not a failure, so nothing
    /// throws here (D43).
    case noMatch(blockingIngredientIDs: Set<String>)
}

/// Picks one dish from the catalogue for tonight, deterministically: the same inputs on the same
/// local date always produce the same dish, which is what lets a saved case be reopened without
/// regenerating anything.
///
/// Flat scalar parameters, not an `EvidenceSnapshot` — `DinnerCategoryRule.decide` takes scalars
/// for exactly this reason: a craving test that first had to build a snapshot would be testing
/// Health plumbing rather than the selection rule. `date` and `calendar` are injected; `Date()`
/// and `.autoupdatingCurrent` appear nowhere here.
enum DishSelection {
    /// The five-key ranking tuple as a named, `Comparable` type rather than a bare tuple — a
    /// tuple this wide is exactly what the constitution's lint gate forbids, and naming each key
    /// makes the priority order ("craving beats convenience beats recency beats favourite beats
    /// rotation") readable at the call site instead of positional.
    private struct RankKey: Comparable {
        let craving: Int
        let convenience: Int
        let recency: Int
        let favourite: Int
        let rotation: Int

        static func < (lhs: RankKey, rhs: RankKey) -> Bool {
            if lhs.craving != rhs.craving {
                return lhs.craving < rhs.craving
            }
            if lhs.convenience != rhs.convenience {
                return lhs.convenience < rhs.convenience
            }
            if lhs.recency != rhs.recency {
                return lhs.recency < rhs.recency
            }
            if lhs.favourite != rhs.favourite {
                return lhs.favourite < rhs.favourite
            }
            return lhs.rotation < rhs.rotation
        }
    }

    static func select(
        from entries: [CatalogueEntry],
        request: DishSelectionRequest,
        on date: Date,
        calendar: Calendar
    ) -> DishSelectionOutcome {
        rank(
            entries: entries,
            initialCandidates: Array(entries.enumerated()).filter { $0.element.category == request.category },
            preferences: RankingPreferences(request),
            on: date,
            calendar: calendar
        )
    }

    /// Negotiates one specific craving for an appeal: searches every family, not just one category
    /// (an appeal may accept a dish from a different category than the ruled one — `foodge-plan.md`
    /// §3), sharing every filtering and ranking rule `select(from:request:on:calendar:)` uses for
    /// tonight's own pick via `rank(entries:initialCandidates:constraints:context:favouriteFamilies:recentSelections:on:calendar:)`
    /// — the only difference is the first-stage filter (family, not category).
    ///
    /// Since every candidate shares `family`, `alternative(to:among:)`'s "different family" branch
    /// always falls through to its "different variant, same family" branch — which is exactly "a
    /// known compatible variant" from the plan's second bullet.
    static func negotiateAppeal(
        from entries: [CatalogueEntry],
        request: AppealNegotiationRequest,
        on date: Date,
        calendar: Calendar
    ) -> DishSelectionOutcome {
        rank(
            entries: entries,
            initialCandidates: Array(entries.enumerated()).filter { $0.element.family == request.craving },
            preferences: RankingPreferences(request),
            on: date,
            calendar: calendar
        )
    }

    /// The fields `select` and `negotiateAppeal` both hand to `rank(entries:initialCandidates:preferences:on:calendar:)`
    /// unchanged — everything about `DishSelectionRequest`/`AppealNegotiationRequest` except the
    /// category/craving each uses for its own first-stage filter.
    private struct RankingPreferences {
        let constraints: DietaryConstraints
        let context: DailyContext
        let favouriteFamilies: [DishFamily]
        let recentSelections: [RecentDishSelection]

        init(_ request: DishSelectionRequest) {
            constraints = request.constraints
            context = request.context
            favouriteFamilies = request.favouriteFamilies
            recentSelections = request.recentSelections
        }

        init(_ request: AppealNegotiationRequest) {
            constraints = request.constraints
            context = request.context
            favouriteFamilies = request.favouriteFamilies
            recentSelections = request.recentSelections
        }
    }

    /// The diet/exclusion filtering and five-key ranking shared by `select` and `negotiateAppeal` —
    /// the only thing that differs between "tonight's own pick" and "an appeal's craving
    /// negotiation" is which entries reach `initialCandidates`, never how they are filtered further
    /// or ranked.
    private static func rank(
        entries: [CatalogueEntry],
        initialCandidates: [(offset: Int, element: CatalogueEntry)],
        preferences: RankingPreferences,
        on date: Date,
        calendar: Calendar
    ) -> DishSelectionOutcome {
        let catalogueCount = entries.count
        let constraints = preferences.constraints

        let onDiet = initialCandidates.filter { $0.element.variant.diets.contains(constraints.profile) }
        let candidates = onDiet.filter { pair in
            constraints.excludedIngredientIDs.isDisjoint(with: pair.element.variant.ingredients.map(\.id))
        }

        guard !candidates.isEmpty else {
            return .noMatch(blockingIngredientIDs: soleBlockers(among: onDiet, excluding: constraints))
        }

        let preferred = preferredConvenience(for: preferences.context)
        let recentWindow = preferences.recentSelections.filter { selection in
            let daysAgo = daysBetween(selection.date, date, calendar: calendar)
            return daysAgo >= 1 && daysAgo <= 3
        }

        func rankKey(_ pair: (offset: Int, element: CatalogueEntry)) -> RankKey {
            let entry = pair.element
            let recency = if recentWindow.contains(where: { $0.variantID == entry.id }) {
                2
            } else if recentWindow.contains(where: { $0.family == entry.family }) {
                1
            } else {
                0
            }
            return RankKey(
                craving: preferences.context.craving == entry.family ? 0 : 1,
                convenience: -entry.variant.convenience.intersection(preferred).count,
                recency: recency,
                favourite: preferences.favouriteFamilies.contains(entry.family) ? 0 : 1,
                rotation: rotatedIndex(
                    catalogueIndex: pair.offset,
                    catalogueCount: catalogueCount,
                    date: date,
                    calendar: calendar
                )
            )
        }

        let ranked = candidates
            .sorted { rankKey($0) < rankKey($1) }
            .map(\.element)

        let recommendation = ranked[0]
        return .selected(recommendation: recommendation, alternative: alternative(to: recommendation, among: ranked))
    }

    /// The ingredient ids each individually sufficient to unblock at least one candidate that
    /// otherwise satisfies category and diet — see ``DishSelectionOutcome/noMatch(blockingIngredientIDs:)``
    /// for why an id blocking a candidate only jointly with another exclusion is left out.
    private static func soleBlockers(
        among onDiet: [(offset: Int, element: CatalogueEntry)],
        excluding constraints: DietaryConstraints
    ) -> Set<String> {
        Set(onDiet.compactMap { pair -> String? in
            let blocking = Set(pair.element.variant.ingredients.map(\.id))
                .intersection(constraints.excludedIngredientIDs)
            return blocking.count == 1 ? blocking.first : nil
        })
    }

    /// Prefers a different family; falls back to a different variant in the same family; `nil`
    /// when only one candidate survives (D42).
    private static func alternative(
        to recommendation: CatalogueEntry,
        among ranked: [CatalogueEntry]
    ) -> CatalogueEntry? {
        guard ranked.count > 1 else { return nil }
        if let differentFamily = ranked.first(where: { $0.family != recommendation.family }) {
            return differentFamily
        }
        return ranked.first(where: { $0.id != recommendation.id })
    }

    private static func preferredConvenience(for context: DailyContext) -> Set<ConvenienceTag> {
        var preferred: Set<ConvenienceTag> = []
        if context.dinnerTime == .quick {
            preferred.formUnion([.quick, .onePan, .noCook])
        }
        if context.energyLevel == .low {
            preferred.formUnion([.onePan, .noCook])
        }
        return preferred
    }

    private static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: from),
            to: calendar.startOfDay(for: to)
        ).day ?? 0
    }

    /// The catalogue index rotated by the number of local days since the reference date, so the
    /// tie-break order shifts by exactly one place per day without ever jumping backwards at a
    /// year boundary (D40). Modded by the full catalogue count, never the candidate count, so
    /// excluding an ingredient never shifts anyone else's rotation.
    static func rotatedIndex(catalogueIndex: Int, catalogueCount: Int, date: Date, calendar: Calendar) -> Int {
        guard catalogueCount > 0 else { return 0 }
        let epoch = calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0))
        let days = daysBetween(epoch, date, calendar: calendar)
        let shifted = (catalogueIndex - days % catalogueCount) % catalogueCount
        return (shifted + catalogueCount) % catalogueCount
    }
}
