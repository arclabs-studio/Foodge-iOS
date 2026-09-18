//
//  SleepIntervalUnion.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Reduces overlapping asleep intervals to the time actually spent asleep.
///
/// Health reports sleep as many records that can overlap — several sources, and individual
/// stages nested inside a longer span. Adding their durations would invent hours, so the only
/// correct reading is the union.
enum SleepIntervalUnion {
    /// - Note: Not implemented yet — WU-19-A. It returns zero so the suites that pin the real
    ///   behaviour are red rather than crashing the test run.
    ///
    ///   Zero is indistinguishable from a real night with nothing recorded, which is the one
    ///   thing the product must never confuse. Nothing outside the tests may call this until
    ///   WU-19-A lands.
    static func duration(of intervals: [DateInterval]) -> Duration {
        .zero
    }
}
