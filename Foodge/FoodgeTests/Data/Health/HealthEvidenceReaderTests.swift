//
//  HealthEvidenceReaderTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// The reader's contract: absent is not zero, overlapping sleep is unioned rather than summed,
/// workout energy is never re-added, and a device without Health is asked nothing at all.
@Suite("Health evidence reader", .tags(.unit, .critical))
struct HealthEvidenceReaderTests {

    private let evaluation = TestCalendar.date(2026, 9, 18, 19, 30)
    private var midnight: Date { TestCalendar.date(2026, 9, 18) }

    private func snapshot(from source: FixtureHealthSampleSource) async throws -> EvidenceSnapshot {
        try await HealthEvidenceReader(source: source).snapshot(
            at: evaluation,
            calendar: TestCalendar.madrid,
            context: .empty,
            constraints: .unrestricted
        )
    }

    @Test("A quantity that reads back nothing stays missing")
    func anUnreadableQuantityIsMissingNotZero() async throws {
        // Given a source with no active energy for today
        let source = FixtureHealthSampleSource(todayStart: midnight, today: .init(steps: 4000))

        // When the snapshot is read
        let snapshot = try await snapshot(from: source)

        // Then the aggregate is absent, and availability names it as unreadable — which is not
        // the same as the user having denied it
        #expect(snapshot.today.activeEnergy == nil)
        #expect(snapshot.availability == .readable(missing: [
            .activeEnergy, .restingEnergy, .sleep, .workouts, .dietaryEnergy
        ]))
    }

    @Test("A recorded zero is kept as zero")
    func aRecordedZeroSurvives() async throws {
        // Given a day where Health genuinely recorded no active energy, as the figure 0
        let source = FixtureHealthSampleSource(todayStart: midnight, today: .init(activeEnergy: 0))

        // When the snapshot is read
        let snapshot = try await snapshot(from: source)

        // Then zero is carried through as a real reading rather than collapsed into missing
        #expect(snapshot.today.activeEnergy?.kilocalories == 0)
    }

    @Test("A workout is listed without its energy being counted again")
    func workoutEnergyIsNotAddedTwice() async throws {
        // Given 350 kcal of active energy and one recorded workout inside it
        let workout = WorkoutSummary(
            id: UUID(),
            activityName: "Running",
            interval: DateInterval(
                start: TestCalendar.date(2026, 9, 18, 8),
                end: TestCalendar.date(2026, 9, 18, 8, 45)
            )
        )
        let source = FixtureHealthSampleSource(
            todayStart: midnight,
            today: .init(activeEnergy: 350, workouts: [workout])
        )

        // When the snapshot is read
        let snapshot = try await snapshot(from: source)

        // Then active energy is still 350: the workout is context, not an addition
        #expect(snapshot.today.activeEnergy?.kilocalories == 350)
        #expect(snapshot.today.workouts?.count == 1)
    }

    @Test("Overlapping sleep records are unioned, not summed")
    func overlappingSleepIsUnioned() async throws {
        // Given two overlapping asleep records, 4 h and 4 h 30, sharing an hour
        let source = FixtureHealthSampleSource(
            todayStart: midnight,
            today: .init(sleep: [
                DateInterval(
                    start: TestCalendar.date(2026, 9, 17, 23),
                    end: TestCalendar.date(2026, 9, 18, 3)
                ),
                DateInterval(
                    start: TestCalendar.date(2026, 9, 18, 2),
                    end: TestCalendar.date(2026, 9, 18, 6, 30)
                )
            ])
        )

        // When the snapshot is read
        let snapshot = try await snapshot(from: source)

        // Then the night is the 7 h 30 they cover, not the 8 h 30 they add up to
        #expect(snapshot.today.sleep?.asleepDuration == .seconds(7 * 3600 + 30 * 60))
        #expect(snapshot.today.sleep?.intervalCount == 2)
    }

    @Test("A device without Health is not asked for anything")
    func anUnavailableDeviceIsNeverQueried() async throws {
        // Given a device where Health data is unavailable entirely
        let source = FixtureHealthSampleSource(available: false, todayStart: midnight)

        // When the snapshot is read
        let snapshot = try await snapshot(from: source)

        // Then it says so, and no query was issued
        #expect(snapshot.availability == .healthUnavailable)
        #expect(snapshot.today == .empty)
        #expect(snapshot.history.isEmpty)
        let calls = await source.dataCallCount
        #expect(calls == 0)
    }

    @Test("Every historical reading stays attached to its own day")
    func historyReadingsStayAlignedWithTheirDays() async throws {
        // Given a distinct energy figure on each of the 14 previous days, read concurrently
        let planned = EvidenceWindowPlanner.windows(
            evaluation: evaluation,
            calendar: TestCalendar.madrid,
            historyDays: 14
        )
        var scripted: [Date: Double] = [:]
        var delays: [Date: Duration] = [:]
        for (index, window) in planned.history.enumerated() {
            scripted[window.start] = Double(100 + index)
            // The earliest day answers last, so results provably arrive out of submission order.
            // Without this the reads never suspend and a serial loop would pass this test too.
            delays[window.start] = .milliseconds(index == 0 ? 60 : 1)
        }
        let source = FixtureHealthSampleSource(
            todayStart: midnight,
            historyEnergy: scripted,
            historyDelays: delays
        )

        // When the snapshot is read
        let snapshot = try await snapshot(from: source)

        // Then each day carries its own figure: concurrency must not shuffle a reading onto the
        // wrong day, which would silently corrupt the baseline
        #expect(snapshot.history.count == 14)
        for (index, observation) in snapshot.history.enumerated() {
            #expect(observation.day == planned.history[index].start)
            #expect(observation.activeEnergyAtCutoff == Double(100 + index))
        }
    }
}
