//
//  CalorieProvenance.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

/// What a dish's calorie display resolved to.
enum DishCalorieOutcome: Hashable, Sendable {
    case verified(CalorieReference)
    case unknown
}

/// Keeps a **verified** calorie figure and an editorial one different things.
///
/// The comparison half of this type is gone with D111: the allowance rule
/// (`CheatMealAllowanceRule`) now owns active + resting − intake, and its preconditions differ —
/// it accepts an estimated component, which `compare(_:)` was built to refuse. What survives is the
/// half that the rebuild makes *more* important, not less: a dish shows a calorie value only
/// against a verified portion reference, and `Dish.kilocalorieRange` (D116) is editorial and is
/// never rendered as one.
enum CalorieProvenance {
    /// `references` is a parameter, not a reach into ``CalorieReferenceCatalogue`` — matches
    /// `DishSelection.select(from:request:...)` taking `entries` as a parameter, so tests can
    /// exercise this against a synthetic list.
    static func calories(for variant: DishVariant, references: [CalorieReference]) -> DishCalorieOutcome {
        guard let referenceID = variant.calorieReferenceID else {
            return .unknown
        }
        guard let reference = references.first(where: { $0.id == referenceID }) else {
            return .unknown
        }
        return .verified(reference)
    }
}
