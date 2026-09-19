//
//  RecordedPatternUnavailableRow.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// Why there is no pattern to compare tonight against.
///
/// A real child view rather than a helper inside the section: a computed property would share
/// the section's invalidation boundary, and this is the part that changes when the user marks
/// the days unrepresentative.
///
/// None of these messages says *denied* or *permission*. Health cannot tell an app that, so
/// Foodge does not say it.
@MainActor
struct RecordedPatternUnavailableRow: View {
    let reason: BaselineUnavailableReason
    /// Days with a reading of **either** metric — not the reason's `found:`, which per D23
    /// carries the energy count and would understate a fortnight tracked only in steps.
    let daysWithAnyReading: Int
    let daysConsidered: Int
    let useTheseDaysAnyway: () -> Void

    var body: some View {
        switch reason {
        case .insufficientHistory:
            Text(
                "Health has readings for \(daysWithAnyReading) of the last \(daysConsidered) days. Foodge needs at least \(ActivityBaselineCalculator.minimumObservations) to see a pattern."
            )
        case .zeroMedian:
            Text("Those days have no movement recorded, so there is nothing to compare tonight against.")
        case .markedUnrepresentative:
            Text("You’ve said these days don’t reflect how you usually live, so Foodge won’t compare against them.")
            Button("Use these days after all", action: useTheseDaysAnyway)
        }
    }
}

#Preview("Not enough days", traits: .sizeThatFitsLayout) {
    Form {
        RecordedPatternUnavailableRow(
            reason: .insufficientHistory(found: 3),
            daysWithAnyReading: 3,
            daysConsidered: 14,
            useTheseDaysAnyway: {}
        )
    }
}

#Preview("Marked unrepresentative", traits: .sizeThatFitsLayout) {
    Form {
        RecordedPatternUnavailableRow(
            reason: .markedUnrepresentative,
            daysWithAnyReading: 14,
            daysConsidered: 14,
            useTheseDaysAnyway: {}
        )
    }
}
