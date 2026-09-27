//
//  HealthSampleSource.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// The cumulative quantities Foodge sums over a window.
///
/// Each maps to exactly one Health type. They are kept apart deliberately: active, resting and
/// dietary energy are three different facts and are never added into a single budget.
enum QuantityKind: String, CaseIterable, Hashable {
    case activeEnergy
    case restingEnergy
    case steps
    case dietaryEnergy

    /// The availability kind this quantity reports as missing.
    var healthKind: HealthKind {
        switch self {
        case .activeEnergy: .activeEnergy
        case .restingEnergy: .restingEnergy
        case .steps: .steps
        case .dietaryEnergy: .dietaryEnergy
        }
    }
}

/// The seam between Foodge and HealthKit.
///
/// It returns raw per-window figures and raw intervals, and does no interpreting: the sleep union
/// and every rule live in the domain, so they can be tested without HealthKit present. A `nil`
/// result means nothing was readable, which is never the same as zero.
protocol HealthSampleSource: Sendable {
    func isAvailable() -> Bool
    func cumulativeSum(of kind: QuantityKind, in window: DateInterval) async throws -> Double?
    /// The raw asleep intervals overlapping the window, still overlapping each other.
    func asleepIntervals(in window: DateInterval) async throws -> [DateInterval]?
    /// The workouts in the window. Energy is deliberately not returned: it is already counted
    /// inside active energy and must not be added twice.
    func workouts(in window: DateInterval) async throws -> [WorkoutSummary]?
}
