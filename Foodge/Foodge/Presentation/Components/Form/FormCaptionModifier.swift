//
//  FormCaptionModifier.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The colour of every `Form` section header, section footer and text-field prompt the app writes
/// (D134, D148).
///
/// The system draws those in `.secondary`, which measures about 3.3:1 on the light grouped
/// background and 3.4:1 on a light row — under WCAG 1.4.3's 4.5:1. `appBurgundyMuted` is measured on
/// every system surface, base and elevated, by `PaletteContrastTests`. One modifier, so the reason
/// lives in one place; nothing checks that a new header uses it, so a new `Section` must.
@MainActor
struct FormCaptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(.appBurgundyMuted)
    }
}

extension View {
    /// Draws a section header or footer in the measured caption colour; see `FormCaptionModifier`.
    func formCaption() -> some View {
        modifier(FormCaptionModifier())
    }
}

extension Text {
    /// The same colour for a `TextField`'s prompt, which has to stay a `Text`.
    func formCaption() -> Text {
        foregroundStyle(.appBurgundyMuted)
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var age = ""

    Form {
        Section {
            TextField("Age in years", text: $age, prompt: Text("Years").formCaption())
        } header: {
            Text("About you")
                .formCaption()
        } footer: {
            Text("They stay on this iPhone, and Foodge never shows them to anyone.")
                .formCaption()
        }
    }
}
