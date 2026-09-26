//
//  DietaryConstraints.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// What the user will and will not eat.
///
/// These always come from the user. Foodge never infers a diet or an exclusion from Health, and
/// never silently relaxes one to produce a match.
struct DietaryConstraints: Hashable, Codable, Sendable {
    let profile: DietProfile
    let excludedIngredientIDs: Set<String>

    init(profile: DietProfile = .omnivore, excludedIngredientIDs: Set<String> = []) {
        self.profile = profile
        self.excludedIngredientIDs = excludedIngredientIDs
    }

    /// Omnivore with nothing excluded.
    static let unrestricted = DietaryConstraints()
}
