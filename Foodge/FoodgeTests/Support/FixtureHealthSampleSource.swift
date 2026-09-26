//
//  FixtureHealthSampleSource.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

@testable import Foodge
import Foundation

/// A scripted stand-in for HealthKit.
///
/// An actor rather than a class with mutable state, because the reader queries it concurrently
/// and the constitution forbids suppressing the resulting data race instead of removing it.
actor FixtureHealthSampleSource: HealthSampleSource {
    /// What the source will report for the window that starts at local midnight today.
    struct Today {
        var activeEnergy: Double?
        var restingEnergy: Double?
        var steps: Double?
        var dietaryEnergy: Double?
        var sleep: [DateInterval]?
        var workouts: [WorkoutSummary]?

        init(
            activeEnergy: Double? = nil,
            restingEnergy: Double? = nil,
            steps: Double? = nil,
            dietaryEnergy: Double? = nil,
            sleep: [DateInterval]? = nil,
            workouts: [WorkoutSummary]? = nil
        ) {
            self.activeEnergy = activeEnergy
            self.restingEnergy = restingEnergy
            self.steps = steps
            self.dietaryEnergy = dietaryEnergy
            self.sleep = sleep
            self.workouts = workouts
        }
    }

    private let available: Bool
    private let todayStart: Date
    private let today: Today

    /// How many times the reader asked for data. `isAvailable()` is not counted — it is the
    /// question that decides whether anything should be asked at all.
    private(set) var dataCallCount = 0

    init(
        available: Bool = true,
        todayStart: Date = .distantPast,
        today: Today = Today()
    ) {
        self.available = available
        self.todayStart = todayStart
        self.today = today
    }

    nonisolated func isAvailable() -> Bool {
        available
    }

    func cumulativeSum(of kind: QuantityKind, in window: DateInterval) async throws -> Double? {
        dataCallCount += 1

        // Only today's window is scripted. D111 deleted the historical windows, so any other
        // window has nothing readable behind it — which is what "missing" means here.
        guard window.start == todayStart else { return nil }

        switch kind {
        case .activeEnergy: return today.activeEnergy
        case .restingEnergy: return today.restingEnergy
        case .steps: return today.steps
        case .dietaryEnergy: return today.dietaryEnergy
        }
    }

    func asleepIntervals(in _: DateInterval) async throws -> [DateInterval]? {
        dataCallCount += 1
        return today.sleep
    }

    func workouts(in _: DateInterval) async throws -> [WorkoutSummary]? {
        dataCallCount += 1
        return today.workouts
    }
}
