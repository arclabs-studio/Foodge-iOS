//
//  SelfReportedActivity+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

extension SelfReportedActivity {
    /// The check-in choice, named for the user.
    var displayName: LocalizedStringResource {
        switch self {
        case .more:
            LocalizedStringResource("More than usual", comment: "Self-reported activity check-in choice")
        case .usual:
            LocalizedStringResource("About usual", comment: "Self-reported activity check-in choice")
        case .less:
            LocalizedStringResource("Less than usual", comment: "Self-reported activity check-in choice")
        }
    }
}
