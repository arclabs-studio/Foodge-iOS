//
//  DinnerCategory+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

extension DinnerCategory {
    /// The category heading favourites are grouped under.
    ///
    /// These are editorial product categories. Nothing here claims a nutritional fact, and
    /// "Light" in particular makes no claim about a verified calorie value.
    var displayName: LocalizedStringResource {
        switch self {
        case .treat:
            LocalizedStringResource("Treat", comment: "Dinner category for a more indulgent dinner")
        case .balanced:
            LocalizedStringResource("Balanced", comment: "Dinner category for an ordinary dinner")
        case .light:
            LocalizedStringResource("Light", comment: "Dinner category for a lighter dinner")
        }
    }
}
