//
//  AppealFreeTextSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 22/09/2026.
//

import SwiftUI

/// A free-text dish outside the catalogue. No nutritional analysis is invented for it —
/// `foodge-plan.md` §3 — so this section is nothing but the text itself and a submit button.
@MainActor
struct AppealFreeTextSection: View {
    @Binding var text: String
    /// Whether `text` is worth submitting — `TodayViewModel.canSubmitFreeText(_:)`, so this view
    /// has no second copy of the "trimmed, non-empty" rule `submitFreeText` itself enforces.
    let canSubmit: Bool
    let submit: () -> Void

    var body: some View {
        Section("What would you rather have?") {
            // Opted out of D135's app-wide style on purpose: its whole job is to recolor the
            // value slot, and here the value slot is the field the user types into. What someone
            // writes is their own text, not a secondary reading, so it stays `primary`.
            LabeledContent("Your dinner") {
                TextField("e.g. Grandma’s stew", text: $text, axis: .vertical)
                    .multilineTextAlignment(.leading)
            }
            .labeledContentStyle(.automatic)
            Button("Submit") { submit() }
                .disabled(!canSubmit)
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    Form {
        AppealFreeTextSection(text: $text, canSubmit: false, submit: {})
    }
}
