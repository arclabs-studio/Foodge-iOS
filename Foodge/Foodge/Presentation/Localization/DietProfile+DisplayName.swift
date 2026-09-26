//
//  DietProfile+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

extension DietProfile {
    /// The name shown to the user.
    ///
    /// User-facing copy lives in Presentation, never in `Domain/Entities`, so the domain stays
    /// free of anything that has to be translated or reviewed for tone.
    var displayName: LocalizedStringResource {
        switch self {
        case .omnivore:
            LocalizedStringResource("Omnivore", comment: "Diet choice: eats everything")
        case .pescatarian:
            LocalizedStringResource("Pescatarian", comment: "Diet choice: fish but no other meat")
        case .vegetarian:
            LocalizedStringResource("Vegetarian", comment: "Diet choice: no meat or fish")
        case .vegan:
            LocalizedStringResource("Vegan", comment: "Diet choice: no animal products at all")
        }
    }
}
