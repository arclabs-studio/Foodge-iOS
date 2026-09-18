//
//  HealthEvidenceReader.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// Assembles one evaluation's evidence from a sample source.
///
/// It reads today's figures and the same-clock-time figure for each of the previous days, then
/// hands the raw sleep intervals to the domain to union. Everything it cannot read stays `nil`
/// and is reported as missing — never as zero, and never as a denial.
struct HealthEvidenceReader: HealthEvidenceProvider {
    private let source: any HealthSampleSource
    private let historyDays: Int

    init(source: any HealthSampleSource, historyDays: Int = 14) {
        self.source = source
        self.historyDays = historyDays
    }

    func snapshot(
        at date: Date,
        calendar: Calendar,
        context: DailyContext,
        constraints: DietaryConstraints
    ) async throws -> EvidenceSnapshot {
        // Nothing is asked of the source when the device has no Health data at all.
        guard source.isAvailable() else {
            return EvidenceSnapshot(
                evaluatedAt: date,
                timeZoneIdentifier: calendar.timeZone.identifier,
                today: .empty,
                history: [],
                availability: .healthUnavailable,
                context: context,
                constraints: constraints
            )
        }

        let windows = EvidenceWindowPlanner.windows(
            evaluation: date,
            calendar: calendar,
            historyDays: historyDays
        )

        // Today and the fortnight share nothing, so they are read together rather than one after
        // the other: the cost is the slower of the two, not their sum.
        async let todayAggregates = todayAggregates(in: windows.today, readAt: date)
        async let historyObservations = history(for: windows.history)

        let today = try await todayAggregates
        let history = try await historyObservations

        return EvidenceSnapshot(
            evaluatedAt: date,
            timeZoneIdentifier: calendar.timeZone.identifier,
            today: today,
            history: history,
            availability: .readable(missing: missingKinds(in: today)),
            context: context,
            constraints: constraints
        )
    }

    private func todayAggregates(in window: DateInterval, readAt: Date) async throws -> HealthAggregates {
        async let activeEnergy = source.cumulativeSum(of: .activeEnergy, in: window)
        async let restingEnergy = source.cumulativeSum(of: .restingEnergy, in: window)
        async let steps = source.cumulativeSum(of: .steps, in: window)
        async let dietaryEnergy = source.cumulativeSum(of: .dietaryEnergy, in: window)
        async let sleepIntervals = source.asleepIntervals(in: sleepWindow(endingAt: window.end))
        async let workouts = source.workouts(in: window)

        let provenance = Provenance(sourceNames: [], readAt: readAt, window: window)
        let intervals = try await sleepIntervals

        return HealthAggregates(
            activeEnergy: try await activeEnergy.map {
                EnergyAggregate(kilocalories: $0, provenance: provenance)
            },
            restingEnergy: try await restingEnergy.map {
                EnergyAggregate(kilocalories: $0, provenance: provenance)
            },
            steps: try await steps.map {
                StepAggregate(count: $0, provenance: provenance)
            },
            sleep: intervals.map { intervals in
                SleepAggregate(
                    // The union, not the sum: overlapping records would otherwise invent hours.
                    asleepDuration: SleepIntervalUnion.duration(of: intervals),
                    intervalCount: intervals.count,
                    provenance: provenance
                )
            },
            workouts: try await workouts,
            dietaryEnergy: try await dietaryEnergy.map {
                EnergyAggregate(kilocalories: $0, provenance: provenance)
            }
        )
    }

    /// Reads every historical window concurrently, keeping each result aligned with its day.
    private func history(for windows: [DateInterval]) async throws -> [DailyActivityObservation] {
        try await withThrowingTaskGroup(of: (Int, DailyActivityObservation).self) { group in
            for (index, window) in windows.enumerated() {
                group.addTask {
                    try Task.checkCancellation()
                    async let energy = source.cumulativeSum(of: .activeEnergy, in: window)
                    async let steps = source.cumulativeSum(of: .steps, in: window)
                    return (
                        index,
                        DailyActivityObservation(
                            day: window.start,
                            activeEnergyAtCutoff: try await energy,
                            stepsAtCutoff: try await steps
                        )
                    )
                }
            }

            // Results arrive in completion order, so they are put back in window order here: an
            // observation attributed to the wrong day would quietly corrupt the baseline.
            var observations = [DailyActivityObservation?](repeating: nil, count: windows.count)
            for try await (index, observation) in group {
                observations[index] = observation
            }

            // Every slot must be filled. Quietly dropping a gap would hand the baseline a short
            // history that looks complete, and the median would be computed over the wrong days.
            return try observations.map { observation in
                guard let observation else { throw FoodgeError.evidenceUnreadable }
                return observation
            }
        }
    }

    /// Sleep is read from the previous evening rather than from midnight, because the night that
    /// matters to tonight's dinner started yesterday (D16).
    private func sleepWindow(endingAt end: Date) -> DateInterval {
        let start = end.addingTimeInterval(-Self.sleepLookBack)
        return DateInterval(start: min(start, end), end: end)
    }

    /// 30 hours back, which reaches the previous evening from any evaluation time.
    private static let sleepLookBack: TimeInterval = 30 * 60 * 60

    private func missingKinds(in aggregates: HealthAggregates) -> Set<HealthKind> {
        var missing: Set<HealthKind> = []
        if aggregates.activeEnergy == nil { missing.insert(.activeEnergy) }
        if aggregates.restingEnergy == nil { missing.insert(.restingEnergy) }
        if aggregates.steps == nil { missing.insert(.steps) }
        if aggregates.sleep == nil { missing.insert(.sleep) }
        if aggregates.workouts == nil { missing.insert(.workouts) }
        if aggregates.dietaryEnergy == nil { missing.insert(.dietaryEnergy) }
        return missing
    }
}
