//
//  RecordedActivityRow.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// What the verdict was actually decided from — a real comparison, a self-report, or neither.
///
/// Reads straight off `VerdictDecision.basis` rather than recomputing anything: the basis already
/// carries the exact ratio and baseline the decision used, so this can never drift from it.
@MainActor
struct RecordedActivityRow: View {
    let basis: CategoryBasis
    /// Today's reading of the recorded metric, for a `.recorded` basis. `nil` for every other
    /// basis, where there is nothing recorded to show.
    let todayValue: Double?

    var body: some View {
        switch basis {
        case let .recorded(ratio, baseline):
            VStack(alignment: .leading, spacing: 4) {
                LabeledContent("Recorded pattern") {
                    Text(baseline.metric.displayName)
                }
                if let todayValue {
                    LabeledContent("Today", value: todayValue, format: .number.precision(.fractionLength(0)))
                }
                LabeledContent("Usual median", value: baseline.median, format: .number.precision(.fractionLength(0)))
                LabeledContent("Compared to pattern", value: ratio, format: .percent.precision(.fractionLength(0)))
                Text("Based on \(baseline.observationCount) recorded days.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case let .selfReported(report):
            LabeledContent("Your account") {
                Text(report.displayName)
            }
        case .provisional:
            Text("No usable comparison — this verdict is provisional.")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    Form {
        RecordedActivityRow(
            basis: .recorded(
                ratio: 1.05,
                baseline: ActivityBaseline(
                    metric: .activeEnergy,
                    median: 400,
                    observationCount: 14,
                    window: DateInterval(start: .now, duration: 60 * 60 * 24 * 14)
                )
            ),
            todayValue: 420
        )
    }
}
