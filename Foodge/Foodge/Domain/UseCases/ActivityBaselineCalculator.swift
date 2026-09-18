//
//  ActivityBaselineCalculator.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Builds "your recorded pattern" from the previous completed days.
///
/// The rules, in order: if the user marked tracking unrepresentative there is no baseline at all;
/// otherwise keep the non-missing, finite, non-negative observations of a metric, require at
/// least ``minimumObservations`` of them and a strictly positive median. Active energy is tried
/// first, steps second.
enum ActivityBaselineCalculator {
    /// The number of usable observations a baseline needs before it may be trusted.
    static let minimumObservations = 7

    static func baseline(
        from observations: [DailyActivityObservation],
        trackingRepresentative: Bool
    ) -> Result<ActivityBaseline, BaselineUnavailableReason> {
        // However good the recording looks, the user's word that it is unrepresentative ends it.
        guard trackingRepresentative else {
            return .failure(.markedUnrepresentative)
        }

        let energy = attempt(.activeEnergy, in: observations, value: \.activeEnergyAtCutoff)
        if case .success = energy {
            return energy
        }

        let steps = attempt(.steps, in: observations, value: \.stepsAtCutoff)
        if case .success = steps {
            return steps
        }

        // Both refused. Report the preferred metric's reason so the failure is deterministic
        // rather than depending on which attempt happened to run last (D23).
        return energy
    }

    /// Tries to build a pattern from one metric.
    private static func attempt(
        _ metric: ActivityMetric,
        in observations: [DailyActivityObservation],
        value: KeyPath<DailyActivityObservation, Double?>
    ) -> Result<ActivityBaseline, BaselineUnavailableReason> {
        // A day with no sample is missing, not zero, so it is dropped rather than counted.
        let usable = observations.filter { observation in
            guard let value = observation[keyPath: value] else { return false }
            return value.isFinite && value >= 0
        }

        guard usable.count >= minimumObservations else {
            return .failure(.insufficientHistory(found: usable.count))
        }

        let values = usable.compactMap { $0[keyPath: value] }
        let median = median(of: values)

        guard median > 0 else {
            return .failure(.zeroMedian)
        }

        let days = usable.map(\.day).sorted()
        guard let first = days.first, let last = days.last else {
            return .failure(.insufficientHistory(found: usable.count))
        }

        return .success(
            ActivityBaseline(
                metric: metric,
                median: median,
                observationCount: usable.count,
                window: DateInterval(start: first, end: last)
            )
        )
    }

    /// The middle value, or the mean of the middle pair when the count is even (D16).
    ///
    /// Returns zero for an empty input, which the caller already rejects as unusable.
    private static func median(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }

        let sorted = values.sorted()
        let middle = sorted.count / 2

        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }
}
