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

    var body: some View {
        Form {
            Section {
                Text(revision.evidence.isSynthetic ? "Demonstration data" : "From Health")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            EvidenceSectionsView(evidence: revision.evidence, basis: revision.decision.basis)
        }
        .navigationTitle("Evidence details")
        .navigationBarTitleDisplayMode(.inline)
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
                    basis: .energyBalance(SampleDecisions.moderateAllowance),
                    reasonCodes: [.moderateAllowance],
                    isProvisional: false,
                    ruleVersion: CheatMealAllowanceRule.ruleVersion
                ),
                evidence: SyntheticScenarios.modestAllowance.snapshot,
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
