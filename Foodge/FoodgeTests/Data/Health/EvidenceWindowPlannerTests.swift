//
//  EvidenceWindowPlannerTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// The calendar rules that survive D111: today runs from local midnight, and a local day is never
/// assumed to be 86,400 seconds long. Spain's 2026 transitions are 29 March (clocks go forward, the
/// day is 23 hours) and 25 October (clocks go back, the day is 25 hours).
///
/// The fortnight of history is gone, so what is left here is the pair the resting-energy proration
/// depends on — today's window, and the real length of the day it sits in.
@Suite("Evidence window planner", .tags(.unit, .domain, .critical))
struct EvidenceWindowPlannerTests {

    private func today(_ evaluation: Date, calendar: Calendar = TestCalendar.madrid) -> DateInterval {
        EvidenceWindowPlanner.today(evaluation: evaluation, calendar: calendar)
    }

    @Test("Today runs from local midnight to the evaluation instant")
    func todayStartsAtLocalMidnight() {
        // Given an evaluation at 19:30 on 18 September 2026
        let evaluation = TestCalendar.date(2026, 9, 18, 19, 30)

        // When the window is planned
        let window = today(evaluation)

        // Then it starts at that day's own midnight and ends where the evaluation does
        #expect(window == DateInterval(start: TestCalendar.date(2026, 9, 18), end: evaluation))
        #expect(window.duration == 19.5 * 3600)
    }

    @Test("At midnight today's window is empty rather than a whole day")
    func midnightGivesAnEmptyTodayWindow() {
        // Given an evaluation at exactly local midnight
        let evaluation = TestCalendar.date(2026, 9, 18)

        // When the window is planned
        let window = today(evaluation)

        // Then nothing has accumulated yet — which is a real answer, not missing data
        #expect(window.duration == 0)
        #expect(window.start == evaluation)
    }

    @Test("The window never inverts, whatever instant it is handed")
    func anInstantBeforeMidnightCannotInvertTheWindow() {
        // Given an instant one second before its own local midnight, which no clock should produce
        let midnight = TestCalendar.date(2026, 9, 18)
        let before = midnight.addingTimeInterval(-1)

        // When the window is planned for it
        let window = today(before)

        // Then the window is empty rather than negative: 17 September's midnight to that instant
        #expect(window.duration >= 0)
        #expect(window.end >= window.start)
    }

    @Test("The day the clocks go forward is 23 hours long")
    func springForwardShortensTheLocalDay() throws {
        // Given an instant on 29 March 2026, the day Spain loses an hour
        let instant = TestCalendar.date(2026, 3, 29, 3, 10)

        // When the local day is asked for
        let day = try #require(
            EvidenceWindowPlanner.localDay(containing: instant, calendar: TestCalendar.madrid)
        )

        // Then it is 23 hours, which is the denominator the resting estimate prorates against
        #expect(day.start == TestCalendar.date(2026, 3, 29))
        #expect(day.duration == 23 * 3600)
    }

    @Test("The day the clocks go back is 25 hours long")
    func fallBackLengthensTheLocalDay() throws {
        // Given an instant on 25 October 2026, the day Spain gains an hour
        let instant = TestCalendar.date(2026, 10, 25, 19, 30)

        // When the local day is asked for
        let day = try #require(
            EvidenceWindowPlanner.localDay(containing: instant, calendar: TestCalendar.madrid)
        )

        // Then it is 25 hours
        #expect(day.start == TestCalendar.date(2026, 10, 25))
        #expect(day.duration == 25 * 3600)
    }

    @Test("An ordinary day really is 86,400 seconds, so the tests above are about the calendar")
    func anOrdinaryDayIsTwentyFourHours() throws {
        let day = try #require(
            EvidenceWindowPlanner.localDay(
                containing: TestCalendar.date(2026, 9, 18, 19, 30),
                calendar: TestCalendar.madrid
            )
        )

        #expect(day.duration == 86_400)
    }

    @Test("The same instant belongs to different days in different time zones")
    func timeZoneDecidesTheDayBoundaries() {
        // Given one instant — 19:30 in Madrid on 18 September 2026
        let instant = TestCalendar.date(2026, 9, 18, 19, 30)
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt

        // When the same instant is planned in each zone
        let madrid = today(instant)
        let abroad = today(instant, calendar: newYork)

        // Then the local day it falls in starts at a different moment, so today's window is a
        // different length. A snapshot therefore has to record the zone it was decided in.
        #expect(madrid.start != abroad.start)
        #expect(madrid.duration != abroad.duration)
    }
}
