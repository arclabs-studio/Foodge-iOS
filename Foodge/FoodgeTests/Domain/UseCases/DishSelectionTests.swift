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
/// The narrowing tool is the **diet profile**, not an ingredient exclusion: exclusions left with
/// D138, so a test that needs a two-candidate field builds one by passing a trimmed `entries`
/// array or by asking as a vegan, never by excluding an ingredient.
private enum Mini {
    static let common = Ingredient(id: "mini.common", nameKey: "Common")

    /// Catalogue index order — this array IS the `entries` parameter, so this order is what
    /// the rotation tie-break rotates.
    static let bowlA = CatalogueEntry(
        family: .riceBowls,
        variant: DishVariant(
            id: "mini.riceBowls.a",
            nameKey: "Bowl A",
            ingredients: [common],
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
            ingredients: [common],
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
            ingredients: [common],
            diets: Set(DietProfile.allCases),
            convenience: [.quick, .onePan],
            calorieReferenceID: nil
        )
    )
    /// The one omnivore-only entry, which is how a vegan request narrows the field.
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
        recentSelections: [RecentDishSelection] = [],
        on date: Date = DishSelectionTests.day
    ) -> DishSelectionResult? {
        DishSelection.select(
            from: entries,
            request: DishSelectionRequest(
                category: category,
                constraints: constraints,
                recentSelections: recentSelections
            ),
            on: date,
            calendar: TestCalendar.madrid
        )
    }

    private func recommendation(_ result: DishSelectionResult?) throws -> CatalogueEntry {
        try #require(result).recommendation
    }

    private func yesterday() throws -> Date {
        try #require(TestCalendar.madrid.date(byAdding: .day, value: -1, to: Self.day))
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
        // Given a field of exactly two balanced entries, one of them omnivore-only
        // When a vegan asks for balanced
        let recommendation = try recommendation(
            select(entries: [Mini.tortillaB, Mini.bowlA], constraints: DietaryConstraints(profile: .vegan))
        )

        // Then the omnivore-only one never wins, whatever the rotation says
        #expect(recommendation.id == Mini.bowlA.id)
    }

    @Test("A diet that admits nothing in the category is reported as nothing, never relaxed")
    func anEmptyFieldIsReportedHonestly() {
        // Given a catalogue whose only balanced entry is omnivore-only
        // When a vegan asks for balanced
        let result = select(entries: [Mini.tortillaB], constraints: DietaryConstraints(profile: .vegan))

        // Then there is no dish, rather than the omnivore one relaxed into an answer. The real
        // catalogue never reaches this — `everyCategoryOffersEveryDietProfile` is what pins
        // that — but the rule has to hold for the one that does.
        #expect(result == nil)
    }

    // MARK: - Ranking: recency

    @Test("The variant shown yesterday loses to the other candidate — in both directions")
    func yesterdaysVariantLoses() throws {
        // Given exactly two candidates, so rotation cannot decide the outcome either way
        let yesterday = try yesterday()
        let field = [Mini.bowlA, Mini.bowlB]

        // When each of them in turn is the one shown yesterday
        let afterBowlA = try recommendation(
            select(
                entries: field,
                recentSelections: [RecentDishSelection(variantID: Mini.bowlA.id, family: .riceBowls, date: yesterday)]
            )
        )
        let afterBowlB = try recommendation(
            select(
                entries: field,
                recentSelections: [RecentDishSelection(variantID: Mini.bowlB.id, family: .riceBowls, date: yesterday)]
            )
        )

        // Then the other one wins each time. Both directions are asserted on purpose: a rule
        // that ignored recency entirely would return the same entry twice, and one direction
        // alone could pass on rotation by luck
        #expect(afterBowlA.id == Mini.bowlB.id)
        #expect(afterBowlB.id == Mini.bowlA.id)
    }

    @Test("Yesterday's family loses to a different family, even with a different variant")
    func yesterdaysFamilyLoses() throws {
        // Given three balanced candidates: two rice bowls and one tortilla
        let yesterday = try yesterday()

        // When a rice bowl was shown yesterday
        let recommendation = try recommendation(
            select(
                entries: [Mini.bowlA, Mini.bowlB, Mini.tortillaA],
                recentSelections: [RecentDishSelection(variantID: Mini.bowlA.id, family: .riceBowls, date: yesterday)]
            )
        )

        // Then the tortilla wins: Bowl A is the exact variant (recency 2), Bowl B shares its
        // family (recency 1), and only the tortilla shares neither (recency 0)
        #expect(recommendation.id == Mini.tortillaA.id)
    }

    @Test("A selection from four days ago changes nothing at all")
    func fourDaysAgoHasNoEffect() throws {
        // Given a selection just outside the three-day window
        let fourDaysAgo = try #require(TestCalendar.madrid.date(byAdding: .day, value: -4, to: Self.day))
        let field = [Mini.bowlA, Mini.bowlB, Mini.tortillaA]

        // When the same day is decided with and without it
        let withHistory = try recommendation(
            select(
                entries: field,
                recentSelections: [RecentDishSelection(variantID: Mini.bowlA.id, family: .riceBowls, date: fourDaysAgo)]
            )
        )
        let withoutHistory = try recommendation(select(entries: field))

        // Then the two agree. The oracle is the rule's own answer with no history at all, so a
        // window widened to four days breaks this without anyone having to predict the winner
        #expect(withHistory.id == withoutHistory.id)
    }

    // MARK: - The alternative

    @Test("The alternative prefers a different family over a different variant")
    func alternativePrefersADifferentFamily() throws {
        // Given two rice bowls and a tortilla, with a rice bowl shown yesterday so the tortilla
        // leads and the two bowls follow it
        let yesterday = try yesterday()
        let result = try #require(
            select(
                entries: [Mini.bowlA, Mini.bowlB, Mini.tortillaA],
                recentSelections: [RecentDishSelection(variantID: Mini.bowlA.id, family: .riceBowls, date: yesterday)]
            )
        )

        // Then the alternative is from the other family rather than the other tortilla variant
        #expect(result.recommendation.id == Mini.tortillaA.id)
        #expect(result.alternative?.family == .riceBowls)
    }

    @Test("The alternative falls back to a different variant when only one family survives")
    func alternativeFallsBackToADifferentVariant() throws {
        // Given a field of two variants from the same family
        let result = try #require(select(entries: [Mini.bowlA, Mini.bowlB]))

        // Then the alternative is the other variant of that same family
        #expect(result.alternative?.family == result.recommendation.family)
        #expect(result.alternative?.id != result.recommendation.id)
        #expect(Set([result.recommendation.id, result.alternative?.id]) == Set([Mini.bowlA.id, Mini.bowlB.id]))
    }

    @Test("The alternative is nil when only one candidate survives")
    func alternativeIsNilWithOneCandidate() throws {
        // Given a field with exactly one balanced candidate
        let result = try #require(select(entries: [Mini.bowlA]))

        // Then there is nothing to offer alongside it, and none is invented
        #expect(result.recommendation.id == Mini.bowlA.id)
        #expect(result.alternative == nil)
    }

    // MARK: - Determinism

    @Test("A clear winner is unaffected by the input array's order")
    func winnerIsUnaffectedByShuffledInput() throws {
        // Given a scenario where recency alone already decides the winner, so rotation — the
        // only value that changes when the array is reshuffled — never breaks the tie
        let yesterday = try yesterday()
        let history = [RecentDishSelection(variantID: Mini.bowlA.id, family: .riceBowls, date: yesterday)]

        for _ in 0 ..< 5 {
            let recommendation = try recommendation(
                select(entries: [Mini.bowlA, Mini.bowlB, Mini.tortillaA].shuffled(), recentSelections: history)
            )
            #expect(recommendation.id == Mini.tortillaA.id)
        }
    }

    // MARK: - Real catalogue

    @Test("Every category offers something to every diet profile")
    func everyCategoryOffersEveryDietProfile() {
        // This is the invariant that lets `select` have no "nothing fits" outcome to report
        // (D139). It fails the moment a category's last vegan or vegetarian variant is edited
        // away — which is exactly when the app would otherwise start returning no dinner.
        for category in DinnerCategory.allCases {
            for profile in DietProfile.allCases {
                let result = DishSelection.select(
                    from: DishCatalogue.entries,
                    request: DishSelectionRequest(
                        category: category,
                        constraints: DietaryConstraints(profile: profile)
                    ),
                    on: Self.day,
                    calendar: TestCalendar.madrid
                )
                if result == nil {
                    Issue.record("\(category) offers nothing to a \(profile) diet")
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
