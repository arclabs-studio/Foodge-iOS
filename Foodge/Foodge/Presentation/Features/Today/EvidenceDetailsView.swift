//
//  EvidenceDetailsView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// What Foodge actually read, and the allowance it worked out from it.
///
/// Every figure carries its own provenance, and a figure Health could not supply is shown as
/// missing rather than as zero. The recorded-pattern comparison this screen once showed was
/// deleted with the 14-day baseline (D111); the allowance breakdown replaced it.
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
