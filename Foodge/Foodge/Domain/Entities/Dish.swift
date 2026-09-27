//
//  Dish.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// A diet the catalogue can be filtered against.
enum DietProfile: String, Codable, CaseIterable, Hashable, Sendable {
    case omnivore
    case pescatarian
    case vegetarian
    case vegan
}

/// How much effort a dish is, used to match the user's available dinner time.
enum ConvenienceTag: String, Codable, CaseIterable, Hashable, Sendable {
    case quick
    case onePan
    case noCook
    case leftoversFriendly
}

/// One named ingredient, stable across languages.
///
/// `nameKey` is the String Catalog key; the raw identifier is what exclusions are stored against
/// so that changing a translation never changes what a user excluded.
struct Ingredient: Hashable, Codable, Sendable, Identifiable {
    let id: String
    let nameKey: String
}

/// The nine bundled dish families.
///
/// The category mapping is editorial and fixed by the product brief.
enum DishFamily: String, Codable, CaseIterable, Hashable, Sendable {
    case burgers
    case pizza
    case tacos
    case riceBowls
    case tortilla
    case pasta
    case lentilSalad
    case vegetableSoup
    case vegetableWraps

    var category: DinnerCategory {
        switch self {
        case .burgers, .pizza, .tacos: .treat
        case .riceBowls, .tortilla, .pasta: .balanced
        case .lentilSalad, .vegetableSoup, .vegetableWraps: .light
        }
    }
}

/// A concrete, ingredient-defined version of a family — the thing actually recommended.
///
/// A generic description cannot guarantee a restaurant's ingredients or the absence of
/// cross-contact, so the ingredient list is always shown rather than implied.
struct DishVariant: Hashable, Codable, Sendable, Identifiable {
    let id: String
    let nameKey: String
    let ingredients: [Ingredient]
    let diets: Set<DietProfile>
    let convenience: Set<ConvenienceTag>
    /// Identifier of a verified portion reference, when one exists. A generic dish has none and
    /// therefore shows no calorie value at all.
    let calorieReferenceID: String?
}

/// A dish family together with its known variants.
struct Dish: Hashable, Codable, Sendable, Identifiable {
    let id: String
    let family: DishFamily
    let variants: [DishVariant]

    var category: DinnerCategory { family.category }
}
