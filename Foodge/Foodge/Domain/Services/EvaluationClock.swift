//
//  EvaluationClock.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// The source of "now" and of the calendar every window is computed in.
///
/// Injecting this is what makes midnight, daylight-saving changes and time-zone changes testable.
/// Domain code never reaches for `Date()` or `Calendar.autoupdatingCurrent`.
protocol EvaluationClock: Sendable {
    var now: Date { get }
    /// A calendar with an explicit time zone. Never `.autoupdatingCurrent`.
    var calendar: Calendar { get }
}

/// A clock frozen at one instant, for tests, previews and demonstration scenarios.
struct FixedClock: EvaluationClock, Hashable {
    let now: Date
    let calendar: Calendar

    init(now: Date, calendar: Calendar) {
        self.now = now
        self.calendar = calendar
    }
}
