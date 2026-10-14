//
//  VerdictFlourishView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The judge's flourish on the verdict stage: the judge, and what it says in a speech bubble.
///
/// The line is the validated on-device narration when there is one, and the reviewed template for
/// the category otherwise — the same two sources `NarrationSection` shows on case detail.
/// Decoration, and labelled as such: the reasoning card is the verdict.
@MainActor
struct VerdictFlourishView: View {
    /// The narrated line, or `nil` for the template.
    let text: String?
    let category: DinnerCategory

    var body: some View {
        VStack(spacing: 8) {
            Text("The judge’s flourish")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            FlourishBubble(text: text, category: category)

            Text("Decoration only — the reasoning above is the verdict.")
                .font(.footnote)
                // On the stage: `appBurgundyMuted` is measured on every stage top (D145).
                .foregroundStyle(.appBurgundyMuted)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview("Template", traits: .sampleData) {
    ScrollView {
        VerdictFlourishView(text: nil, category: .treat)
            .padding()
    }
    .background { StageBackground(accent: Color(DinnerCategory.treat.tint)) }
}
