//
//  RecordedPatternSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// What Health recorded over the last fortnight, and what Foodge can do with it.
///
/// Takes the summary rather than the view model: it writes nothing, produces no `$` binding,
/// and reads exactly one value. The one action it offers is handed in as a closure.
@MainActor
struct RecordedPatternSection: View {
    let summary: RecordedPatternSummary
    let useTheseDaysAnyway: () -> Void

    var body: some View {
        Section {
            switch summary.pattern {
            case let .success(baseline):
                RecordedPatternRows(baseline: baseline, summary: summary)
            case let .failure(reason):
                RecordedPatternUnavailableRow(
                    reason: reason,
                    daysWithAnyReading: summary.daysWithAnyReading,
                    daysConsidered: summary.daysConsidered,
                    useTheseDaysAnyway: useTheseDaysAnyway
                )
            }
        } header: {
            Text("Your recorded pattern")
        } footer: {
            Text("Recorded samples are not a complete measurement of your day. Foodge compares them, and says so.")
        }
    }
}

/// The available case: the median, what it was measured in, and how many days it rests on.
///
/// `LabeledContent` rather than a hand-built `HStack` because it stacks at AX5 where an `HStack`
/// truncates, and the formatted values are passed to `Text` as values rather than interpolated
/// into a string, which is what lets VoiceOver read "400 kilocalories" instead of "400 kcal".
@MainActor
private struct RecordedPatternRows: View {
    let baseline: ActivityBaseline
    let summary: RecordedPatternSummary

    var body: some View {
        LabeledContent("A usual day") {
            switch baseline.metric {
            case .activeEnergy:
                Text(
                    Measurement(value: baseline.median, unit: UnitEnergy.kilocalories),
                    format: .measurement(width: .abbreviated, usage: .food)
                )
            case .steps:
                Text(baseline.median, format: .number.precision(.fractionLength(0)))
            }
        }

        LabeledContent("Measured in") {
            Text(baseline.metric.displayName)
        }

        LabeledContent("Days recorded") {
            Text(summary.daysWithAnyReading, format: .number)
        }
    }
}

#Preview("Available", traits: .sizeThatFitsLayout) {
    Form {
        RecordedPatternSection(
            summary: RecordedPatternSummary(
                snapshot: SyntheticScenarios.typicalDay.snapshot,
                trackingRepresentative: true
            ),
            useTheseDaysAnyway: {}
        )
    }
}

#Preview("Marked unrepresentative", traits: .sizeThatFitsLayout) {
    Form {
        RecordedPatternSection(
            summary: RecordedPatternSummary(
                snapshot: SyntheticScenarios.partialTracking.snapshot,
                trackingRepresentative: false
            ),
            useTheseDaysAnyway: {}
        )
    }
}
