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

/// The fixed set of scenarios previews, tests and demonstration mode are fed from.
///
/// They are all evaluated at 19:30 on 18 September 2026 in Europe/Madrid, except the
/// daylight-saving case, so their figures can be checked against hand-computed expectations.
///
/// **Every number here is chosen so the share comes out round.** Maintenance is resting + active
/// and the share is `(maintenance − intake) / maintenance`, so each scenario's arithmetic is
/// written out in its own doc comment and `DemonstrationScenarioOutcomeTests` checks the band it
/// lands in rather than trusting the comment.
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

    /// The body behind every estimated resting figure here: a 35-year-old man, 175 cm, 70 kg, whose
    /// Mifflin–St Jeor daily figure is 1623.75 kcal.
    ///
    /// Force-unwrapping is forbidden, so an implausible literal would leave the scenario with no
    /// body rather than crash — and `DemonstrationScenarioOutcomeTests` would fail on the missing
    /// resting basis rather than pass quietly.
    static let body = BodyBasics(
        sex: .male,
        ageYears: 35,
        heightCentimetres: 175,
        weightKilograms: 70
    )

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

    /// One invented morning run, for the scenario that demonstrates a strong day.
    static let morningRun = WorkoutSummary(
        id: UUID(uuidString: "0B9A1C4E-0001-4000-8000-000000000001") ?? UUID(),
        activityName: "Running",
        interval: DateInterval(
            start: date(year: 2026, month: 9, day: 18, hour: 8, minute: 0),
            end: date(year: 2026, month: 9, day: 18, hour: 8, minute: 45)
        )
    )

    // MARK: - Scenarios

    /// Resting 1200 + active 600 = 1800 maintenance, 990 eaten: an allowance of 810, a share of
    /// 0.45 — comfortably a treat, with a recorded workout to remark on.
    static let generousAllowance = SyntheticScenario(
        id: "generousAllowance",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(600),
                restingEnergy: energy(1200),
                steps: steps(14_000),
                sleep: sleep(hours: 7, minutes: 40),
                workouts: [morningRun],
                dietaryEnergy: energy(990)
            ),
            availability: .readable(missing: []),
            isSynthetic: true
        )
    )

    /// Resting 1600 + active 400 = 2000 maintenance, 1460 eaten: an allowance of 540, a share of
    /// 0.27 — an ordinary day, squarely balanced.
    static let modestAllowance = SyntheticScenario(
        id: "modestAllowance",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(400),
                restingEnergy: energy(1600),
                steps: steps(8400),
                sleep: sleep(hours: 7, minutes: 15),
                workouts: [],
                dietaryEnergy: energy(1460)
            ),
            availability: .readable(missing: []),
            isSynthetic: true
        )
    )

    /// Resting 1350 + active 150 = 1500 maintenance, 1320 eaten: an allowance of 180, a share of
    /// 0.12 — a quiet day and a heavy lunch, so dinner is light.
    static let slimAllowance = SyntheticScenario(
        id: "slimAllowance",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(150),
                restingEnergy: energy(1350),
                steps: steps(3100),
                sleep: sleep(hours: 8, minutes: 5),
                workouts: [],
                dietaryEnergy: energy(1320)
            ),
            availability: .readable(missing: []),
            isSynthetic: true
        )
    )

    /// Resting 1400 + active 200 = 1600 maintenance, 2100 eaten: an allowance of **−500**, a share
    /// of −0.3125. Light, and a dish is still recommended — a negative result never suppresses
    /// dinner.
    static let allowanceSpent = SyntheticScenario(
        id: "allowanceSpent",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(200),
                restingEnergy: energy(1400),
                steps: steps(5200),
                sleep: sleep(hours: 7, minutes: 0),
                workouts: [],
                dietaryEnergy: energy(2100)
            ),
            availability: .readable(missing: []),
            isSynthetic: true
        )
    )

    /// No `basalEnergyBurned` at all, so Mifflin–St Jeor supplies resting from the body basics:
    /// 1623.75 × 19.5/24 = 1319.30, plus 400 active = 1719.30 maintenance, 1250 eaten — an
    /// allowance of 469.30 and a share of 0.27, balanced, labelled as an estimate.
    static let estimatedResting = SyntheticScenario(
        id: "estimatedResting",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(400),
                restingEnergy: nil,
                steps: steps(8400),
                sleep: sleep(hours: 7, minutes: 15),
                workouts: [],
                dietaryEnergy: energy(1250)
            ),
            availability: .readable(missing: [.restingEnergy]),
            body: body,
            isSynthetic: true
        )
    )

    /// No `dietaryEnergy`, so the questionnaire supplies intake: a light breakfast (200) and a
    /// normal lunch (650) is 850 against resting 1200 + active 600 = 1800 maintenance — an
    /// allowance of 950, a share of 0.53, a treat labelled as an estimate.
    static let estimatedIntake = SyntheticScenario(
        id: "estimatedIntake",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(600),
                restingEnergy: energy(1200),
                steps: steps(10_500),
                sleep: sleep(hours: 7, minutes: 30),
                workouts: [],
                dietaryEnergy: nil
            ),
            availability: .readable(missing: [.dietaryEnergy]),
            intake: IntakeQuestionnaire(breakfast: .light, lunch: .normal),
            isSynthetic: true
        )
    )

    /// Nothing readable at all: the self-report fallback has to carry the whole experience, because
    /// a day with no active energy cannot be given a number without inventing one.
    static let noHealthData = SyntheticScenario(
        id: "noHealthData",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: .empty,
            availability: .readable(missing: Set(HealthKind.allCases)),
            isSynthetic: true
        )
    )

    /// The same figures as ``modestAllowance`` on four hours of broken sleep, and the user says
    /// their energy is low. **The band does not move** — sleep and self-reported energy inform the
    /// explanation only — so this is a balanced verdict carrying two extra reasons.
    static let shortSleep = SyntheticScenario(
        id: "shortSleep",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(400),
                restingEnergy: energy(1600),
                steps: steps(8300),
                sleep: sleep(hours: 4, minutes: 0, intervalCount: 3),
                workouts: [],
                dietaryEnergy: energy(1460)
            ),
            availability: .readable(missing: []),
            context: DailyContext(energyLevel: .low),
            isSynthetic: true
        )
    )

    /// 03:10 on the 23-hour day, with no basal samples: the prorated estimate is
    /// 1623.75 × (3 h 10 min / 23 h) = 223.56, not 214.21 against a 24-hour day. Plus 25 kcal
    /// active that is 248.56 of maintenance, against a questionnaire that says nothing has been
    /// eaten — an answered zero, so the allowance is the whole of it.
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
            availability: .readable(missing: [.restingEnergy, .sleep, .dietaryEnergy]),
            intake: IntakeQuestionnaire(breakfast: .skipped, lunch: .skipped, snacks: .skipped),
            body: body,
            isSynthetic: true
        )
    )

    /// ``modestAllowance``'s figures with constraints — vegan, rice and pasta excluded — that block
    /// every balanced dish, so the pick honestly reports no match (D58). **The allowance figure is
    /// still shown**, which is what makes a no-match night more useful than it used to be.
    static let noCompatibleDish = SyntheticScenario(
        id: "noCompatibleDish",
        clock: clock,
        snapshot: EvidenceSnapshot(
            evaluatedAt: evaluationDate,
            timeZoneIdentifier: timeZoneIdentifier,
            today: HealthAggregates(
                activeEnergy: energy(400),
                restingEnergy: energy(1600),
                steps: steps(8400),
                sleep: sleep(hours: 7, minutes: 15),
                workouts: [],
                dietaryEnergy: energy(1460)
            ),
            availability: .readable(missing: []),
            constraints: DietaryConstraints(
                profile: .vegan,
                excludedIngredientIDs: [Ingredient.rice.id, Ingredient.pasta.id]
            ),
            isSynthetic: true
        )
    )

    /// Every scenario, in the order demonstration mode offers them.
    static let all: [SyntheticScenario] = [
        generousAllowance,
        modestAllowance,
        slimAllowance,
        allowanceSpent,
        estimatedResting,
        estimatedIntake,
        noHealthData,
        shortSleep,
        dstSpringForward,
        noCompatibleDish,
    ]
}
