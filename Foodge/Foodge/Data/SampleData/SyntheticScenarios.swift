//
//  SyntheticScenarios.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// One clearly labelled demonstration case.
///
/// Every snapshot here is invented. Nothing in this file is anyone's health data, and the
/// snapshots carry `isSynthetic` so the interface can say so wherever they are shown.
struct SyntheticScenario: Hashable, Sendable, Identifiable {
    let id: String
    let clock: FixedClock
    let snapshot: EvidenceSnapshot
}

/// The fixed set of scenarios used by previews, tests and demonstration mode.
///
/// They are all evaluated at 19:30 on 18 September 2026 in Europe/Madrid, except the
/// daylight-saving case, so their numbers can be compared against hand-computed expectations.
enum SyntheticScenarios {
    static let timeZoneIdentifier = "Europe/Madrid"

    /// A Gregorian calendar pinned to an explicit time zone, never `.autoupdatingCurrent`.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .gmt
        return calendar
    }()

    /// 18 September 2026, 19:30 local.
    static let evaluationDate = date(year: 2026, month: 9, day: 18, hour: 19, minute: 30)

    static let clock = FixedClock(now: evaluationDate, calendar: calendar)

    /// 29 March 2026, 03:10 local — the morning Spain loses an hour, so this local day is 23
    /// hours long and the window since midnight is 2 h 10 min of wall time, not 3 h 10 min.
    static let springForwardDate = date(year: 2026, month: 3, day: 29, hour: 3, minute: 10)

    static let springForwardClock = FixedClock(now: springForwardDate, calendar: calendar)

    /// Builds a date from fixed components in ``calendar``.
    ///
    /// The fallback is unreachable for the literal components used here; it exists so that sample
    /// data never force-unwraps, and a wrong date would be glaringly visible rather than a crash.
    static func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? .distantPast
    }

    /// The window from local midnight up to an evaluation instant.
    static func windowSinceMidnight(endingAt end: Date) -> DateInterval {
        DateInterval(start: calendar.startOfDay(for: end), end: end)
    }

    static func provenance(endingAt end: Date) -> Provenance {
        Provenance(
            sourceNames: ["Foodge demonstration data"],
            readAt: end,
            window: windowSinceMidnight(endingAt: end)
        )
    }

    static func energy(_ kilocalories: Double, endingAt end: Date = evaluationDate) -> EnergyAggregate {
        EnergyAggregate(kilocalories: kilocalories, provenance: provenance(endingAt: end))
    }

    static func steps(_ count: Double, endingAt end: Date = evaluationDate) -> StepAggregate {
        StepAggregate(count: count, provenance: provenance(endingAt: end))
    }

    static func sleep(hours: Int, minutes: Int, intervalCount: Int = 1) -> SleepAggregate {
        SleepAggregate(
            asleepDuration: .seconds(hours * 3600 + minutes * 60),
            intervalCount: intervalCount,
            provenance: provenance(endingAt: evaluationDate)
        )
    }

    // MARK: - Scenarios

    /// 520 kcal against a 400 kcal pattern: comfortably a treat.
    static let activeDay = SyntheticScenario(
        id: "activeDay",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(520),
                restingEnergy: energy(1450),
                steps: steps(11_200),
                sleep: sleep(hours: 7, minutes: 40),
                workouts: [
                    WorkoutSummary(
                        id: UUID(uuidString: "0B9A1C4E-0001-4000-8000-000000000001") ?? UUID(),
                        activityName: "Running",
                        interval: DateInterval(
                            start: date(year: 2026, month: 9, day: 18, hour: 8, minute: 0),
                            end: date(year: 2026, month: 9, day: 18, hour: 8, minute: 45)
                        )
                    )
                ],
                dietaryEnergy: nil
            ),
            history: fullyTrackedHistory,
            availability: .readable(missing: [.dietaryEnergy]),
            isSynthetic: true
        )
    )

    /// 410 kcal against 400 kcal: inside the band, so balanced.
    static let typicalDay = SyntheticScenario(
        id: "typicalDay",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(410),
                restingEnergy: energy(1440),
                steps: steps(8400),
                sleep: sleep(hours: 7, minutes: 15),
                workouts: [],
                dietaryEnergy: nil
            ),
            history: fullyTrackedHistory,
            availability: .readable(missing: [.dietaryEnergy]),
            isSynthetic: true
        )
    )

    /// 180 kcal against 400 kcal, with the user confirming the tracking reflects the day.
    static let restDay = SyntheticScenario(
        id: "restDay",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(180),
                restingEnergy: energy(1430),
                steps: steps(3100),
                sleep: sleep(hours: 8, minutes: 5),
                workouts: [],
                dietaryEnergy: nil
            ),
            history: fullyTrackedHistory,
            availability: .readable(missing: [.dietaryEnergy]),
            trackingRepresentative: true,
            isSynthetic: true
        )
    )

    /// Nothing readable at all: the fallback path has to carry the whole experience.
    static let noHealthData = SyntheticScenario(
        id: "noHealthData",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: .none,
            history: [],
            availability: .readable(missing: Set(HealthKind.allCases)),
            isSynthetic: true
        )
    )

    /// A low reading the user has said is not representative, so the pattern must not be used.
    static let partialTracking = SyntheticScenario(
        id: "partialTracking",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(150),
                restingEnergy: nil,
                steps: steps(2600),
                sleep: nil,
                workouts: [],
                dietaryEnergy: nil
            ),
            history: fullyTrackedHistory,
            availability: .readable(missing: [.restingEnergy, .sleep, .dietaryEnergy]),
            trackingRepresentative: false,
            isSynthetic: true
        )
    )

    /// Energy is recorded on only three days, so the comparison falls back to steps.
    static let stepsFallback = SyntheticScenario(
        id: "stepsFallback",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: nil,
                restingEnergy: nil,
                steps: steps(9000),
                sleep: sleep(hours: 6, minutes: 50),
                workouts: [],
                dietaryEnergy: nil
            ),
            history: observations(
                days: historyDays,
                energy: [410, 430, 390],
                steps: typicalStepsAtCutoff
            ),
            availability: .readable(missing: [.activeEnergy, .restingEnergy, .dietaryEnergy]),
            isSynthetic: true
        )
    )

    /// A typical day's activity on 5 h 10 min of sleep, which should steer the pick inside the
    /// category towards something easier without deducting anything.
    static let shortSleep = SyntheticScenario(
        id: "shortSleep",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(410),
                restingEnergy: energy(1440),
                steps: steps(8300),
                sleep: sleep(hours: 5, minutes: 10, intervalCount: 3),
                workouts: [],
                dietaryEnergy: nil
            ),
            history: fullyTrackedHistory,
            availability: .readable(missing: [.dietaryEnergy]),
            context: DailyContext(energyLevel: .low),
            isSynthetic: true
        )
    )

    /// An evaluation inside the hour Spain skips, to prove the windows are calendar-aware.
    static let dstSpringForward = SyntheticScenario(
        id: "dstSpringForward",
        clock: springForwardClock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: springForwardDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(25, endingAt: springForwardDate),
                restingEnergy: nil,
                steps: steps(310, endingAt: springForwardDate),
                sleep: nil,
                workouts: [],
                dietaryEnergy: nil
            ),
            history: observations(
                days: springForwardHistoryDays,
                energy: springForwardEnergyAtCutoff.map { $0 },
                steps: []
            ),
            availability: .readable(missing: [.restingEnergy, .sleep, .dietaryEnergy]),
            isSynthetic: true
        )
    )

    /// Every scenario, in the order demonstration mode offers them.
    static let all: [SyntheticScenario] = [
        activeDay,
        typicalDay,
        restDay,
        noHealthData,
        partialTracking,
        stepsFallback,
        shortSleep,
        dstSpringForward
    ]
}
