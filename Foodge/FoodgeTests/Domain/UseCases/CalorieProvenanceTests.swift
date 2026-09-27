//
//  CalorieProvenanceTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// What survives of this suite after D111: the rule that a dish shows a calorie value **only**
/// against a verified portion reference.
///
/// The eight `compare(_:)` tests went with the function, but their oracles did not: the sum, the
/// negative result that must still be returned, the identical-window precondition and
/// "replaces, never adds" are all asserted in `CheatMealAllowanceRuleTests` against the rule that
/// now owns that arithmetic. The four tests here are unchanged, and matter more than before —
/// `Dish.kilocalorieRange` (D116) is editorial, and this is what keeps the two kinds of number
/// different things.
@Suite("Calorie provenance", .tags(.unit, .domain, .critical))
struct CalorieProvenanceTests {

    // MARK: - Dish calorie display

    @Test("A variant with no reference id shows no calorie value")
    func aVariantWithNoReferenceIDShowsNoCalorieValue() {
        // Given a generic dish variant with no calorieReferenceID
        let variant = DishVariant(
            id: "variant.test.generic",
            nameKey: "Generic dish",
            ingredients: [],
            diets: [.omnivore],
            convenience: [],
            calorieReferenceID: nil
        )

        // When resolving its calorie display against a non-empty reference set
        let outcome = CalorieProvenance.calories(for: variant, references: CalorieReferenceCatalogue.all)

        // Then it is unknown — a generic dish has no automatic calorie value
        #expect(outcome == .unknown)
    }

    @Test("A variant with a dangling reference id shows no calorie value")
    func aVariantWithADanglingReferenceIDShowsNoCalorieValue() {
        // Given a variant naming a reference id that does not exist in the supplied set
        let variant = DishVariant(
            id: "variant.test.dangling",
            nameKey: "Dangling dish",
            ingredients: [],
            diets: [.omnivore],
            convenience: [],
            calorieReferenceID: "calorieReference.does.not.exist"
        )

        // When resolving its calorie display
        let outcome = CalorieProvenance.calories(for: variant, references: CalorieReferenceCatalogue.all)

        // Then it is unknown rather than crashing on the orphaned id
        #expect(outcome == .unknown)
    }

    @Test("A variant with a matching reference id shows the verified figure")
    func aVariantWithAMatchingReferenceIDShowsTheVerifiedFigure() {
        // Given a synthetic reference and a variant naming its id
        let reference = CalorieReference(
            id: "calorieReference.test.fixture",
            regionCode: "ES",
            productName: "Test product",
            portionDescription: "One unit",
            kilocalories: 123,
            source: URL(string: "https://example.com/test") ?? URL(fileURLWithPath: "/"),
            verifiedOn: Date(timeIntervalSinceReferenceDate: 0)
        )
        let variant = DishVariant(
            id: "variant.test.matching",
            nameKey: "Matching dish",
            ingredients: [],
            diets: [.omnivore],
            convenience: [],
            calorieReferenceID: reference.id
        )

        // When resolving its calorie display
        let outcome = CalorieProvenance.calories(for: variant, references: [reference])

        // Then the exact fixture comes back untouched
        #expect(outcome == .verified(reference))
    }
}
