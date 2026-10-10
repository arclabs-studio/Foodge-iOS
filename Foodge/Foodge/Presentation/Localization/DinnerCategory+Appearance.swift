//
//  DinnerCategory+Appearance.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The colours a category is drawn in — display helpers, not logic (D145).
///
/// Returned as `ColorResource` rather than `Color` so the pairing can be measured: a resource
/// resolves through `UIColor(resource:)` in any trait collection, high contrast included, with no
/// SwiftUI environment to build. `PaletteContrastTests` reads this mapping, so a category given a
/// label colour that does not read on its own fill fails there.
extension DinnerCategory {
    /// The category's fill and the verdict stage's accent. Anything drawn in it must also name the
    /// category in text: the colour is never the only carrier of meaning (D145).
    var tint: ColorResource {
        switch self {
        case .treat: .appTomato
        case .balanced: .appCheese
        case .light: .appBasil
        }
    }

    /// The colour for text and symbols drawn on ``tint``, measured at ≥ 4.5:1 against it in all
    /// four appearances.
    var onTint: ColorResource {
        switch self {
        case .treat: .appOnTomato
        case .balanced: .appOnCheese
        case .light: .appOnBasil
        }
    }
}
