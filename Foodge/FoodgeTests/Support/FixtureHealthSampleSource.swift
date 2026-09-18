//
//  FixtureHealthSampleSource.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
@testable import Foodge

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
    /// Active energy for each historical window, keyed by the window's start.
    private let historyEnergy: [Date: Double]
    /// How long a historical window takes to come back.
    ///
    /// Without this the fixture never suspends, completion order tracks submission order, and a
    /// test claiming to prove readings cannot be shuffled onto the wrong day would pass against
    /// a plain serial loop. Delaying the *first* window the longest forces results to arrive out
    /// of order, so the reassembly is actually put under test.
    private let historyDelays: [Date: Duration]

    /// How many times the reader asked for data. `isAvailable()` is not counted — it is the
    /// question that decides whether anything should be asked at all.
    private(set) var dataCallCount = 0

    init(
        available: Bool = true,
        todayStart: Date = .distantPast,
        today: Today = Today(),
        historyEnergy: [Date: Double] = [:],
        historyDelays: [Date: Duration] = [:]
    ) {
        self.available = available
        self.todayStart = todayStart
        self.today = today
        self.historyEnergy = historyEnergy
        self.historyDelays = historyDelays
    }

    nonisolated func isAvailable() -> Bool { available }

    func cumulativeSum(of kind: QuantityKind, in window: DateInterval) async throws -> Double? {
        dataCallCount += 1

        guard window.start == todayStart else {
            // A historical window. Only active energy is scripted; steps stay missing.
            if let delay = historyDelays[window.start] {
                try await Task.sleep(for: delay)
            }
            return kind == .activeEnergy ? historyEnergy[window.start] : nil
        }

        switch kind {
        case .activeEnergy: return today.activeEnergy
        case .restingEnergy: return today.restingEnergy
        case .steps: return today.steps
        case .dietaryEnergy: return today.dietaryEnergy
        }
    }

    func asleepIntervals(in window: DateInterval) async throws -> [DateInterval]? {
        dataCallCount += 1
        return today.sleep
    }

    func workouts(in window: DateInterval) async throws -> [WorkoutSummary]? {
        dataCallCount += 1
        return today.workouts
    }
}
