//
//  SleepIntervalUnionTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// Health reports sleep as overlapping records — several sources, and stages nested inside a
/// longer span. Adding their durations would invent hours the user never slept, so the only
/// correct answer is the union.
@Suite("Sleep interval union", .tags(.unit, .domain, .critical))
struct SleepIntervalUnionTests {

    private func interval(
        from startHour: Int,
        _ startMinute: Int = 0,
        to endHour: Int,
        _ endMinute: Int = 0,
        startingOn startDay: Int = 17,
        endingOn endDay: Int = 18
    ) -> DateInterval {
        DateInterval(
            start: TestCalendar.date(2026, 9, startDay, startHour, startMinute),
            end: TestCalendar.date(2026, 9, endDay, endHour, endMinute)
        )
    }

    @Test("Two overlapping records count as the span they cover, not their sum")
    func overlappingRecordsAreMerged() {
        // Given a 4 h record and a 4 h 30 min record that overlap between 02:00 and 03:00
        let intervals = [
            interval(from: 23, to: 3),
            interval(from: 2, to: 6, 30, startingOn: 18, endingOn: 18)
        ]

        // When the union is taken
        let duration = SleepIntervalUnion.duration(of: intervals)

        // Then the answer is 23:00 to 06:30 — 7 h 30 min, not the 8 h 30 min their sum would give
        #expect(duration == .seconds(7 * 3600 + 30 * 60))
    }

    @Test("Stages recorded inside a longer span add nothing to it")
    func containedIntervalsAddNothing() {
        // Given one 4 h span with three sleep stages recorded inside it
        let intervals = [
            interval(from: 23, to: 3),
            interval(from: 23, 20, to: 0, 40, endingOn: 18),
            interval(from: 0, 40, to: 2, 10, startingOn: 18, endingOn: 18),
            interval(from: 2, 10, to: 2, 55, startingOn: 18, endingOn: 18)
        ]

        // When the union is taken
        let duration = SleepIntervalUnion.duration(of: intervals)

        // Then the night is still 4 h long
        #expect(duration == .seconds(4 * 3600))
    }

    @Test("Records arriving out of order are still merged")
    func unsortedRecordsAreMerged() {
        // Given the same night as above, but handed back newest first — which is what a query
        // sorted by start date descending returns
        let intervals = [
            interval(from: 2, to: 6, 30, startingOn: 18, endingOn: 18),
            interval(from: 23, to: 3)
        ]

        // When the union is taken
        let duration = SleepIntervalUnion.duration(of: intervals)

        // Then arrival order changes nothing: still 23:00 to 06:30, 7 h 30 min. An
        // implementation that merges without sorting first anchors on 02:00 and reports 4 h 30.
        #expect(duration == .seconds(7 * 3600 + 30 * 60))
    }

    @Test("Records that do not touch are added together")
    func disjointRecordsAreSummed() {
        // Given a 2 h record and a 1 h record with an hour awake between them
        let intervals = [
            interval(from: 23, to: 1),
            interval(from: 2, to: 3, startingOn: 18, endingOn: 18)
        ]

        // When the union is taken
        let duration = SleepIntervalUnion.duration(of: intervals)

        // Then the gap is not counted as sleep: 3 h in total
        #expect(duration == .seconds(3 * 3600))
    }

    @Test("A night with no records is zero, and says so without failing")
    func noRecordsIsZero() {
        // Given nothing recorded
        // When the union is taken
        let duration = SleepIntervalUnion.duration(of: [])

        // Then the duration is zero. The caller is what decides whether that means "slept
        // nothing" or "nothing readable"; this function only reports the union it was given.
        #expect(duration == .zero)
    }
}
