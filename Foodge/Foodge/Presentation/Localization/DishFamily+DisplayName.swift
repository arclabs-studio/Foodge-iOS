//
//  DishFamily+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

extension DishFamily {
    /// The family's name as the user sees it.
    ///
    /// There is deliberately no symbol map alongside this one: the artwork lands on Day 24 and
    /// a second switch over the same nine cases would be a second place to forget to edit.
    var displayName: LocalizedStringResource {
        switch self {
        case .burgers:
            LocalizedStringResource("Burgers", comment: "Dish family, a treat")
        case .pizza:
            LocalizedStringResource("Pizza", comment: "Dish family, a treat")
        case .tacos:
            LocalizedStringResource("Tacos", comment: "Dish family, a treat")
        case .riceBowls:
            LocalizedStringResource("Rice bowls", comment: "Dish family, balanced")
        case .tortilla:
            LocalizedStringResource("Tortilla", comment: "Dish family, balanced. The Spanish potato omelette, not a wrap")
        case .pasta:
            LocalizedStringResource("Pasta", comment: "Dish family, balanced")
        case .lentilSalad:
            LocalizedStringResource("Lentil salad", comment: "Dish family, light")
        case .vegetableSoup:
            LocalizedStringResource("Vegetable soup", comment: "Dish family, light")
        case .vegetableWraps:
            LocalizedStringResource("Vegetable wraps", comment: "Dish family, light")
        }
    }
}
