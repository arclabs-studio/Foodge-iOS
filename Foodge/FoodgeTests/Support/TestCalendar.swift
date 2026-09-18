//
//  TestCalendar.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation
@testable import Foodge

/// A calendar pinned to Europe/Madrid, plus the date helpers the suites build their fixtures
/// from. Tests never read the machine's current calendar or time zone.
enum TestCalendar {
    static let madrid: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return calendar
    }()

    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0,
        calendar: Calendar = madrid
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? .distantPast
    }

    /// A fortnight ending the day before 18 September 2026, which is the window every baseline
    /// fixture in these suites describes.
    static let fortnight = DateInterval(
        start: date(2026, 9, 4),
        end: date(2026, 9, 18)
    )
}

extension CategoryOutcome {
    /// The decision inside a `.verdict` outcome, or `nil` when the rule asked for confirmation
    /// instead. Lets a suite say `try #require(outcome.decision)` and keep the assertion on one
    /// line.
    var decision: VerdictDecision? {
        if case let .verdict(decision) = self { decision } else { nil }
    }
}
