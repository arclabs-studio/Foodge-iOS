//
//  RecordedPatternSummary.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// What the recorded fortnight amounted to, in the form a screen can show.
///
/// It carries the calculator's verdict *and* the two counts needed to explain a refusal
/// honestly, which the verdict alone cannot supply.
struct RecordedPatternSummary: Hashable, Sendable {
    /// The comparison, or why there is none.
    let pattern: Result<ActivityBaseline, BaselineUnavailableReason>
    /// Days that produced a reading of *either* metric.
    ///
    /// Deliberately independent of the calculator: per D23 its `insufficientHistory(found:)`
    /// reports the **energy** count, so using it to tell a user how many days were recorded
    /// would understate a fortnight tracked only in steps.
    let daysWithAnyReading: Int
    /// How many completed days were looked at, recorded or not.
    let daysConsidered: Int
    let evaluatedAt: Date

    init(snapshot: EvidenceSnapshot, trackingRepresentative: Bool) {
        pattern = ActivityBaselineCalculator.baseline(
            from: snapshot.history,
            trackingRepresentative: trackingRepresentative
        )
        daysWithAnyReading = snapshot.history.count { observation in
            observation.activeEnergyAtCutoff != nil || observation.stepsAtCutoff != nil
        }
        daysConsidered = snapshot.history.count
        evaluatedAt = snapshot.evaluatedAt
    }
}
