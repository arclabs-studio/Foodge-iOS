//
//  SettingsIconLabelStyle.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import SwiftUI

/// A Settings row's symbol in a filled tile, the way iOS Settings draws its own rows (D151).
///
/// Only rows that act wear one, and in the tint: the HIG's *Color* guidance keeps the brand colour
/// for what is interactive, so a symbol that only informs takes `appBurgundyMuted` instead and no
/// tile. The glyph is `appOnBurgundy` on `appBurgundy`, the pair `PaletteContrastTests` measures for
/// the primary action. A destructive row uses ``destructiveSettingsIcon``: red marks what deletes.
///
/// The tile is decoration — the title names the row — so VoiceOver skips it, and **at accessibility
/// sizes it is not drawn**: a tile scaled to AX 5 took a fifth of the row and broke *Evening reminder*
/// mid-word beside its switch (`arc-audit-accessibility`). `HistoryCaseRow` gives up its artwork the
/// same way. The destructive row keeps its symbol there, bare and red, because the symbol is the only
/// red on a row whose title is in the label colour (`arc-audit-hig`).
///
/// The colours are held as `UIColor` so `PaletteContrastTests` can resolve the shipped pair in every
/// appearance — the destructive tile's glyph on system red is not one of the asset catalogue's sets.
@MainActor
struct SettingsIconLabelStyle: LabelStyle {
    let fill: UIColor
    let glyph: UIColor
    /// Whether the symbol stays, bare in the fill colour, when the tile is dropped at accessibility
    /// sizes — true only where it is the row's one cue, as on *Delete local data*.
    var keepsSymbolWithoutTile = false

    func makeBody(configuration: Configuration) -> some View {
        SettingsIconLabel(
            fill: Color(uiColor: fill),
            glyph: Color(uiColor: glyph),
            keepsSymbolWithoutTile: keepsSymbolWithoutTile,
            title: configuration.title,
            icon: configuration.icon
        )
    }
}

/// The row's layout: the tile beside the title, or at accessibility sizes the title alone — or beside
/// the bare symbol, for the one row whose symbol is its cue.
@MainActor
private struct SettingsIconLabel<Title: View, Icon: View>: View {
    let fill: Color
    let glyph: Color
    let keepsSymbolWithoutTile: Bool
    let title: Title
    let icon: Icon

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            if keepsSymbolWithoutTile {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    icon
                        .foregroundStyle(fill)
                        .accessibilityHidden(true)
                    title
                }
            } else {
                title
            }
        } else {
            HStack(spacing: 14) {
                SettingsIconTile(fill: fill, glyph: glyph) {
                    icon
                }
                title
                    // Lets the row's separator start under the title, as it does for a system label.
                    .alignmentGuide(.listRowSeparatorLeading) { dimensions in
                        dimensions[.leading]
                    }
            }
        }
    }
}

/// The filled square behind a Settings symbol, scaling with the text beside it up to `xxxLarge`.
@MainActor
private struct SettingsIconTile<Icon: View>: View {
    let fill: Color
    let glyph: Color
    @ViewBuilder let icon: Icon

    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 29

    var body: some View {
        icon
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(glyph)
            .frame(width: side, height: side)
            .background(fill, in: RoundedRectangle(cornerRadius: side * 0.24, style: .continuous))
            .accessibilityHidden(true)
    }
}

extension LabelStyle where Self == SettingsIconLabelStyle {
    /// A Settings row that acts: its symbol in a tile of the tint.
    static var settingsIcon: SettingsIconLabelStyle {
        .init(fill: UIColor(resource: .appBurgundy), glyph: UIColor(resource: .appOnBurgundy))
    }

    /// A Settings row that deletes: its symbol in a system-red tile.
    ///
    /// The glyph is cut out in `systemBackground` — white in light appearance, near-black in dark —
    /// rather than white throughout: system red lightens in dark appearance with Increased Contrast,
    /// and white on it measured 2.93:1, under the 3:1 a graphic needs (`PaletteContrastTests`). The
    /// burgundy tile already draws a dark glyph in dark appearance, so the two tiles match.
    static var destructiveSettingsIcon: SettingsIconLabelStyle {
        .init(fill: .systemRed, glyph: .systemBackground, keepsSymbolWithoutTile: true)
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var isOn = true

    Form {
        Section {
            Label("Diet", systemImage: "fork.knife")
                .labelStyle(.settingsIcon)
            Toggle(isOn: $isOn) {
                Label("Evening reminder", systemImage: "bell.fill")
                    .labelStyle(.settingsIcon)
            }
        }
        Section {
            Label("Delete local data", systemImage: "trash.fill")
                .labelStyle(.destructiveSettingsIcon)
        }
    }
}
