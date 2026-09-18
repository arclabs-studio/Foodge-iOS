//
//  EvidenceWindowPlannerTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// The brief's calendar rules: compare each previous day at the same local clock time, and never
/// assume a day is 86,400 seconds long. Spain's 2026 transitions are 29 March (clocks go
/// forward, the day is 23 hours) and 25 October (clocks go back, the day is 25 hours).
@Suite("Evidence window planner", .tags(.unit, .domain, .critical))
struct EvidenceWindowPlannerTests {

    private func windows(
        _ evaluation: Date,
        calendar: Calendar = TestCalendar.madrid,
        historyDays: Int = 14
    ) -> (today: DateInterval, history: [DateInterval]) {
        EvidenceWindowPlanner.windows(
            evaluation: evaluation,
            calendar: calendar,
            historyDays: historyDays
        )
    }

    @Test("A fortnight of history is cut at today's clock time on every day")
    func historyIsCutAtTheSameClockTime() throws {
        // Given an evaluation at 19:30 on 18 September 2026
        let evaluation = TestCalendar.date(2026, 9, 18, 19, 30)

        // When the windows are planned
        let planned = windows(evaluation)

        // Then today runs from local midnight to 19:30, and the 14 completed days before it each
        // run from their own midnight to their own 19:30, oldest first
        #expect(planned.today == DateInterval(start: TestCalendar.date(2026, 9, 18), end: evaluation))
        #expect(planned.history.count == 14)

        let first = try #require(planned.history.first)
        let last = try #require(planned.history.last)
        #expect(first == DateInterval(
            start: TestCalendar.date(2026, 9, 4),
            end: TestCalendar.date(2026, 9, 4, 19, 30)
        ))
        #expect(last == DateInterval(
            start: TestCalendar.date(2026, 9, 17),
            end: TestCalendar.date(2026, 9, 17, 19, 30)
        ))
    }

    @Test("At midnight today's window is empty rather than a whole day")
    func midnightGivesAnEmptyTodayWindow() {
        // Given an evaluation at exactly local midnight
        let evaluation = TestCalendar.date(2026, 9, 18)

        // When the windows are planned
        let planned = windows(evaluation)

        // Then nothing has accumulated yet — which is a real answer, not missing data
        #expect(planned.today.duration == 0)
        #expect(planned.today.start == evaluation)
    }

    @Test("The day the clocks go forward is an hour shorter, and the window follows")
    func springForwardShortensTheWindow() throws {
        // Given an evaluation at 04:00 on 30 March 2026, the day after Spain loses an hour
        let evaluation = TestCalendar.date(2026, 3, 30, 4)

        // When the windows are planned
        let planned = windows(evaluation)

        // Then the window for 29 March runs midnight to 04:00 but lasts three hours, because
        // 02:00 to 03:00 did not exist that day
        let springForward = try #require(planned.history.last)
        #expect(springForward.start == TestCalendar.date(2026, 3, 29))
        #expect(springForward.duration == 3 * 3600)
    }

    @Test("The day the clocks go back is an hour longer, and the window follows")
    func fallBackLengthensTheWindow() throws {
        // Given an evaluation at 04:00 on 26 October 2026, the day after Spain gains an hour
        let evaluation = TestCalendar.date(2026, 10, 26, 4)

        // When the windows are planned
        let planned = windows(evaluation)

        // Then the window for 25 October runs midnight to 04:00 but lasts five hours, because
        // 02:00 to 03:00 happened twice
        let fallBack = try #require(planned.history.last)
        #expect(fallBack.start == TestCalendar.date(2026, 10, 25))
        #expect(fallBack.duration == 5 * 3600)
    }

    @Test("The same instant belongs to different days in different time zones")
    func timeZoneDecidesTheDayBoundaries() {
        // Given one instant — 19:30 in Madrid on 18 September 2026
        let instant = TestCalendar.date(2026, 9, 18, 19, 30)
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt

        // When the same instant is planned in each zone
        let madrid = windows(instant)
        let abroad = windows(instant, calendar: newYork)

        // Then the local day it falls in starts at a different moment, so today's window is a
        // different length. A snapshot therefore has to record the zone it was decided in.
        #expect(madrid.today.start != abroad.today.start)
        #expect(madrid.today.duration != abroad.today.duration)
    }
}
