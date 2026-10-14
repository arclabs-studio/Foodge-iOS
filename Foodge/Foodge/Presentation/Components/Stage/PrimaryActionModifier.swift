//
//  PrimaryActionModifier.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The one prominent action on a stage screen (D145): the system's prominent Liquid Glass button,
/// full width, tinted brand burgundy.
///
/// Apply it to the button or link itself: it sets the button style, sizing and colours in the
/// environment of whatever it wraps.
///
/// A modifier over a native style rather than a style of its own, so the button keeps everything
/// `glassProminent` gives it. The label colour is set here because the tint is tuned as a
/// *foreground* colour — light pink in dark appearance, where the system's white label would read
/// at about 2.2:1. `PaletteContrastTests` measures `appOnBurgundy` on the flat tint; on the glass
/// fill itself `arc-audit-accessibility` sampled 7.78:1 light, 10.93:1 light with Increased
/// Contrast, 8.95:1 dark and 12.10:1 dark with Increased Contrast (WU-29-C). One place for the
/// recipe, so every screen's primary action carries the pairing rather than each repeating it.
@MainActor
struct PrimaryActionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .controlSize(.large)
            .fontWeight(.semibold)
            .tint(.appBurgundy)
            .foregroundStyle(.appOnBurgundy)
    }
}

extension View {
    /// Styles a button or navigation link as the stage screen's primary action.
    func primaryAction() -> some View {
        modifier(PrimaryActionModifier())
    }
}

#Preview {
    VStack {
        Button("Give me a verdict") {}
            .primaryAction()
        Button("Give me a verdict") {}
            .primaryAction()
            .disabled(true)
    }
    .padding()
    .background { StageBackground(accent: .appBurgundy) }
}
