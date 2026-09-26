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
/// version renames a variant (D39).
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
    let recentSelections: [RecentDishSelection]

    init(
        category: DinnerCategory,
        constraints: DietaryConstraints,
        recentSelections: [RecentDishSelection] = []
    ) {
        self.category = category
        self.constraints = constraints
        self.recentSelections = recentSelections
    }
}

/// The dish Foodge chose, and the runner-up when one survived filtering.
///
/// A struct rather than the old two-case enum: with per-ingredient exclusions gone (D138) the
/// only filter left is the diet profile, and every category carries at least one variant for
/// every profile — an invariant `DishCatalogueTests` now pins, because a rule that cannot fail
/// must be guarded by something that can. The honest no-match it replaces existed to report an
/// exclusion conflict, and there are no exclusions to conflict (D139).
struct DishSelectionResult: Hashable, Sendable {
    /// What the judge names tonight.
    let recommendation: CatalogueEntry
    /// A distinct second dish to show alongside it, or `nil` when only one candidate survived
    /// (D42). Not a choice put to the user — the recommendation stands on its own.
    let alternative: CatalogueEntry?
}

/// Picks one dish from the catalogue for tonight, deterministically: the same inputs on the same
/// local date always produce the same dish, which is what lets a saved case be reopened without
/// regenerating anything.
///
/// Flat scalar parameters, not an `EvidenceSnapshot` — `DinnerCategoryRule.decide` takes scalars
/// for exactly this reason. `date` and `calendar` are injected; `Date()` and
/// `.autoupdatingCurrent` appear nowhere here.
enum DishSelection {
    /// The two-key ranking tuple as a named, `Comparable` type, so the priority order
    /// ("recency beats rotation") reads at the call site instead of positionally.
    ///
    /// It used to have five keys. Craving, convenience and favourite all left with D139: each of
    /// them was a way for the user to steer the pick, and the user does not pick.
    private struct RankKey: Comparable {
        let recency: Int
        let rotation: Int

        static func < (lhs: RankKey, rhs: RankKey) -> Bool {
            if lhs.recency != rhs.recency {
                return lhs.recency < rhs.recency
            }
            return lhs.rotation < rhs.rotation
        }
    }

    /// Selection order: diet profile → category → avoid the last three days → stable order
    /// rotated by date.
    static func select(
        from entries: [CatalogueEntry],
        request: DishSelectionRequest,
        on date: Date,
        calendar: Calendar
    ) -> DishSelectionResult? {
        let catalogueCount = entries.count
        let candidates = Array(entries.enumerated())
            .filter { $0.element.category == request.category }
            .filter { $0.element.variant.diets.contains(request.constraints.profile) }

        // `nil` rather than an invented dish. The catalogue invariant makes this unreachable for
        // every shipped profile and category, and returning something anyway would be the
        // silent relaxation the product rules forbid.
        guard !candidates.isEmpty else { return nil }

        let recentWindow = request.recentSelections.filter { selection in
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
                recency: recency,
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
        return DishSelectionResult(
            recommendation: recommendation,
            alternative: alternative(to: recommendation, among: ranked)
        )
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

    private static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: from),
            to: calendar.startOfDay(for: to)
        ).day ?? 0
    }

    /// The catalogue index rotated by the number of local days since the reference date, so the
    /// tie-break order shifts by exactly one place per day without ever jumping backwards at a
    /// year boundary (D40). Modded by the full catalogue count, never the candidate count, so a
    /// diet profile never shifts anyone else's rotation.
    static func rotatedIndex(catalogueIndex: Int, catalogueCount: Int, date: Date, calendar: Calendar) -> Int {
        guard catalogueCount > 0 else { return 0 }
        let epoch = calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0))
        let days = daysBetween(epoch, date, calendar: calendar)
        let shifted = (catalogueIndex - days % catalogueCount) % catalogueCount
        return (shifted + catalogueCount) % catalogueCount
    }
}
