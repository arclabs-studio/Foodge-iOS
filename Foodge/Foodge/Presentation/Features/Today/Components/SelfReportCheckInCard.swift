//
//  SelfReportCheckInCard.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// The user's own account of the day, asked only when no recorded comparison is usable.
///
/// Skipping is a real, honest option here — it produces a provisional balanced verdict rather
/// than forcing a choice the user cannot make.
@MainActor
struct SelfReportCheckInCard: View {
    /// Moves VoiceOver to the question when Today brings the card in (WCAG 2.4.3).
    let questionFocus: AccessibilityFocusState<Bool>.Binding
    let submit: (SelfReportedActivity?) -> Void

    /// The card's question — also what Today announces when the card appears, so VoiceOver hears it
    /// in the card's own words.
    static var question: LocalizedStringResource {
        "How active was today, compared to usual?"
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("There isn’t enough readable data to work out today’s allowance.")
                    .font(.footnote)
                    // `.secondary` reads at about 3.4:1 on a light card; `appBurgundyMuted` is
                    // measured on it by `PaletteContrastTests` (D134, D145).
                    .foregroundStyle(.appBurgundyMuted)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(SelfReportedActivity.allCases, id: \.self) { report in
                    Button(String(localized: report.displayName)) { submit(report) }
                        .secondaryAction()
                }
                Button("Skip") { submit(nil) }
                    .secondaryAction()
            }
        } label: {
            Text(Self.question)
                .accessibilityFocused(questionFocus)
        }
        .groupBoxStyle(.stageCard)
    }
}

#Preview(traits: .sampleData) {
    @Previewable @AccessibilityFocusState var isFocused: Bool

    ScrollView {
        SelfReportCheckInCard(questionFocus: $isFocused, submit: { _ in })
            .padding()
    }
    .background { StageBackground(accent: .appBurgundy) }
}
