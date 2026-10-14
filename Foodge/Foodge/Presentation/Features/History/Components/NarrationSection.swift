//
//  NarrationSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import SwiftUI

/// The judge's flourish on case detail: `FlourishBubble`, the same judge and speech bubble the verdict
/// shows (`VerdictFlourishView`), so a filed case still sounds like its verdict.
///
/// `text` is a validated on-device model line, or `nil` — and `nil` is the ordinary case, not an
/// error: it covers Apple Intelligence being off, unsupported, still downloading, the model
/// refusing, the 8-second budget expiring, and validation rejecting the candidate. All of them
/// render the reviewed template, with no error text and no retry, which is exactly why this view
/// needs neither a spinner nor a pending flag.
///
/// Every template speaks of a dish that was found, which used to mean a no-match night rendered
/// nothing at all (D106). There is no such night any more — the rule always names a dish (D139) —
/// so the gate went with it rather than lingering as a condition that is always true.
///
/// `FlourishBubble` renders the model half with `Text(verbatim:)`, so model output is never treated as
/// a format string; the template half is a `LocalizedStringResource` resolved against the ambient
/// locale. The section is visually separate from the authoritative explanation above it, and the footnote
/// says plainly that this is decoration. The row has no background: the bubble is the surface, and
/// its text is primary `label` on `AppCard`, the pair `PaletteContrastTests` measures.
@MainActor
struct NarrationSection: View {
    let text: String?
    let category: DinnerCategory

    var body: some View {
        Section {
            FlourishBubble(text: text, category: category)
                .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        } header: {
            Text("The judge’s flourish")
                .formCaption()
        } footer: {
            // A caption about the section belongs in its footer, not in a row of it
            // (`arc-audit-hig`, WU-EB).
            Text("Decoration only — the reasoning above is the verdict.")
                .formCaption()
        }
    }
}

#Preview("Template", traits: .sampleData) {
    Form {
        NarrationSection(text: nil, category: .balanced)
    }
}

#Preview("Narrated", traits: .sampleData) {
    Form {
        NarrationSection(
            text: "The defence pleaded tiredness; the court finds pasta a proportionate remedy.",
            category: .balanced
        )
    }
}
