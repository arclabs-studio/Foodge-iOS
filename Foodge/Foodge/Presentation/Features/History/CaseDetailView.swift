//
//  CaseDetailView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import SwiftUI

/// One day, exactly as Foodge ruled it: the evidence, rule version, dish and appeals that day
/// actually used — never recomputed against today's rules or catalogue.
///
/// Renders `savedCase.latestRevision` only. The data model supports multiple revisions per day,
/// but no UI trigger for creating a second one exists yet, so a multi-revision layout would be
/// speculative. If `latestRevision` were ever `nil`, the `Group` below renders nothing —
/// documented-unreachable, per the same reasoning as `VerdictRevision.dishOutcome`'s fallback: a
/// `DailyCase` is never inserted without its first revision.
@MainActor
struct CaseDetailView: View {
    let savedCase: SavedCase

    var body: some View {
        Group {
            if let revision = savedCase.latestRevision {
                content(for: revision)
            }
        }
        .navigationTitle("Case detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(for revision: SavedRevision) -> some View {
        Form {
            if revision.evidence.isSynthetic {
                // A caption, not a row — the same spelling `EvidenceDetailsView` uses for the
                // same line, so the two screens that share `EvidenceSectionsView` also agree on
                // how the provenance above it reads.
                Section {
                    EmptyView()
                } footer: {
                    Text("Demonstration data")
                        // `.secondary` measures ~3.3:1 against the grouped background in
                        // standard-contrast light — below WCAG 1.4.3's 4.5:1.
                        // `appBurgundyMuted` is ≥4.5:1 (D134).
                        .foregroundStyle(.appBurgundyMuted)
                }
            }

            CaseHeroSection(
                category: revision.decision.category,
                isProvisional: revision.decision.isProvisional,
                variantID: revision.dishOutcome.variantID,
                family: revision.dishOutcome.family
            )

            CaseReasonsSection(reasonCodes: revision.decision.reasonCodes, createdAt: revision.createdAt)

            EvidenceSectionsView(evidence: revision.evidence, basis: revision.decision.basis)

            // `narrationText` is nil for every case recorded before narration existed, and stays
            // nil whenever the model did not produce a validated line. The reviewed template
            // covers all of that, so History shows a flourish for every case.
            NarrationSection(
                text: revision.narrationText,
                category: revision.decision.category
            )

            CaseRecordSection(ruleVersion: revision.decision.ruleVersion, catalogueVersion: revision.catalogueVersion)
        }
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        CaseDetailView(savedCase: SampleDecisions.savedCase)
    }
    // The root applies it in the app (D135); without it a value renders in `.secondary`.
    .labeledContentStyle(.readableValue)
}
