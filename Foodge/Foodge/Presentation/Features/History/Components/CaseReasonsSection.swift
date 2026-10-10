//
//  CaseReasonsSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// Why a filed case landed where it did: its reason codes under a header that carries the case's
/// date, and the disclaimer that qualifies them.
///
/// The header carries the date because the reason codes are stored, not recomputed: they are phrased
/// for the day they were written ("Today's activity came in…"), so on a past case the date is what
/// makes "today" read as the day being quoted rather than as now. `VerdictReasonsCard` shows the same
/// codes undated, where today really is today.
@MainActor
struct CaseReasonsSection: View {
    let reasonCodes: [ReasonCode]
    let createdAt: Date

    var body: some View {
        Section {
            ForEach(reasonCodes, id: \.self) { reason in
                Text(reason.displayText)
            }
        } header: {
            // Side by side while the date fits; stacked once it would wrap (Spanish from AX 1).
            ViewThatFits(in: .horizontal) {
                HStack {
                    title
                    Spacer()
                    date
                }
                VStack(alignment: .leading, spacing: 2) {
                    title
                    date
                }
            }
            // Headers, like footers, are drawn in `.secondary` — about 3.3:1 on the light grouped
            // background. `appBurgundyMuted` is ≥4.5:1 there (D134, D148).
            .foregroundStyle(.appBurgundyMuted)
            .accessibilityElement(children: .combine)
        } footer: {
            // It qualifies the reasons above it, so it is a footer rather than one more row among them
            // (`arc-audit-hig`, WU-EB); `VerdictReasonsCard` closes its card with the same sentence.
            Text("These are prototype product heuristics, not nutritional advice.")
                .foregroundStyle(.appBurgundyMuted)
        }
    }

    private var title: some View {
        Text("Why")
    }

    private var date: some View {
        Text(createdAt, format: .dateTime.year().month().day())
    }
}

#Preview(traits: .sampleData) {
    Form {
        CaseReasonsSection(
            reasonCodes: SampleDecisions.savedRevision.decision.reasonCodes,
            createdAt: SampleDecisions.savedRevision.createdAt
        )
    }
}
