//
//  DishSelectionTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 20/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// A five-entry miniature catalogue whose winner is computable on paper, so every ranking test
/// isolates exactly the one criterion it claims to test — the others are held tied by
/// construction rather than asserted to be equal by inspection.
///
/// Ingredient markers (`onlyIn…`) exist purely so a test can remove exactly one entry via
/// `excludedIngredientIDs` without touching the others.
private enum Mini {
    static let common = Ingredient(id: "mini.common", nameKey: "Common")
    static let onlyBowlA = Ingredient(id: "mini.onlyBowlA", nameKey: "Only in Bowl A")
    static let onlyBowlB = Ingredient(id: "mini.onlyBowlB", nameKey: "Only in Bowl B")
    static let onlyTortillaA = Ingredient(id: "mini.onlyTortillaA", nameKey: "Only in Tortilla A")

    /// Catalogue index order — this array IS the `entries` parameter, so this order is what
    /// the rotation tie-break rotates.
    static let bowlA = CatalogueEntry(
        family: .riceBowls,
        variant: DishVariant(
            id: "mini.riceBowls.a",
            nameKey: "Bowl A",
            ingredients: [common, onlyBowlA],
            diets: Set(DietProfile.allCases),
            convenience: [.quick],
            calorieReferenceID: nil
        )
    )
    static let bowlB = CatalogueEntry(
        family: .riceBowls,
        variant: DishVariant(
            id: "mini.riceBowls.b",
            nameKey: "Bowl B",
            ingredients: [common, onlyBowlB],
            diets: Set(DietProfile.allCases),
            convenience: [.onePan],
            calorieReferenceID: nil
        )
    )
    static let tortillaA = CatalogueEntry(
        family: .tortilla,
        variant: DishVariant(
            id: "mini.tortilla.a",
            nameKey: "Tortilla A",
            ingredients: [common, onlyTortillaA],
            diets: Set(DietProfile.allCases),
            convenience: [.quick, .onePan],
            calorieReferenceID: nil
        )
    )
    static let tortillaB = CatalogueEntry(
        family: .tortilla,
        variant: DishVariant(
            id: "mini.tortilla.b",
            nameKey: "Tortilla B",
            ingredients: [common],
            diets: [.omnivore],
            convenience: [],
            calorieReferenceID: nil
        )
    )
    static let burgerX = CatalogueEntry(
        family: .burgers,
        variant: DishVariant(
            id: "mini.burgers.x",
            nameKey: "Burger X",
            ingredients: [common],
            diets: Set(DietProfile.allCases),
            convenience: [.quick],
            calorieReferenceID: nil
        )
    )

    static let all = [bowlA, bowlB, tortillaA, tortillaB, burgerX]
}

@Suite("Dish selection", .tags(.unit, .domain, .critical))
struct DishSelectionTests {
    private static let day = TestCalendar.date(2026, 9, 20)

    private func select(
        entries: [CatalogueEntry] = Mini.all,
        category: DinnerCategory = .balanced,
        constraints: DietaryConstraints = .unrestricted,
        context: DailyContext = .empty,
        favouriteFamilies: [DishFamily] = [],
        recentSelections: [RecentDishSelection] = [],
        on date: Date = DishSelectionTests.day
    ) -> DishSelectionOutcome {
        DishSelection.select(
            from: entries,
            request: DishSelectionRequest(
                category: category,
                constraints: constraints,
                context: context,
                favouriteFamilies: favouriteFamilies,
                recentSelections: recentSelections
            ),
            on: date,
            calendar: TestCalendar.madrid
        )
    }

    private func recommendation(_ outcome: DishSelectionOutcome) throws -> CatalogueEntry {
        guard case let .selected(recommendation, _) = outcome else {
            Issue.record("Expected .selected, got \(outcome)")
            throw FixtureFailure("not selected")
        }
        return recommendation
    }

    // MARK: - Hard filters

    @Test("Category filters out every other family")
    func categoryFilterExcludesOtherFamilies() throws {
        // Given the miniature catalogue, which includes one treat-family entry
        // When asking for balanced
        let recommendation = try recommendation(select(category: .balanced))

        // Then the treat entry never wins, because it was never a candidate
        #expect(recommendation.family != .burgers)
        #expect(recommendation.category == .balanced)
    }

    @Test("An omnivore-only variant is excluded by a vegan diet")
    func dietFilterExcludesIncompatibleVariants() throws {
        // Given tortillaB, which only satisfies omnivore, among otherwise all-vegan-compatible
        // candidates
        // When a vegan asks for balanced
        let recommendation = try recommendation(
            select(
                constraints: DietaryConstraints(profile: .vegan)
            )
        )

        // Then tortillaB never wins — it is the only remaining candidate's opposite
        #expect(recommendation.id != Mini.tortillaB.id)
    }

    @Test("An exclusion is never relaxed, even when it empties every candidate")
    func exclusionNeverRelaxes() {
        // Given every balanced variant sharing one ingredient
        // When that ingredient is excluded
        let outcome = select(
            constraints: DietaryConstraints(excludedIngredientIDs: [Mini.common.id])
        )

        // Then the result is an honest no-match naming the blocking ingredient — never a
        // silently relaxed recommendation
        #expect(outcome == .noMatch(blockingIngredientIDs: [Mini.common.id]))
    }

    @Test("An id blocking a candidate only jointly with another exclusion is left out of the result")
    func blockingIDsExcludeJointlyNeededIngredients() {
        // Given two exclusions: "common", which every candidate contains, and "onlyBowlA",
        // which only Bowl A contains alongside "common"
        let outcome = select(
            constraints: DietaryConstraints(excludedIngredientIDs: [Mini.common.id, Mini.onlyBowlA.id])
        )

        // Then "onlyBowlA" is never named: un-excluding it alone still leaves Bowl A blocked by
        // "common", so it is not individually sufficient to unblock anything. "common" alone
        // would unblock Bowl B and Tortilla A (neither contains "onlyBowlA"), so it is named.
        #expect(outcome == .noMatch(blockingIngredientIDs: [Mini.common.id]))
    }

    // MARK: - Ranking: craving

    @Test("Craving wins inside the category when everything else ties")
    func cravingWinsInsideTheCategory() throws {
        let recommendation = try recommendation(
            select(
                constraints: DietaryConstraints(profile: .vegan, excludedIngredientIDs: [Mini.onlyBowlB.id]),
                context: DailyContext(craving: .tortilla)
            )
        )
        #expect(recommendation.id == Mini.tortillaA.id)
    }

    @Test("A craving for a family outside the category falls through and still returns a dish")
    func cravingOutsideCategoryStillReturnsADish() {
        // Given only one candidate can possibly survive
        let outcome = select(
            constraints: DietaryConstraints(
                profile: .vegan,
                excludedIngredientIDs: [Mini.onlyBowlB.id, Mini.onlyTortillaA.id]
            ),
            context: DailyContext(craving: .burgers)
        )

        // Then a craving for a family this category doesn't even hold never blocks a result
        guard case let .selected(recommendation, alternative) = outcome else {
            Issue.record("Expected .selected, got \(outcome)")
            return
        }
        #expect(recommendation.id == Mini.bowlA.id)
        #expect(alternative == nil)
    }

    // MARK: - Ranking: convenience

    @Test("Convenience overlap orders two candidates that tie on craving")
    func convenienceOrdersCandidates() throws {
        let recommendation = try recommendation(
            select(
                constraints: DietaryConstraints(profile: .vegan, excludedIngredientIDs: [Mini.onlyBowlB.id]),
                context: DailyContext(dinnerTime: .quick)
            )
        )
        // Tortilla A matches two preferred tags (quick, onePan) against Bowl A's one (quick)
        #expect(recommendation.id == Mini.tortillaA.id)
    }

    // MARK: - Ranking: recency

    @Test("Yesterday's variant loses to a same-day-tied alternative")
    func yesterdaysVariantLoses() throws {
        let yesterday = try #require(TestCalendar.madrid.date(byAdding: .day, value: -1, to: Self.day))
        let recommendation = try recommendation(
            select(
                constraints: DietaryConstraints(profile: .vegan, excludedIngredientIDs: [Mini.onlyTortillaA.id]),
                recentSelections: [RecentDishSelection(variantID: Mini.bowlA.id, family: .riceBowls, date: yesterday)]
            )
        )
        // Bowl A is the exact variant shown yesterday (recency 2); Bowl B only shares its
        // family (recency 1) — the lower penalty wins
        #expect(recommendation.id == Mini.bowlB.id)
    }

    @Test("Yesterday's family loses to a different family, even with a different variant")
    func yesterdaysFamilyLoses() throws {
        let yesterday = try #require(TestCalendar.madrid.date(byAdding: .day, value: -1, to: Self.day))
        let recommendation = try recommendation(
            select(
                constraints: DietaryConstraints(profile: .vegan, excludedIngredientIDs: [Mini.onlyBowlB.id]),
                recentSelections: [RecentDishSelection(variantID: Mini.bowlB.id, family: .riceBowls, date: yesterday)]
            )
        )
        // Bowl A only shares the family shown yesterday (recency 1); Tortilla A shares neither
        // the family nor the variant (recency 0)
        #expect(recommendation.id == Mini.tortillaA.id)
    }

    @Test("A selection from four days ago has no effect on recency")
    func fourDaysAgoHasNoEffect() throws {
        let fourDaysAgo = try #require(TestCalendar.madrid.date(byAdding: .day, value: -4, to: Self.day))
        let recommendation = try recommendation(
            select(
                constraints: DietaryConstraints(profile: .vegan, excludedIngredientIDs: [Mini.onlyBowlB.id]),
                favouriteFamilies: [.riceBowls],
                recentSelections: [RecentDishSelection(variantID: Mini.bowlA.id, family: .riceBowls, date: fourDaysAgo)]
            )
        )
        // If the four-day-old selection wrongly counted, Bowl A's recency would outrank its
        // favourite status and Tortilla A would win instead
        #expect(recommendation.id == Mini.bowlA.id)
    }

    // MARK: - Ranking: favourites, and the comparator's priority order

    @Test("Favourites break a tie once craving, convenience and recency all agree")
    func favouritesBreakATie() throws {
        let recommendation = try recommendation(
            select(
                constraints: DietaryConstraints(profile: .vegan, excludedIngredientIDs: [Mini.onlyBowlB.id]),
                favouriteFamilies: [.tortilla]
            )
        )
        #expect(recommendation.id == Mini.tortillaA.id)
    }

    @Test("Favourites never beat recency")
    func favouritesNeverBeatRecency() throws {
        let yesterday = try #require(TestCalendar.madrid.date(byAdding: .day, value: -1, to: Self.day))
        let recommendation = try recommendation(
            select(
                constraints: DietaryConstraints(profile: .vegan, excludedIngredientIDs: [Mini.onlyBowlB.id]),
                favouriteFamilies: [.riceBowls],
                recentSelections: [RecentDishSelection(variantID: Mini.bowlA.id, family: .riceBowls, date: yesterday)]
            )
        )
        // Bowl A is favourited but was shown yesterday; Tortilla A is not favourited but is
        // untouched — recency, ranked above favourite, decides
        #expect(recommendation.id == Mini.tortillaA.id)
    }

    @Test("Recency never beats craving")
    func recencyNeverBeatsCraving() throws {
        let yesterday = try #require(TestCalendar.madrid.date(byAdding: .day, value: -1, to: Self.day))
        let recommendation = try recommendation(
            select(
                constraints: DietaryConstraints(profile: .vegan, excludedIngredientIDs: [Mini.onlyBowlB.id]),
                context: DailyContext(craving: .tortilla),
                recentSelections: [RecentDishSelection(variantID: Mini.tortillaA.id, family: .tortilla, date: yesterday)]
            )
        )
        // Tortilla A was shown yesterday (recency 2, its worst possible score) but is still the
        // craving match — craving, ranked above recency, decides regardless
        #expect(recommendation.id == Mini.tortillaA.id)
    }

    @Test("Convenience never beats craving")
    func convenienceNeverBeatsCraving() throws {
        let recommendation = try recommendation(
            select(
                constraints: DietaryConstraints(profile: .vegan, excludedIngredientIDs: [Mini.onlyBowlB.id]),
                context: DailyContext(dinnerTime: .quick, craving: .riceBowls)
            )
        )
        // Tortilla A matches two preferred convenience tags against Bowl A's one, but Bowl A is
        // the craving match — craving, ranked above convenience (D46), decides regardless
        #expect(recommendation.id == Mini.bowlA.id)
    }

    // MARK: - Alternative

    @Test("The alternative prefers a different family over a different variant")
    func alternativePrefersADifferentFamily() throws {
        let yesterday = try #require(TestCalendar.madrid.date(byAdding: .day, value: -1, to: Self.day))
        let outcome = select(
            constraints: DietaryConstraints(profile: .vegan),
            context: DailyContext(dinnerTime: .quick),
            recentSelections: [RecentDishSelection(variantID: Mini.bowlB.id, family: .riceBowls, date: yesterday)]
        )
        guard case let .selected(recommendation, alternative) = outcome else {
            Issue.record("Expected .selected, got \(outcome)")
            return
        }
        #expect(recommendation.id == Mini.tortillaA.id)
        // Bowl A outranks Bowl B within riceBowls (recency 1 vs 2), so it is the alternative
        #expect(alternative?.id == Mini.bowlA.id)
    }

    @Test("The alternative falls back to a different variant when only one family survives")
    func alternativeFallsBackToADifferentVariant() {
        let outcome = select(
            constraints: DietaryConstraints(profile: .vegan, excludedIngredientIDs: [Mini.onlyTortillaA.id])
        )
        guard case let .selected(recommendation, alternative) = outcome, let alternative else {
            Issue.record("Expected a selected recommendation with an alternative")
            return
        }
        #expect(alternative.family == recommendation.family)
        #expect(alternative.id != recommendation.id)
        #expect(Set([recommendation.id, alternative.id]) == Set([Mini.bowlA.id, Mini.bowlB.id]))
    }

    @Test("The alternative is nil when only one candidate survives")
    func alternativeIsNilWithOneCandidate() {
        let outcome = select(
            constraints: DietaryConstraints(
                profile: .vegan,
                excludedIngredientIDs: [Mini.onlyBowlB.id, Mini.onlyTortillaA.id]
            )
        )
        guard case let .selected(recommendation, alternative) = outcome else {
            Issue.record("Expected .selected, got \(outcome)")
            return
        }
        #expect(recommendation.id == Mini.bowlA.id)
        #expect(alternative == nil)
    }

    // MARK: - Determinism

    @Test("A clear winner is unaffected by the input array's order")
    func winnerIsUnaffectedByShuffledInput() throws {
        // Given a scenario where convenience alone already decides the winner, so rotation —
        // the only value that changes when the array is reshuffled — is never consulted
        for _ in 0 ..< 5 {
            let recommendation = try recommendation(
                select(
                    entries: Mini.all.shuffled(),
                    constraints: DietaryConstraints(profile: .vegan),
                    context: DailyContext(dinnerTime: .quick)
                )
            )
            #expect(recommendation.id == Mini.tortillaA.id)
        }
    }

    // MARK: - Real catalogue

    @Test("No diet profile alone ever produces a no-match, in any category")
    func noDietAloneEverProducesNoMatch() {
        for category in DinnerCategory.allCases {
            for profile in DietProfile.allCases {
                let outcome = DishSelection.select(
                    from: DishCatalogue.entries,
                    request: DishSelectionRequest(
                        category: category,
                        constraints: DietaryConstraints(profile: profile),
                        context: .empty
                    ),
                    on: Self.day,
                    calendar: TestCalendar.madrid
                )
                if case .noMatch = outcome {
                    Issue.record("\(category)/\(profile) produced a no-match with nothing excluded")
                }
            }
        }
    }

    // MARK: - Rotation

    private func rotatedIndex(_ index: Int, count: Int = 27, date: Date) -> Int {
        DishSelection.rotatedIndex(
            catalogueIndex: index,
            catalogueCount: count,
            date: date,
            calendar: TestCalendar.madrid
        )
    }

    @Test("Consecutive local days rotate by exactly one position")
    func consecutiveDaysDifferByOne() throws {
        let tomorrow = try #require(TestCalendar.madrid.date(byAdding: .day, value: 1, to: Self.day))
        let today = rotatedIndex(5, date: Self.day)
        let next = rotatedIndex(5, date: tomorrow)
        #expect(((today - next) + 27) % 27 == 1)
    }

    @Test("The new year does not jump the rotation backwards")
    func newYearRotatesByOne() {
        let eve = rotatedIndex(3, date: TestCalendar.date(2026, 12, 31))
        let day = rotatedIndex(3, date: TestCalendar.date(2027, 1, 1))
        // A day-of-year implementation would jump backwards by 364 here; a continuous day
        // index differs by exactly one, same as any other consecutive pair
        #expect(((eve - day) + 27) % 27 == 1)
    }

    @Test("The day Spain loses an hour still rotates by exactly one position")
    func springForwardRotatesByOne() {
        let before = rotatedIndex(1, date: TestCalendar.date(2026, 3, 29))
        let after = rotatedIndex(1, date: TestCalendar.date(2026, 3, 30))
        #expect(((before - after) + 27) % 27 == 1)
    }

    @Test("08:00 and 23:30 on the same local day give the same rotation")
    func sameLocalDayGivesSameRotation() {
        let morningIndex = rotatedIndex(8, date: TestCalendar.date(2026, 9, 20, 8, 0))
        let nightIndex = rotatedIndex(8, date: TestCalendar.date(2026, 9, 20, 23, 30))
        #expect(morningIndex == nightIndex)
    }

    @Test("A pre-2001 date still produces a non-negative rotation")
    func preReferenceDateIsNonNegative() {
        let index = rotatedIndex(12, date: TestCalendar.date(1990, 1, 1))
        #expect(index >= 0)
        #expect(index < 27)
    }

    @Test("Rotation is a pure function of its inputs")
    func rotationIsDeterministic() {
        #expect(rotatedIndex(4, date: Self.day) == rotatedIndex(4, date: Self.day))
    }
}
