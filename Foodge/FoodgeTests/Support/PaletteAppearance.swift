//
//  PaletteAppearance.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import Testing
import UIKit

/// One of the four looks the system can ask the palette for.
///
/// Its own file rather than nested in `PaletteContrastTests`, so that its
/// `CustomTestStringConvertible` conformance stays `nonisolated` while that suite is `@MainActor`.
enum PaletteAppearance: CaseIterable, CustomTestStringConvertible {
    case light
    case dark
    case lightHighContrast
    case darkHighContrast

    /// Names the appearance in the test navigator and in every failure message.
    var testDescription: String {
        switch self {
        case .light: "light+normal"
        case .dark: "dark+normal"
        case .lightHighContrast: "light+high"
        case .darkHighContrast: "dark+high"
        }
    }

    var isDark: Bool {
        self == .dark || self == .darkHighContrast
    }

    /// The trait collection a colour is resolved against. Built with `init(mutations:)`, the
    /// non-deprecated route; the SDK header declares `UIMutableTraits` UI-actor isolated, hence
    /// `@MainActor`.
    ///
    /// `elevated` selects the interface level a sheet is drawn at — Settings is one — where the
    /// system's dark backgrounds resolve lighter than at the base level.
    @MainActor
    func traits(elevated: Bool = false) -> UITraitCollection {
        let style: UIUserInterfaceStyle = isDark ? .dark : .light
        let contrast: UIAccessibilityContrast =
            (self == .lightHighContrast || self == .darkHighContrast) ? .high : .normal
        let level: UIUserInterfaceLevel = elevated ? .elevated : .base
        return UITraitCollection(mutations: { mutableTraits in
            mutableTraits.userInterfaceStyle = style
            mutableTraits.accessibilityContrast = contrast
            mutableTraits.userInterfaceLevel = level
        })
    }
}
