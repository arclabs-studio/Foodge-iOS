//
//  TodayLog.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import OSLog

/// The Today flow's log, and the rule about what may go into it.
///
/// **Only stage labels.** Never a Health value, never a decision payload, never a user's note —
/// which is why every call site passes ``TodayViewModel/Stage/logLabel`` rather than the stage
/// itself. Same idiom as `OnboardingLog`.
enum TodayLog {
    static let logger = Logger(subsystem: "com.arclabs.Foodge", category: "today")
}
