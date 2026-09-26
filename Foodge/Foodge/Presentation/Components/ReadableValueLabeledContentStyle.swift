//
//  ReadableValueLabeledContentStyle.swift
//  Foodge
//
//  Created by ARC Labs Studio on 26/09/2026.
//

import SwiftUI

/// `LabeledContent` whose value clears the WCAG 1.4.3 contrast floor.
///
/// The automatic style renders the value with SwiftUI's secondary hierarchy, measured at
/// **3.44:1** against a `Form` row in standard-contrast light — the same ratio D134 fixed
/// everywhere the app styles its own text, which left `ProvenanceRow`'s "410 kcal" failing
/// directly above a timestamp that passes. This changes that one thing and nothing else: the
/// layout is still `LabeledContent`'s, and only the value slot is recolored.
///
/// The value is styled directly rather than through the foreground style's second level. That
/// was the first attempt, and the simulator showed what it actually does: rebuilding from the
/// configuration drops the value's secondary treatment altogether, so every figure rendered at
/// full `primary` — passing the contrast floor while flattening the label/value hierarchy the
/// HIG asks for. `appBurgundyMuted` measures 4.73:1 light / 5.68:1 dark, and better again under
/// Increased Contrast (D135).
@MainActor
struct ReadableValueLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        LabeledContent {
            configuration.content
                .foregroundStyle(.appBurgundyMuted)
        } label: {
            configuration.label
        }
    }
}

extension LabeledContentStyle where Self == ReadableValueLabeledContentStyle {
    /// Applied once at the app's root, so every `LabeledContent` in the app inherits it.
    static var readableValue: ReadableValueLabeledContentStyle { .init() }
}
