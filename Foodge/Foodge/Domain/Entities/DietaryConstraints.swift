//
//  DietaryConstraints.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// What the user will not eat.
///
/// Always from the user, never inferred from Health, and never relaxed to produce a match. The
/// per-ingredient exclusion list left with D138 along with the screen that gathered it; the diet
/// profile stayed, because without it the judge can propose a burger to a vegetarian and has no
/// way to know.
struct DietaryConstraints: Hashable, Codable, Sendable {
    let profile: DietProfile

    init(profile: DietProfile = .omnivore) {
        self.profile = profile
    }

    /// Omnivore — nothing ruled out.
    static let unrestricted = DietaryConstraints()
}
