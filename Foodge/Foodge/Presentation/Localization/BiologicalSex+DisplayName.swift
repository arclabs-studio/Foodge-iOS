//
//  BiologicalSex+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

extension BiologicalSex {
    /// How the formula's parameter is named for the person answering.
    ///
    /// Named plainly, without explaining the equation: what it selects is the version of
    /// Mifflin–St Jeor used, and the screen's own copy says the figures are only ever an estimate.
    var displayName: LocalizedStringResource {
        switch self {
        case .female:
            LocalizedStringResource("Female", comment: "Body basics: the female form of the resting-energy equation")
        case .male:
            LocalizedStringResource("Male", comment: "Body basics: the male form of the resting-energy equation")
        }
    }
}
