//
//  PersistedDishOutcome+Display.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import Foundation

extension PersistedDishOutcome {
    /// The variant on screen: the runner-up while the alternative is shown, when there is one.
    func shownVariantID(showingAlternative: Bool) -> String {
        showingAlternative ? (alternativeVariantID ?? variantID) : variantID
    }

    /// The family of the variant on screen, under the same rule as ``shownVariantID(showingAlternative:)``.
    func shownFamily(showingAlternative: Bool) -> DishFamily {
        showingAlternative ? (alternativeFamily ?? family) : family
    }
}
