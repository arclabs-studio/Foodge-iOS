//
//  WCAGContrast.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import Foundation

/// WCAG 2.x contrast arithmetic, written out in the test target so no production file can share
/// a mistake with it.
///
/// Production code contains no contrast arithmetic at all — the palette is a set of asset-catalog
/// values — so this is the independent oracle for "is this text readable". It follows the
/// definitions in WCAG 2.2 verbatim: relative luminance over linearised sRGB channels, and
/// `(L1 + 0.05) / (L2 + 0.05)` with the lighter colour on top.
enum WCAGContrast {
    /// Success criterion 1.4.3 (AA) for text below the large-text threshold.
    static let minimumTextRatio = 4.5

    /// An opaque colour as three gamma-encoded sRGB channels, each in `0...1`.
    struct SRGBColor {
        let red: Double
        let green: Double
        let blue: Double

        /// `#RRGGBB`, for failure messages that name a colour a human can look up.
        var hexDescription: String {
            "#" + [red, green, blue].map(Self.hexByte).joined()
        }

        /// The largest absolute difference across the three channels, in `0...1`.
        func largestChannelDifference(from other: SRGBColor) -> Double {
            max(abs(red - other.red), abs(green - other.green), abs(blue - other.blue))
        }

        private static func hexByte(_ channel: Double) -> String {
            let digits = String(Int((channel * 255).rounded()), radix: 16, uppercase: true)
            return digits.count == 1 ? "0" + digits : digits
        }
    }

    /// WCAG relative luminance of an opaque colour, `0` (black) to `1` (white).
    static func relativeLuminance(of color: SRGBColor) -> Double {
        0.2126 * linearised(color.red) + 0.7152 * linearised(color.green) + 0.0722 * linearised(color.blue)
    }

    /// Contrast ratio between two opaque colours, `1` (identical) to `21` (black on white).
    /// Symmetric: the lighter colour is always the numerator.
    static func ratio(_ first: SRGBColor, _ second: SRGBColor) -> Double {
        let firstLuminance = relativeLuminance(of: first)
        let secondLuminance = relativeLuminance(of: second)
        return (max(firstLuminance, secondLuminance) + 0.05) / (min(firstLuminance, secondLuminance) + 0.05)
    }

    /// `foreground` painted at `opacity` over an opaque `background`, blended per gamma-encoded
    /// channel — which is how a SwiftUI `Color.opacity(_:)` layer composites over an opaque fill.
    static func composite(_ foreground: SRGBColor, opacity: Double, over background: SRGBColor) -> SRGBColor {
        SRGBColor(
            red: foreground.red * opacity + background.red * (1 - opacity),
            green: foreground.green * opacity + background.green * (1 - opacity),
            blue: foreground.blue * opacity + background.blue * (1 - opacity)
        )
    }

    private static func linearised(_ channel: Double) -> Double {
        channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }
}
