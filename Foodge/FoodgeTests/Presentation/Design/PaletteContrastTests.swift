//
//  PaletteContrastTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 10/10/2026.
//

@testable import Foodge
import Foundation
import Testing
import UIKit

/// Proves that every text/background pair the redesign ships is readable in all four
/// appearances, by resolving the **shipped** colour sets — not a copy of their hex values — and
/// measuring them (acceptance criterion 5 of the playful-redesign plan, WU-29-A).
///
/// The oracle is `WCAGContrast`, a from-the-spec implementation of WCAG 2.x relative luminance
/// that lives in the test target. Production code contains no contrast arithmetic, so there is
/// nothing for the oracle to share a mistake with: the only production inputs are the colour
/// values the asset catalog resolves to, the category→colour mapping, and
/// `StageBackground.accentOpacity`. Each of those can be edited in a way that still compiles
/// and still builds, which is exactly what this suite exists to catch.
///
/// ## What is measured
///
/// 1. `appBurgundy`, `appBurgundyMuted` and primary `label` text on every surface text can sit
///    on — `systemBackground`, `systemGroupedBackground` and `secondarySystemGroupedBackground`
///    at the base level and at the elevated level a sheet is drawn at, the `AppCard` fill,
///    `appDough`, and the **top of every stage gradient** (accent at
///    `StageBackground.accentOpacity` composited over dough, where the tint is strongest and so
///    the contrast is lowest). Accents are burgundy (Today, Welcome) and each category tint
///    (verdict).
/// 2. `AppCard` is lighter than dough and every stage top, so a card reads as raised content.
/// 3. The "On" pairs: `appOnBurgundy` on `appBurgundy`, and for every `DinnerCategory` its
///    `onTint` on its `tint`, read through the production mapping so a mismatched pair fails.
/// 4. `AccentColor` is the same colour as `appBurgundy` in every appearance, so the system tint
///    inherits the measurements in (1).
/// 5. Each Settings tile's glyph on its fill, read from `SettingsIconLabelStyle`, at the 3:1 a
///    graphic needs — including the destructive tile's glyph on system red — and the destructive
///    symbol's red on the Settings row, where it stands without its tile at accessibility sizes
///    (WU-29-H).
///
/// ## What is deliberately not measured
///
/// `appGold` and `appCheese` as **shapes** against light surfaces (about 1.5 to 1.9:1) are
/// decoration only and never the sole carrier of meaning, so WCAG 1.4.11 does not apply. That
/// is accepted and recorded as part of D145 — it is not an omission. The system's `.secondary`
/// is not measured either: it reads at about 3.4:1 on a light row, which is why D134 replaced it
/// with `appBurgundyMuted` in app-styled text. The `Form` headers, footers and text-field prompts
/// the system would draw in it set `appBurgundyMuted` instead, and every `Picker` is a
/// `MenuPickerRow` whose value is the tint (D148) — established by a grep in WU-29-G, not by this
/// suite, which cannot see which colour a view applies. Text the system still draws itself — a
/// `DatePicker`'s value, a menu's items, a confirmation dialog — is not measured here.
@Suite("Palette contrast", .tags(.unit, .critical))
@MainActor
struct PaletteContrastTests {
    /// Half an 8-bit step: absorbs float representation, never a different colour.
    private static let channelTolerance = 1.0 / 255.0 / 2.0

    // MARK: - Tests

    @Test("Every declared text and on-colour pair meets 4.5:1", arguments: PaletteAppearance.allCases)
    func everyDeclaredPairMeetsTheTextContrastFloor(in appearance: PaletteAppearance) throws {
        // Given the shipped colour sets, the category mapping and the stage opacity, resolved
        // for this appearance
        let sut = try makeSUT(in: appearance)

        // When each pair is measured with the independent WCAG formula
        // Then none falls below the AA floor, and each failure names its foreground,
        // background, appearance and measured ratio
        for pair in sut.pairs {
            #expect(pair.ratio >= WCAGContrast.minimumTextRatio, "\(pair.summary) (floor 4.5:1)")
        }
    }

    @Test("A Settings tile's glyph reads on its fill, the destructive one included", arguments: PaletteAppearance.allCases)
    func settingsTileGlyphsMeetTheGraphicFloor(in appearance: PaletteAppearance) throws {
        // Given the two tiles Settings ships, read from the style itself — the destructive one is
        // drawn on the system's red, which no asset set or other pair here covers (WU-29-H)
        let tiles: [(name: String, style: SettingsIconLabelStyle)] = [
            ("settingsIcon", .settingsIcon),
            ("destructiveSettingsIcon", .destructiveSettingsIcon),
        ]

        for tile in tiles {
            // When the glyph is measured against its tile in this appearance, at the base level and
            // at the elevated level the Settings sheet is drawn at — a glyph in a background colour
            // resolves differently on each
            for elevated in [false, true] {
                let level = elevated ? "(elevated)" : ""
                let pair = try ContrastPair(
                    foreground: Self.read(
                        tile.style.glyph,
                        named: "\(tile.name).glyph\(level)",
                        in: appearance,
                        elevated: elevated
                    ),
                    background: Self.read(
                        tile.style.fill,
                        named: "\(tile.name).fill\(level)",
                        in: appearance,
                        elevated: elevated
                    ),
                    appearance: appearance
                )

                // Then it clears the 3:1 a symbol needs — the title beside it carries the meaning,
                // so a glyph is held to the graphic floor, not the text one
                #expect(pair.ratio >= WCAGContrast.minimumGraphicRatio, "\(pair.summary) (floor 3:1)")
            }

            // And a symbol kept without its tile at accessibility sizes reads on the Settings row
            // itself, drawn in the tile's colour on the sheet's grouped row, base and elevated
            guard tile.style.keepsSymbolWithoutTile else { continue }
            for elevated in [false, true] {
                let bare = try ContrastPair(
                    foreground: Self.read(tile.style.fill, named: "\(tile.name).fill", in: appearance),
                    background: Self.read(
                        .secondarySystemGroupedBackground,
                        named: "secondarySystemGroupedBackground\(elevated ? "(elevated)" : "")",
                        in: appearance,
                        elevated: elevated
                    ),
                    appearance: appearance
                )
                #expect(bare.ratio >= WCAGContrast.minimumGraphicRatio, "\(bare.summary) (floor 3:1)")
            }
        }
    }

    @Test("AccentColor is AppBurgundy in every appearance", arguments: PaletteAppearance.allCases)
    func accentColorIsTheBrandBurgundy(in appearance: PaletteAppearance) throws {
        // Given AccentColor and AppBurgundy resolved for this appearance
        let sut = try makeSUT(in: appearance)

        // When their channels are compared
        let difference = sut.accent.color.largestChannelDifference(from: sut.burgundy.color)

        // Then the system tint is the measured burgundy, not a stale second brand colour
        #expect(
            difference <= Self.channelTolerance,
            """
            AccentColor \(sut.accent.color.hexDescription) is not appBurgundy \
            \(sut.burgundy.color.hexDescription) in \(appearance.testDescription)
            """
        )
    }

    @Test("A card is lighter than any stage it can sit on", arguments: PaletteAppearance.allCases)
    func aCardAdvancesFromTheStage(in appearance: PaletteAppearance) throws {
        // Given the card fill, dough and the top of every stage, resolved for this appearance
        let sut = try makeSUT(in: appearance)
        let cardLuminance = WCAGContrast.relativeLuminance(of: sut.card.color)

        // Then the card is the lighter of each pair, so in dark appearance it reads as raised
        // content rather than a hole in the stage — where `secondarySystemGroupedBackground`,
        // the first choice, failed against every dark stage top
        for surface in sut.stageSurfaces {
            let surfaceLuminance = WCAGContrast.relativeLuminance(of: surface.color)
            #expect(
                cardLuminance > surfaceLuminance,
                """
                appCard \(sut.card.color.hexDescription) is not lighter than \(surface.name) \
                \(surface.color.hexDescription) in \(appearance.testDescription)
                """
            )
        }
    }

    @Test("The four trait collections select four different shipped variants")
    func traitCollectionsSelectDistinctVariants() throws {
        // Given the brand burgundy and the system label, resolved in every appearance
        var burgundies: [String] = []
        for appearance in PaletteAppearance.allCases {
            let burgundy = try Self.read(UIColor(resource: .appBurgundy), named: "appBurgundy", in: appearance)
            let label = try Self.read(.label, named: "label", in: appearance)
            burgundies.append(burgundy.color.hexDescription)

            // Then the system label follows light and dark, which proves the traits were applied
            // at all — otherwise all four "appearances" would silently measure the same one
            let labelIsLight = WCAGContrast.relativeLuminance(of: label.color) > 0.5
            #expect(labelIsLight == appearance.isDark, "label did not flip for \(appearance.testDescription)")
        }

        // And the shipped set carries a value per appearance, so high contrast is really shipped
        #expect(
            Set(burgundies).count == PaletteAppearance.allCases.count,
            "appBurgundy resolved to \(burgundies) for light+normal, dark+normal, light+high, dark+high"
        )
    }

    // MARK: - SUT

    private struct Swatch {
        let name: String
        let color: WCAGContrast.SRGBColor
    }

    private struct ContrastPair {
        let foreground: Swatch
        let background: Swatch
        let appearance: PaletteAppearance

        var ratio: Double {
            WCAGContrast.ratio(foreground.color, background.color)
        }

        /// For example `appBurgundyMuted on stage(balanced.tint) in dark+high = 4.31:1`. The ratio
        /// is floored to two decimals, so a pair just under the floor can never print as `4.50`.
        var summary: String {
            let floored = (ratio * 100).rounded(.down) / 100
            let text = floored.formatted(.number.precision(.fractionLength(2)).locale(Locale(identifier: "en_US")))
            return "\(foreground.name) on \(background.name) in \(appearance.testDescription) = \(text):1"
        }
    }

    private struct ResolvedPalette {
        let pairs: [ContrastPair]
        let accent: Swatch
        let burgundy: Swatch
        let card: Swatch
        /// Dough and the top of every stage: everything a card can be placed on.
        let stageSurfaces: [Swatch]
    }

    /// Resolves the shipped palette for one appearance and builds the declarative pair table.
    private func makeSUT(in appearance: PaletteAppearance) throws -> ResolvedPalette {
        func resolve(_ name: String, _ color: UIColor, elevated: Bool = false) throws -> Swatch {
            try Self.read(color, named: name, in: appearance, elevated: elevated)
        }

        let burgundy = try resolve("appBurgundy", UIColor(resource: .appBurgundy))
        let burgundyMuted = try resolve("appBurgundyMuted", UIColor(resource: .appBurgundyMuted))
        let onBurgundy = try resolve("appOnBurgundy", UIColor(resource: .appOnBurgundy))
        let accent = try resolve("AccentColor", UIColor(resource: .accent))
        let dough = try resolve("appDough", UIColor(resource: .appDough))
        let label = try resolve("label", .label)
        let background = try resolve("systemBackground", .systemBackground)
        let grouped = try resolve("systemGroupedBackground", .systemGroupedBackground)
        let secondaryGrouped = try resolve("secondarySystemGroupedBackground", .secondarySystemGroupedBackground)
        // The same three at the level a sheet is drawn at (Settings), lighter in dark appearance.
        let elevatedSurfaces = try [
            ("systemBackground(elevated)", UIColor.systemBackground),
            ("systemGroupedBackground(elevated)", .systemGroupedBackground),
            ("secondarySystemGroupedBackground(elevated)", .secondarySystemGroupedBackground),
        ].map { try resolve($0.0, $0.1, elevated: true) }
        let systemSurfaces = [background, grouped, secondaryGrouped] + elevatedSurfaces
        // The fill cards and speech bubbles are actually drawn with, not a set assumed to be it.
        let card = try resolve("appCard", UIColor(resource: StageSurface.fill))

        /// The strongest tint behind any text: the accent at the production opacity, over dough.
        func stageTop(over accent: Swatch) -> Swatch {
            Swatch(
                name: "stage(\(accent.name))",
                color: WCAGContrast.composite(accent.color, opacity: StageBackground.accentOpacity, over: dough.color)
            )
        }

        // Today and Welcome stage on burgundy; the verdict stages on its category's tint, and a
        // category's label colour must be the one that reads on that same tint.
        var stageTops = [stageTop(over: burgundy)]
        var onPairs = [(foreground: onBurgundy, background: burgundy)]
        for category in DinnerCategory.allCases {
            let tint = try resolve("\(category.rawValue).tint", UIColor(resource: category.tint))
            let onTint = try resolve("\(category.rawValue).onTint", UIColor(resource: category.onTint))
            stageTops.append(stageTop(over: tint))
            onPairs.append((foreground: onTint, background: tint))
        }

        let textSurfaces = systemSurfaces + [card, dough] + stageTops
        let textPairs = [burgundy, burgundyMuted, label].flatMap { text in
            textSurfaces.map { ContrastPair(foreground: text, background: $0, appearance: appearance) }
        }
        let onColourPairs = onPairs.map {
            ContrastPair(foreground: $0.foreground, background: $0.background, appearance: appearance)
        }

        return ResolvedPalette(
            pairs: textPairs + onColourPairs,
            accent: accent,
            burgundy: burgundy,
            card: card,
            stageSurfaces: [dough] + stageTops
        )
    }

    /// Resolves `color` against `appearance` and reads it as opaque sRGB. Fails loudly rather than
    /// measuring a colour that could not be read, or one that is not opaque — a translucent
    /// colour has no contrast ratio of its own.
    private static func read(
        _ color: UIColor,
        named name: String,
        in appearance: PaletteAppearance,
        elevated: Bool = false
    ) throws -> Swatch {
        let resolved = color.resolvedColor(with: appearance.traits(elevated: elevated))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        let converted = resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        try #require(converted, "\(name) could not be read as RGB in \(appearance.testDescription)")
        try #require(alpha == 1, "\(name) is not opaque in \(appearance.testDescription) (alpha \(alpha))")
        return Swatch(name: name, color: WCAGContrast.SRGBColor(red: red, green: green, blue: blue))
    }
}
