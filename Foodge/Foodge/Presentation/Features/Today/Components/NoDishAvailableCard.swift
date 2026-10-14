//
//  NoDishAvailableCard.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// What Today shows when nothing in the menu fits tonight's category on the person's diet.
///
/// Unreachable for every shipped diet profile, and said plainly rather than papered over with a
/// dish nothing chose (D139).
@MainActor
struct NoDishAvailableCard: View {
    let category: DinnerCategory

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(
                    """
                    Tonight’s category is \(category.displayName), and nothing in \
                    Foodge’s menu fits it on your diet.
                    """
                )
                Text("Nothing was recorded for tonight.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)
            }
        }
        .groupBoxStyle(.stageCard)
    }
}

#Preview(traits: .sampleData) {
    ScrollView {
        NoDishAvailableCard(category: .light)
            .padding()
    }
    .background { StageBackground(accent: .appBurgundy) }
}
