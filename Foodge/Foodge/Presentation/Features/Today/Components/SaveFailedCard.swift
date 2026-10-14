//
//  SaveFailedCard.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// What the verdict shows when its revision did not save: the decision stays on screen above this,
/// with a retry — a failed save is never reported as saved.
@MainActor
struct SaveFailedCard: View {
    /// What went wrong — also what the verdict announces, so the two cannot drift.
    static var message: LocalizedStringResource {
        "Foodge couldn’t save this verdict. Nothing has been lost — try again."
    }

    let retry: () -> Void

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text(Self.message)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Retry save", action: retry)
                    .secondaryAction()
            }
        }
        .groupBoxStyle(.stageCard)
    }
}

#Preview(traits: .sampleData) {
    ScrollView {
        SaveFailedCard(retry: {})
            .padding()
    }
    .background { StageBackground(accent: .appBurgundy) }
}
