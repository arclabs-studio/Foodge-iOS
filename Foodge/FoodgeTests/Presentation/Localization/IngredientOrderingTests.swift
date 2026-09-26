//
//  IngredientOrderingTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The exclusion list is offered by two screens — onboarding and Settings — from one ordering
/// helper (D91). It lives on `Ingredient` rather than on either view model, so its tests live
/// here rather than in either suite.
///
/// The oracle is the shipped Spanish strings and Foundation's own collation, neither of which is
/// produced by the code under test: `Ingredient.excludable` does not decide what "Salmón" is
/// called or where it sorts.
@Suite("Ingredient ordering", .tags(.unit))
struct IngredientOrderingTests {
    @Test("Excludable ingredients are sorted alphabetically in the requested locale, and search is accent-insensitive")
    func excludableIngredientsAreSortedAndSearchIsAccentInsensitive() {
        // Given the compiled-in catalogue, read in Spanish
        let spanish = Locale(identifier: "es")

        // When listing with no search text
        let all = Ingredient.excludable(matching: "", in: spanish)

        // Then the list holds every catalogue ingredient, alphabetically ordered in Spanish
        #expect(all.count == DishCatalogue.ingredients.count)
        let names = all.map { $0.localizedName(in: spanish) }
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })

        // When searching without the accent Spanish actually uses on "Salmón"
        let matches = Ingredient.excludable(matching: "salmon", in: spanish)

        // Then the accented ingredient is still found
        #expect(matches.contains(Ingredient.salmon))
    }
}
