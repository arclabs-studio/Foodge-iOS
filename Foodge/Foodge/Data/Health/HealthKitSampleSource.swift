//
//  HealthKitSampleSource.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import HealthKit

/// The real HealthKit implementation of ``HealthSampleSource``.
///
/// An actor so the work around each query — building predicates, and filtering and mapping the
/// samples that come back — runs off the caller's actor rather than on the main thread, and so
/// every HealthKit object becomes a plain `Sendable` value before it leaves. Nothing of
/// HealthKit's own vocabulary crosses this boundary.
///
/// - Important: This actor does **not** serialise queries, and must not be read as doing so.
///   Swift actors are reentrant: every method here suspends at `result(for:)`, and the next call
///   is admitted while the first is parked there. That is deliberate — the fourteen historical
///   windows are meant to overlap — but it means no state may be held across an `await`. The type
///   has exactly one stored property, an immutable store, and adding a mutable cache would
///   introduce a race that the current design has no way to show you.
actor HealthKitSampleSource: HealthSampleSource {
    private let store: HKHealthStore

    init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    nonisolated func isAvailable() -> Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// The summed quantity over the window, or `nil` when nothing was readable.
    ///
    /// Uses HealthKit's own statistics rather than adding up raw samples, which would double
    /// count wherever two sources overlap.
    func cumulativeSum(of kind: QuantityKind, in window: DateInterval) async throws -> Double? {
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: quantityType(for: kind), predicate: predicate(for: window)),
            options: .cumulativeSum
        )

        guard let sum = try await descriptor.result(for: store)?.sumQuantity() else {
            // No statistics and no sum both mean "nothing readable". Returning zero here is the
            // single most damaging thing this file could do.
            return nil
        }

        return sum.doubleValue(for: unit(for: kind))
    }

    func asleepIntervals(in window: DateInterval) async throws -> [DateInterval]? {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: HealthReadTypes.sleep, predicate: predicate(for: window))],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )

        let samples = try await descriptor.result(for: store)
        guard !samples.isEmpty else { return nil }

        // Keep only the values that actually mean asleep, so "in bed" and "awake" records cannot
        // inflate the night. Merging the survivors is the domain's job, not this one's.
        let asleep = samples.filter { sample in
            guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return false }
            return HKCategoryValueSleepAnalysis.allAsleepValues.contains(value)
        }

        return asleep.map { DateInterval(start: $0.startDate, end: $0.endDate) }
    }

    func workouts(in window: DateInterval) async throws -> [WorkoutSummary]? {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout(predicate(for: window))],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )

        let workouts = try await descriptor.result(for: store)
        guard !workouts.isEmpty else { return nil }

        return workouts.map { workout in
            WorkoutSummary(
                id: workout.uuid,
                activityName: String(describing: workout.workoutActivityType),
                interval: DateInterval(start: workout.startDate, end: workout.endDate)
            )
        }
    }

    private func predicate(for window: DateInterval) -> NSPredicate {
        HKQuery.predicateForSamples(
            withStart: window.start,
            end: window.end,
            options: [.strictStartDate]
        )
    }

    private func quantityType(for kind: QuantityKind) -> HKQuantityType {
        switch kind {
        case .activeEnergy: HealthReadTypes.activeEnergy
        case .restingEnergy: HealthReadTypes.restingEnergy
        case .steps: HealthReadTypes.steps
        case .dietaryEnergy: HealthReadTypes.dietaryEnergy
        }
    }

    private func unit(for kind: QuantityKind) -> HKUnit {
        switch kind {
        case .activeEnergy, .restingEnergy, .dietaryEnergy: .kilocalorie()
        case .steps: .count()
        }
    }
}
