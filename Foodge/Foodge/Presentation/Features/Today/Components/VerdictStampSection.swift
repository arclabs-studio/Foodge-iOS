//
//  VerdictStampSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The top of the verdict: the category stamp, and — when the decision was provisional — the caveat
/// that says so.
@MainActor
struct VerdictStampSection: View {
    let category: DinnerCategory
    let isProvisional: Bool

    var body: some View {
        VStack(spacing: 12) {
            CategoryStampView(category: category)
            if isProvisional {
                Text("Provisional — there wasn’t enough to go on yet.")
                    .font(.footnote)
                    // On the stage: `appBurgundyMuted` is measured on every stage top (D145).
                    .foregroundStyle(.appBurgundyMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 8)
    }
}

#Preview(traits: .sampleData) {
    VerdictStampSection(category: .balanced, isProvisional: true)
        .padding()
        .background { StageBackground(accent: Color(DinnerCategory.balanced.tint)) }
}
