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

    /// - Note: Not implemented yet — WU-19-A. It returns a failure so the suites that pin the
    ///   real behaviour are red rather than crashing the test run.
    static func baseline(
        from observations: [DailyActivityObservation],
        trackingRepresentative: Bool
    ) -> Result<ActivityBaseline, BaselineUnavailableReason> {
        .failure(.insufficientHistory(found: 0))
    }
}
