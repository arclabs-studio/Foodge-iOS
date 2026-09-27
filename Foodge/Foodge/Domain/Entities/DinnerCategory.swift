//
//  DinnerCategory.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// The three dinner categories Foodge can rule for.
///
/// These are editorial product categories, not validated nutritional advice. "Light" in
/// particular makes no claim about a verified calorie value.
enum DinnerCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case treat
    case balanced
    case light

    /// The dish families the product brief assigns to this category.
    ///
    /// Lives here rather than in the screen that groups them: which family is a treat is a
    /// domain fact, and a second copy of it in Presentation is a second place to get it wrong.
    var families: [DishFamily] {
        DishFamily.allCases.filter { $0.category == self }
    }
}
