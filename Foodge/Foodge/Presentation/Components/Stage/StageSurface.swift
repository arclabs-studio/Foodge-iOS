//
//  StageSurface.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The fill and edge of anything that sits on a stage as content — a card, a speech bubble (D145).
///
/// One place for both, so a card and a bubble cannot drift apart, and so the fill the contrast
/// tests measure text on is the fill these surfaces are actually drawn with: `PaletteContrastTests`
/// resolves ``fill`` itself rather than a colour set it assumes is the same.
@MainActor
struct StageSurface: ViewModifier {
    /// White in light appearance, and in dark a warm grey lighter than dough and every stage top,
    /// so the surface advances the way elevated content does in Dark Mode.
    static let fill: ColorResource = .appCard

    let outline: AnyShape

    func body(content: Content) -> some View {
        content
            .background(Color(Self.fill), in: outline)
            // A hairline keeps the outline on cream dough, where white alone is barely
            // distinguishable from it.
            .overlay {
                outline.stroke(Color(.separator), lineWidth: 1)
            }
    }
}

extension View {
    /// Draws this view on a stage surface of the given shape.
    func stageSurface(in shape: some Shape) -> some View {
        modifier(StageSurface(outline: AnyShape(shape)))
    }
}
