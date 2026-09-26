//
//  DinnerTime+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

extension DinnerTime {
    /// How the user describes the evening they have ahead of them.
    var displayName: LocalizedStringResource {
        switch self {
        case .quick:
            LocalizedStringResource("Quick", comment: "Dinner routine: little time to cook")
        case .relaxed:
            LocalizedStringResource("Relaxed", comment: "Dinner routine: time to cook properly")
        }
    }

    /// A short line explaining what the choice changes, for the row's secondary text.
    var displayDescription: LocalizedStringResource {
        switch self {
        case .quick:
            LocalizedStringResource(
                "Foodge leans towards dinners that are ready fast.",
                comment: "Explains the quick dinner routine"
            )
        case .relaxed:
            LocalizedStringResource(
                "Foodge can suggest dinners worth taking time over.",
                comment: "Explains the relaxed dinner routine"
            )
        }
    }
}

extension DinnerTime? {
    /// The footer under the dinner-routine picker, including the case where nothing is chosen.
    ///
    /// Kept beside the other two descriptions rather than in the screen, so all three readings
    /// of this one choice are edited in the same place.
    var footerDescription: LocalizedStringResource {
        switch self {
        case let .some(routine):
            routine.displayDescription
        case .none:
            LocalizedStringResource(
                "Foodge will suggest both quick and slower dinners.",
                comment: "Footer when the user has picked no dinner routine"
            )
        }
    }
}
