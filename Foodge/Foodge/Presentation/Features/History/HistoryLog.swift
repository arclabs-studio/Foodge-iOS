//
//  HistoryLog.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import OSLog

/// The History flow's log, and the rule about what may go into it.
///
/// **Only stage labels.** Never a case's evidence, decision or appeals — same idiom as
/// `TodayLog`/`OnboardingLog`.
enum HistoryLog {
    static let logger = Logger(subsystem: "com.arclabs.Foodge", category: "history")
}
