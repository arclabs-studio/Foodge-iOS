//
//  DailyContext.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// The user's own account of the day's activity, used only when recorded evidence cannot
/// produce a usable comparison.
enum SelfReportedActivity: String, Codable, CaseIterable, Hashable, Sendable {
    case more
    case usual
    case less
}

/// The context a verdict is decided with, beyond what Health recorded.
///
/// Exactly one field, and it is not a preference: the self-report is the only way a day with no
/// readable active energy can be ruled on at all. Dinner time, energy level, craving and the free
/// note left with D138 — every one of them existed to let the user steer the dish, and Foodge
/// chooses the dish.
struct DailyContext: Hashable, Codable, Sendable {
    let selfReportedActivity: SelfReportedActivity?

    init(selfReportedActivity: SelfReportedActivity? = nil) {
        self.selfReportedActivity = selfReportedActivity
    }

    /// The context of a day the user has not been asked about.
    static let empty = DailyContext()
}
