//
//  NarrationLog.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import OSLog

/// The narration layer's log, and the rule about what may go into it.
///
/// **Only state labels.** Never the prompt, never the user's note, never the model's output, never
/// an `errorDescription` that could echo any of them — same idiom as `PersistenceLog`/`TodayLog`,
/// with a stricter reason: everything this layer handles is either Health-derived or user-written.
enum NarrationLog {
    static let logger = Logger(subsystem: "com.arclabs.Foodge", category: "narration")
}
