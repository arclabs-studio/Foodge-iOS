//
//  DishCatalogueTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 20/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// Pins the shape of the catalogue itself, independently of how any selector reads it.
///
/// The animal-product oracle is the load-bearing suite here: it hand-lists which ingredients are
/// meat, fish, or egg/dairy and recomputes what each variant's diets *should* be from that list
/// alone, then compares against what the catalogue actually declares. That is what would catch an
/// editorial slip — the mayonnaise taco marked vegan — that a count or an id-shape check cannot.
@Suite("Dish catalogue", .tags(.unit, .domain, .critical))
struct DishCatalogueTests {

    // MARK: - Counts

    @Test("Nine families, three variants each, 27 entries")
    func theCatalogueHasNineFamiliesOfThreeVariants() {
        // Given the compiled-in catalogue
        // Then every family is present, with exactly three variants
        #expect(DishCatalogue.dishes.count == 9)
        #expect(Set(DishCatalogue.dishes.map(\.family)) == Set(DishFamily.allCases))
        for dish in DishCatalogue.dishes {
            #expect(dish.variants.count == 3, "\(dish.family) has \(dish.variants.count) variants")
        }

        // And the flattened entries match
        #expect(DishCatalogue.entries.count == 27)
    }

    @Test("Forty-four distinct ingredients, every one of them used")
    func ingredientsAreDeduplicatedAndAllUsed() {
        // Given the catalogue's ingredient list
        let ingredients = DishCatalogue.ingredients

        // Then there are 44 of them and none repeats
        #expect(ingredients.count == 44)
        #expect(Set(ingredients).count == 44)

        // And every ingredient the catalogue lists is actually used by some variant
        let used = Set(DishCatalogue.entries.flatMap(\.variant.ingredients))
        #expect(Set(ingredients) == used)
    }

    @Test("Every variant lists at least three ingredients")
    func everyVariantHasAtLeastThreeIngredients() {
        for entry in DishCatalogue.entries {
            #expect(
                entry.variant.ingredients.count >= 3,
                "\(entry.id) has \(entry.variant.ingredients.count) ingredients"
            )
        }
    }

    // MARK: - Identifiers

    @Test("Dish, variant and ingredient ids are unique and correctly shaped")
    func idsAreUniqueAndShaped() {
        let dishIDs = DishCatalogue.dishes.map(\.id)
        #expect(Set(dishIDs).count == dishIDs.count)
        for id in dishIDs {
            #expect(id.hasPrefix("dish."))
        }

        let variantIDs = DishCatalogue.entries.map(\.id)
        #expect(Set(variantIDs).count == variantIDs.count)
        for id in variantIDs {
            #expect(id.hasPrefix("dish."))
        }

        let ingredientIDs = DishCatalogue.ingredients.map(\.id)
        #expect(Set(ingredientIDs).count == ingredientIDs.count)
        for id in ingredientIDs {
            #expect(id.hasPrefix("ingredient."))
        }
    }

    @Test("No display name is an identifier")
    func noNameKeyIsAnIdentifier() {
        // Guards the one failure mode the missing en.lproj creates: a nameKey that is actually
        // the dotted id would render the raw identifier on screen, in every language.
        for ingredient in DishCatalogue.ingredients {
            #expect(ingredient.nameKey != ingredient.id)
            #expect(!ingredient.nameKey.hasPrefix("ingredient."))
        }
        for entry in DishCatalogue.entries {
            #expect(entry.variant.nameKey != entry.variant.id)
            #expect(!entry.variant.nameKey.hasPrefix("dish."))
        }
    }

    @Test("DishCatalogue.ingredient(id:) finds every catalogue ingredient and nothing else")
    func ingredientLookupWorks() {
        for ingredient in DishCatalogue.ingredients {
            #expect(DishCatalogue.ingredient(id: ingredient.id) == ingredient)
        }
        #expect(DishCatalogue.ingredient(id: "ingredient.doesNotExist") == nil)
    }

    // MARK: - Diet nesting

    @Test("A variant's diets are always a nested set: vegan implies vegetarian implies pescatarian implies omnivore")
    func dietsNestCorrectly() {
        for entry in DishCatalogue.entries {
            let diets = entry.variant.diets
            if diets.contains(.vegan) {
                #expect(diets.isSuperset(of: [.vegetarian, .pescatarian, .omnivore]), "\(entry.id)")
            }
            if diets.contains(.vegetarian) {
                #expect(diets.isSuperset(of: [.pescatarian, .omnivore]), "\(entry.id)")
            }
            if diets.contains(.pescatarian) {
                #expect(diets.contains(.omnivore), "\(entry.id)")
            }
            #expect(!diets.isEmpty, "\(entry.id) satisfies nobody")
        }
    }

    @Test("Every category holds at least two fully-vegan variants")
    func everyCategoryHasVeganOptions() {
        // The exact counts the brief's editorial pass produced — asserted, not just "at least
        // one", so a future edit that quietly narrows a category's vegan options is caught.
        let veganCountByCategory = Dictionary(grouping: DishCatalogue.entries) { $0.category }
            .mapValues { entries in entries.filter { $0.variant.diets.contains(.vegan) }.count }

        #expect(veganCountByCategory[.treat] == 3)
        #expect(veganCountByCategory[.balanced] == 2)
        #expect(veganCountByCategory[.light] == 6)
        for category in DinnerCategory.allCases {
            #expect((veganCountByCategory[category] ?? 0) >= 2, "\(category)")
        }
    }

    // MARK: - The independent animal-product oracle

    /// What a diet-conscious human, not the catalogue, would say each ingredient is compatible
    /// with. This list is hand-authored from the ingredient's real-world nature, never derived
    /// from `DishCatalogue` itself — an oracle that read its own answer key would prove nothing.
    private static let meat: Set<Ingredient> = [.beefPatty, .beefMince, .chickenBreast, .chorizo]
    private static let fish: Set<Ingredient> = [.prawns, .salmon, .tuna]
    private static let eggOrDairy: Set<Ingredient> = [.egg, .mayonnaise, .mozzarella, .parmesan, .feta, .halloumi]

    private static func dietCeiling(for ingredient: Ingredient) -> Set<DietProfile> {
        if meat.contains(ingredient) { return [.omnivore] }
        if fish.contains(ingredient) { return [.omnivore, .pescatarian] }
        if eggOrDairy.contains(ingredient) { return [.omnivore, .pescatarian, .vegetarian] }
        return Set(DietProfile.allCases)
    }

    @Test("Every variant's declared diets match what its ingredients actually allow")
    func declaredDietsMatchIngredients() {
        for entry in DishCatalogue.entries {
            let expected = entry.variant.ingredients
                .map(Self.dietCeiling(for:))
                .reduce(Set(DietProfile.allCases)) { $0.intersection($1) }

            #expect(
                entry.variant.diets == expected,
                "\(entry.id) declares \(entry.variant.diets) but ingredients only allow \(expected)"
            )
        }
    }

    @Test("Tortilla is the Spanish potato omelette: every variant contains egg, so none is vegan")
    func tortillaAlwaysContainsEgg() {
        let tortillaVariants = DishCatalogue.entries.filter { $0.family == .tortilla }
        #expect(tortillaVariants.count == 3)
        for entry in tortillaVariants {
            #expect(entry.variant.ingredients.contains(.egg), "\(entry.id)")
            #expect(!entry.variant.diets.contains(.vegan), "\(entry.id)")
        }
    }

    @Test("The chorizo tortilla is the one omnivore-only variant in its family")
    func chorizoTortillaIsOmnivoreOnly() {
        let chorizo = DishCatalogue.entries.first { $0.id == "dish.tortilla.chorizo" }
        #expect(chorizo?.variant.diets == [.omnivore])
    }
}
