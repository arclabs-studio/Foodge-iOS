//
//  NarrationSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import SwiftUI

/// The judge's flourish, shared by `VerdictView` and `CaseDetailView`.
///
/// `text` is a validated on-device model line, or `nil` — and `nil` is the ordinary case, not an
/// error: it covers Apple Intelligence being off, unsupported, still downloading, the model
/// refusing, the 8-second budget expiring, and validation rejecting the candidate. All of them
/// render the reviewed template, with no error text and no retry, which is exactly why this view
/// needs neither a spinner nor a pending flag.
///
/// The model half is rendered with `Text(verbatim:)` so model output is never treated as a format
/// string; the template half is a `LocalizedStringResource` resolved against the ambient locale.
/// The section is visually separate from the authoritative explanation above it, and the footnote
/// says plainly that this is decoration.
@MainActor
struct NarrationSection: View {
    let text: String?
    let category: DinnerCategory

    var body: some View {
        Section("The judge’s flourish") {
            flourish
                .font(.callout)
                .italic()
                // `AppBurgundyMuted` is the brand's dedicated secondary-text color, carrying all
                // four appearances. `arc-audit-accessibility` measured it from the rendered
                // pixels rather than the asset hex: 5.82:1 light, 6.70:1 dark, against the 4.5:1
                // WCAG 1.4.3 needs.
                .foregroundStyle(.appBurgundyMuted)
            Text("Decoration only — the reasoning above is the verdict.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var flourish: some View {
        if let text {
            Text(verbatim: text)
        } else {
            Text(category.flourishTemplate)
        }
    }
}

#Preview("Template") {
    Form {
        NarrationSection(text: nil, category: .balanced)
    }
}

#Preview("Narrated") {
    Form {
        NarrationSection(
            text: "The defence pleaded tiredness; the court finds pasta a proportionate remedy.",
            category: .balanced
        )
    }
}
