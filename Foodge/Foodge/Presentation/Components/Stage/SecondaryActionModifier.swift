//
//  SecondaryActionModifier.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// A full-width bordered action on a stage screen — an answer to a question, a retry, the verdict's
/// toggle and its evidence link (D145).
///
/// Apply it to each button: it sets the style, sizing and the primary foreground in the environment
/// of whatever it wraps.
///
/// The label is the primary text colour rather than the tint. The bordered fill is a translucent
/// grey; over a dark card, the light-pink tint on it read at 3.75:1, under
/// WCAG 1.4.3's 4.5:1; white primary text on the same fill reads at 8.05:1. Both are computed from
/// the fill sampled in a dark render, (84, 79, 79) — the system's bordered fill is not a colour set
/// `PaletteContrastTests` can resolve.
@MainActor
struct SecondaryActionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.bordered)
            .buttonSizing(.flexible)
            .controlSize(.large)
            .foregroundStyle(.primary)
    }
}

extension View {
    /// Styles a button as a full-width secondary action inside a stage card.
    func secondaryAction() -> some View {
        modifier(SecondaryActionModifier())
    }
}
