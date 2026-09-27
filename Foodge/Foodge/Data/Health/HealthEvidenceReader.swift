//
//  HealthEvidenceReader.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// Assembles one evaluation's evidence from a sample source.
///
/// It reads today's six figures and hands the raw sleep intervals to the domain to union.
/// Everything it cannot read stays `nil` and is reported as missing — never as zero, and never as a
/// denial, because HealthKit cannot tell absence from denial.
///
/// The fourteen historical windows went with D111. That drops this from fifteen statistics queries
/// per evaluation to one set of six, which is also the cheapest available fix for the ~51-second
/// verdict recorded in WU-25-A.
struct HealthEvidenceReader: HealthEvidenceProvider {
    private let source: any HealthSampleSource

    init(source: any HealthSampleSource) {
        self.source = source
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
                availability: .healthUnavailable,
                context: context,
                constraints: constraints
            )
        }

        let window = EvidenceWindowPlanner.today(evaluation: date, calendar: calendar)
        let today = try await todayAggregates(in: window, readAt: date)

        return EvidenceSnapshot(
            evaluatedAt: date,
            timeZoneIdentifier: calendar.timeZone.identifier,
            today: today,
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

    /// Sleep is read from the previous evening rather than from midnight, because the night that
    /// matters to tonight's dinner started yesterday (D16 — the half of it that survives D111).
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
