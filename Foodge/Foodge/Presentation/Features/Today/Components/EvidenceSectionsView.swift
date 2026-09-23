//
//  EvidenceSectionsView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import SwiftUI

/// What Foodge actually read, and how it compared to the recorded pattern.
///
/// Shared between `EvidenceDetailsView` (today's flow) and `CaseDetailView` (History) so the two
/// screens stay provably identical in how they present Health evidence — one place formats it,
/// rather than two copies that could quietly drift apart.
@MainActor
struct EvidenceSectionsView: View {
    let evidence: EvidenceSnapshot
    let basis: CategoryBasis

    private var today: HealthAggregates {
        evidence.today
    }

    var body: some View {
        Group {
            Section("Sources") {
                ProvenanceRow(
                    title: HealthKind.activeEnergy.displayName,
                    valueText: today.activeEnergy.map { "\(Int($0.kilocalories)) kcal" },
                    readAt: today.activeEnergy?.provenance.readAt
                )
                ProvenanceRow(
                    title: HealthKind.restingEnergy.displayName,
                    valueText: today.restingEnergy.map { "\(Int($0.kilocalories)) kcal" },
                    readAt: today.restingEnergy?.provenance.readAt
                )
                ProvenanceRow(
                    title: HealthKind.steps.displayName,
                    valueText: today.steps.map { "\(Int($0.count))" },
                    readAt: today.steps?.provenance.readAt
                )
                ProvenanceRow(
                    title: HealthKind.dietaryEnergy.displayName,
                    valueText: today.dietaryEnergy.map { "\(Int($0.kilocalories)) kcal" },
                    readAt: today.dietaryEnergy?.provenance.readAt
                )
            }

            Section("Recorded activity") {
                RecordedActivityRow(basis: basis, todayValue: recordedMetricValue)
            }

            Section("Sleep") {
                if let sleep = today.sleep {
                    LabeledContent(
                        "Asleep",
                        value: sleep.asleepDuration.formatted(.units(allowed: [.hours, .minutes], width: .narrow))
                    )
                    LabeledContent("Intervals", value: sleep.intervalCount, format: .number)
                } else {
                    Text("No readable data")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var recordedMetricValue: Double? {
        guard case let .recorded(_, baseline) = basis else { return nil }
        return today.value(for: baseline.metric)
    }
}

#Preview(traits: .sampleData) {
    Form {
        EvidenceSectionsView(
            evidence: SyntheticScenarios.typicalDay.snapshot,
            basis: .recorded(
                ratio: 1.02,
                baseline: ActivityBaseline(
                    metric: .activeEnergy,
                    median: 400,
                    observationCount: 14,
                    window: SyntheticScenarios.windowSinceMidnight(endingAt: SyntheticScenarios.evaluationDate)
                )
            )
        )
    }
}
