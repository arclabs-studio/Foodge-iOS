//
//  DishCatalogue.swift
//  Foodge
//
//  Created by ARC Labs Studio on 20/09/2026.
//

import Foundation

/// The nine-family, 27-variant dish catalogue that stands behind every recommendation.
///
/// A pure Domain constant, not a protocol with a `Data/` implementation (D36): nothing here
/// does I/O, so there is no seam that needs faking and no runtime decode path for something
/// that is really a compile-time guarantee about diet sets.
enum DishCatalogue {
    /// Bumped whenever a variant, ingredient or diet set changes, so a saved case always says
    /// which catalogue produced its dish. Persisted with the case on Day 21.
    static let version = "1.0.0"

    /// The nine dishes, in `DishFamily.allCases` order.
    static let dishes: [Dish] = [
        burgers, pizza, tacos, riceBowls, tortilla, pasta, lentilSalad, vegetableSoup, vegetableWraps
    ]

    /// Every variant flattened to its family, in family order and then variant order.
    static let entries: [CatalogueEntry] = dishes.flatMap { dish in
        dish.variants.map { CatalogueEntry(family: dish.family, variant: $0) }
    }

    /// Every ingredient the catalogue uses, de-duplicated, in first-appearance order.
    static let ingredients: [Ingredient] = {
        var seen = Set<Ingredient>()
        var ordered: [Ingredient] = []
        for entry in entries {
            for ingredient in entry.variant.ingredients where !seen.contains(ingredient) {
                seen.insert(ingredient)
                ordered.append(ingredient)
            }
        }
        return ordered
    }()

    static func ingredient(id: String) -> Ingredient? {
        ingredients.first { $0.id == id }
    }
}

/// One variant together with the family it belongs to — `DishVariant` alone cannot answer
/// "is this a favourite?" or "does it match the craving?".
///
/// Stores no catalogue index: the ordered ``DishCatalogue/entries`` array already carries it, and
/// a selector derives it with `entries.enumerated()` before filtering.
struct CatalogueEntry: Hashable, Sendable, Identifiable {
    let family: DishFamily
    let variant: DishVariant
    var id: String { variant.id }
    var category: DinnerCategory { family.category }
}
