//
//  SettingsLog.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import OSLog

/// Settings' own logger, following the same convention as `TodayLog`/`OnboardingLog`: bare state
/// labels, `privacy: .public`, and never a preference value, a reminder time or a Health reading.
enum SettingsLog {
    static let logger = Logger(subsystem: "com.arclabs.Foodge", category: "settings")
}
