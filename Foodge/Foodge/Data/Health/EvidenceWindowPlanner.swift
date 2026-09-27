//
//  EvidenceWindowPlanner.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// Works out which spans of time an evaluation is allowed to look at.
///
/// Today is measured from local midnight up to the evaluation instant. The previous days went with
/// D111 — nothing is compared against them any more — but the daylight-saving arithmetic stayed and
/// now matters more, because the resting-energy estimate is prorated across the local day's real
/// length (D113). Assuming every day is 86,400 seconds long is what this type exists to prevent.
enum EvidenceWindowPlanner {
    /// The window from local midnight up to the evaluation instant.
    ///
    /// Clamped rather than allowed to invert: an evaluation instant before its own local midnight
    /// is impossible, and a `DateInterval` with a negative duration is a trap for everything
    /// downstream.
    static func today(evaluation: Date, calendar: Calendar) -> DateInterval {
        let midnight = calendar.startOfDay(for: evaluation)
        return DateInterval(start: midnight, end: max(midnight, evaluation))
    }

    /// The whole local day `instant` falls in, or `nil` when the calendar cannot say.
    ///
    /// This is the denominator the resting-energy proration divides by, so it is a real
    /// calendar day: 23 hours the morning Spain springs forward, 25 the morning it falls back.
    static func localDay(containing instant: Date, calendar: Calendar) -> DateInterval? {
        calendar.dateInterval(of: .day, for: instant)
    }
}
