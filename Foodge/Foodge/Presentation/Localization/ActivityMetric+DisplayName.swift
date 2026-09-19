//
//  ActivityMetric+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

extension ActivityMetric {
    /// What the recorded pattern was measured in, named for the user.
    var displayName: LocalizedStringResource {
        switch self {
        case .activeEnergy:
            LocalizedStringResource("active energy", comment: "Health metric, used mid-sentence: the calories Health recorded from movement")
        case .steps:
            LocalizedStringResource("steps", comment: "Health metric, used mid-sentence: the step count Health recorded")
        }
    }
}
