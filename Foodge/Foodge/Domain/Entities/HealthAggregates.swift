//
//  HealthAggregates.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Where a reading came from and the exact window it covers.
///
/// Every number Foodge shows has to be traceable to one of these.
struct Provenance: Hashable, Codable, Sendable {
    let sourceNames: [String]
    let readAt: Date
    let window: DateInterval
}

/// A summed energy reading in kilocalories.
///
/// Used for active energy, resting energy and dietary energy, which are always kept apart and
/// never added together into a single "budget".
struct EnergyAggregate: Hashable, Codable, Sendable {
    let kilocalories: Double
    let provenance: Provenance
}

/// A summed step count.
struct StepAggregate: Hashable, Codable, Sendable {
    let count: Double
    let provenance: Provenance
}

/// Time asleep over a window, already reduced to the union of the asleep intervals.
///
/// `intervalCount` is how many raw intervals contributed, which is what lets the evidence screen
/// say how fragmented the night was without storing the raw series.
struct SleepAggregate: Hashable, Codable, Sendable {
    let asleepDuration: Duration
    let intervalCount: Int
    let provenance: Provenance
}

/// One recorded workout.
///
/// Deliberately carries no energy value: workout calories are already inside active energy and
/// must never be added a second time.
struct WorkoutSummary: Hashable, Codable, Sendable, Identifiable {
    let id: UUID
    let activityName: String
    let interval: DateInterval
}

/// Everything Foodge managed to read from Health for one evaluation.
///
/// Every field is optional on purpose: a missing sample stays missing and is never turned into
/// zero activity or zero intake.
struct HealthAggregates: Hashable, Codable, Sendable {
    let activeEnergy: EnergyAggregate?
    let restingEnergy: EnergyAggregate?
    let steps: StepAggregate?
    let sleep: SleepAggregate?
    let workouts: [WorkoutSummary]?
    let dietaryEnergy: EnergyAggregate?

    static let none = HealthAggregates(
        activeEnergy: nil,
        restingEnergy: nil,
        steps: nil,
        sleep: nil,
        workouts: nil,
        dietaryEnergy: nil
    )
}
