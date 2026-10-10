//
//  VerdictReasonsCard.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// Why tonight landed where it did: the decision's reason codes, and the disclaimer that qualifies
/// them.
@MainActor
struct VerdictReasonsCard: View {
    let reasonCodes: [ReasonCode]

    var body: some View {
        GroupBox("Why") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(reasonCodes, id: \.self) { reason in
                    Text(reason.displayText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text("These are prototype product heuristics, not nutritional advice.")
                    .font(.footnote)
                    // `.secondary` reads at about 3.4:1 on a light card; `appBurgundyMuted` is
                    // measured on it by `PaletteContrastTests` (D134, D145).
                    .foregroundStyle(.appBurgundyMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
        .groupBoxStyle(.stageCard)
    }
}

#Preview(traits: .sampleData) {
    ScrollView {
        VerdictReasonsCard(reasonCodes: SampleDecisions.spentVerdict.reasonCodes)
            .padding()
    }
    .background { StageBackground(accent: Color(DinnerCategory.light.tint)) }
}
