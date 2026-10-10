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
            // A caption, not a row: written as a section footer so it reads as the provenance
            // line it is. As a `Section { Text }` it rendered as a card holding one short phrase
            // and nothing else, which reads as a header that lost its content.
            Section {
                EmptyView()
            } footer: {
                Text(revision.evidence.isSynthetic ? "Demonstration data" : "From Health")
                    .formCaption()
            }

            EvidenceSectionsView(evidence: revision.evidence, basis: revision.decision.basis)
        }
        .navigationTitle("Evidence details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        EvidenceDetailsView(revision: SampleDecisions.savedRevision)
    }
    // The root applies it in the app (D135); without it a value renders in `.secondary`.
    .labeledContentStyle(.readableValue)
}
