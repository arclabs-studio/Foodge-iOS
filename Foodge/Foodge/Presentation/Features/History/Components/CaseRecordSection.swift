//
//  CaseRecordSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The versions a filed case was decided under — the rule and the catalogue that day, never today's.
@MainActor
struct CaseRecordSection: View {
    let ruleVersion: String
    let catalogueVersion: String

    var body: some View {
        Section {
            LabeledContent("Rule version", value: ruleVersion)
            LabeledContent("Catalogue version", value: catalogueVersion)
        } header: {
            Text("Recorded")
                // `.secondary` is about 3.3:1 on the light grouped background (D134, D148).
                .foregroundStyle(.appBurgundyMuted)
        }
    }
}

#Preview(traits: .sampleData) {
    Form {
        CaseRecordSection(
            ruleVersion: SampleDecisions.savedRevision.decision.ruleVersion,
            catalogueVersion: SampleDecisions.savedRevision.catalogueVersion
        )
    }
    // The root applies it in the app (D135); without it a value renders in `.secondary`.
    .labeledContentStyle(.readableValue)
}
