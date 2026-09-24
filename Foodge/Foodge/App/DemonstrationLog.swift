//
//  DemonstrationLog.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import OSLog

/// Demonstration mode's own logger, following the same convention as `TodayLog`/`SettingsLog`:
/// bare state labels, `privacy: .public`, and never a Health reading, a note or model output.
///
/// A scenario identifier is safe to log — it names invented data, not anyone's day — and on a
/// physical device the console is the only instrument there is (D21).
enum DemonstrationLog {
    static let logger = Logger(subsystem: "com.arclabs.Foodge", category: "demonstration")
}
