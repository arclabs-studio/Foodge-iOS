//
//  HealthKind+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

extension HealthKind {
    /// The reading's name, for the evidence-details source list.
    var displayName: LocalizedStringResource {
        switch self {
        case .activeEnergy:
            LocalizedStringResource("Active energy", comment: "Health reading: calories from movement")
        case .restingEnergy:
            LocalizedStringResource("Resting energy", comment: "Health reading: calories at rest")
        case .steps:
            LocalizedStringResource("Steps", comment: "Health reading: step count")
        case .sleep:
            LocalizedStringResource("Sleep", comment: "Health reading: time asleep")
        case .workouts:
            LocalizedStringResource("Workouts", comment: "Health reading: recorded workouts")
        case .dietaryEnergy:
            LocalizedStringResource("Dietary energy", comment: "Health reading: calories eaten")
        }
    }
}
