//
//  EvidenceDetailsView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// What Foodge actually read, and how it compared to the recorded pattern.
///
/// A calorie comparison only ever appears once intake completeness can be confirmed — no such
/// confirmation exists yet this unit, so that section stays honestly absent rather than showing
/// an unconfirmed number.
@MainActor
struct EvidenceDetailsView: View {
    let revision: SavedRevision

    private var today: HealthAggregates {
        revision.evidence.today
    }

    var body: some View {
        Form {
            Section {
                Text(revision.evidence.isSynthetic ? "Demonstration data" : "From Health")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

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
                RecordedActivityRow(
                    basis: revision.decision.basis,
                    todayValue: recordedMetricValue
                )
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
        .navigationTitle("Evidence details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var recordedMetricValue: Double? {
        guard case let .recorded(_, baseline) = revision.decision.basis else { return nil }
        return today.value(for: baseline.metric)
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        EvidenceDetailsView(
            revision: SavedRevision(
                id: UUID(),
                sequence: 0,
                createdAt: SyntheticScenarios.evaluationDate,
                decision: VerdictDecision(
                    category: .balanced,
                    basis: .recorded(
                        ratio: 1.02,
                        baseline: ActivityBaseline(
                            metric: .activeEnergy,
                            median: 400,
                            observationCount: 14,
                            window: SyntheticScenarios.windowSinceMidnight(endingAt: SyntheticScenarios.evaluationDate)
                        )
                    ),
                    reasonCodes: [.withinRecordedPattern],
                    isProvisional: false,
                    ruleVersion: DinnerCategoryRule.ruleVersion
                ),
                evidence: SyntheticScenarios.typicalDay.snapshot,
                catalogueVersion: DishCatalogue.version,
                dishOutcome: .selected(
                    variantID: "dish.pasta.pesto",
                    family: .pasta,
                    alternativeVariantID: nil,
                    alternativeFamily: nil
                ),
                narrationText: nil,
                appeals: []
            )
        )
    }
}
