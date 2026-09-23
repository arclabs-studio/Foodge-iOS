//
//  PersistenceLog.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import OSLog

/// The persistence layer's log, and the rule about what may go into it.
///
/// **Only state labels.** Never a day key, never a decision payload, never a user's note — same
/// idiom as `TodayLog`/`OnboardingLog`.
enum PersistenceLog {
    static let logger = Logger(subsystem: "com.arclabs.Foodge", category: "persistence")
}
