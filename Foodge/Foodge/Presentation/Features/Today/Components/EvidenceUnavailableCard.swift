//
//  EvidenceUnavailableCard.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// What Today shows when a read of today's evidence failed: what went wrong, and a retry.
///
/// The retry comes first, because a read that failed once may well succeed. `TodayBeforeVerdictView`
/// puts the self-report below it, because the retry must never be the only way out: on a phone
/// whose Health has never been authorized every attempt throws (D129).
@MainActor
struct EvidenceUnavailableCard: View {
    /// What went wrong — also what Today announces when this card appears, so the two cannot drift.
    static var message: LocalizedStringResource {
        "Foodge couldn’t finish reading today’s evidence."
    }

    /// Moves VoiceOver to the message when Today brings the card in (WCAG 2.4.3).
    let messageFocus: AccessibilityFocusState<Bool>.Binding
    let retry: () -> Void

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text(Self.message)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityFocused(messageFocus)
                Button("Try again", action: retry)
                    .secondaryAction()
            }
        }
        .groupBoxStyle(.stageCard)
    }
}

#Preview(traits: .sampleData) {
    @Previewable @AccessibilityFocusState var isFocused: Bool

    ScrollView {
        EvidenceUnavailableCard(messageFocus: $isFocused, retry: {})
            .padding()
    }
    .background { StageBackground(accent: .appBurgundy) }
}
