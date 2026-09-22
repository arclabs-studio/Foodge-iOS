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
            LabeledContent("Your dinner") {
                TextField("e.g. Grandma’s stew", text: $text, axis: .vertical)
                    .multilineTextAlignment(.leading)
            }
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
