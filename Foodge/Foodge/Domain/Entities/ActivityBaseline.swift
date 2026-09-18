//
//  ActivityBaseline.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Which recorded metric a baseline was built from.
///
/// Active energy is preferred; steps are the fallback when energy cannot supply a usable
/// comparison.
enum ActivityMetric: String, Codable, CaseIterable, Hashable, Sendable {
    case activeEnergy
    case steps
}

/// One completed day's activity, accumulated up to the same local clock time as today's
/// evaluation.
///
/// Both values are optional because a day with no recorded samples is missing, not zero.
struct DailyActivityObservation: Hashable, Codable, Sendable {
    let day: Date
    let activeEnergyAtCutoff: Double?
    let stepsAtCutoff: Double?
}

/// The comparison Foodge calls "your recorded pattern".
///
/// Recorded samples do not establish complete physiological measurement, and the explanation
/// always says so.
struct ActivityBaseline: Hashable, Codable, Sendable {
    let metric: ActivityMetric
    let median: Double
    let observationCount: Int
    let window: DateInterval
}

/// Why no usable baseline could be built.
enum BaselineUnavailableReason: Error, Codable, Hashable, Sendable {
    /// Fewer than the required number of usable observations were found.
    case insufficientHistory(found: Int)
    /// Enough observations, but their median was zero, so a ratio would be meaningless.
    case zeroMedian
    /// The user said the recorded days do not represent their usual days.
    case markedUnrepresentative
}
