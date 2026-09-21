//
//  EnergyLevel+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

extension EnergyLevel {
    /// How the user's own account of their energy is named for them.
    var displayName: LocalizedStringResource {
        switch self {
        case .low:
            LocalizedStringResource("Low", comment: "Self-reported energy level: low")
        case .normal:
            LocalizedStringResource("Normal", comment: "Self-reported energy level: normal")
        }
    }
}
