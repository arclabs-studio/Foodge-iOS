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
        // Fixture loading is the one place the constitution allows failing loudly, and this is
        // worth failing loudly for: falling back to GMT would leave every assertion here passing
        // while quietly removing the daylight-saving behaviour the time tests exist to prove.
        guard let madrid = TimeZone(identifier: "Europe/Madrid") else {
            fatalError("These fixtures require the Europe/Madrid time zone.")
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = madrid
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

    /// Local midnight up to 19:30 on 18 September 2026 — the evaluation window every allowance
    /// fixture is cut at, matching `SyntheticScenarios`' own evaluation instant.
    static let todayWindow = DateInterval(
        start: date(2026, 9, 18),
        end: date(2026, 9, 18, 19, 30)
    )
}
