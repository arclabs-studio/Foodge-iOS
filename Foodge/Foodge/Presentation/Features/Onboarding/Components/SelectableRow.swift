//
//  SelectableRow.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// A row that is either chosen or not, for the choices that are membership of a set.
///
/// A `Toggle` would be the native control for an independent on/off, but these choices live in
/// an array on the draft, and a per-item `Binding` over array membership can only be hand-built
/// — which the doctrine forbids. A button row carrying `.isSelected` is the native, accessible
/// alternative, and it is what Apple's own pickers do.
@MainActor
struct SelectableRow: View {
    let title: LocalizedStringResource
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        // A plain `HStack` label rather than `LabeledContent`: inside a `Button`, the latter
        // forms its own accessibility container, which stopped the row responding to taps at
        // all and left every checkmark exposed as a separate "Selected" element — so VoiceOver
        // announced all nine dishes as selected. Caught on device, not in a preview.
        Button(action: action) {
            HStack {
                Text(title)
                Spacer(minLength: 12)
                // Built only when selected, rather than drawn and hidden with `.opacity(0)`.
                // A trailing checkmark in a `Form` row becomes the row's native accessory,
                // and an accessory ignores `.accessibilityHidden(true)` — so the invisible
                // version still announced itself as "Selected" on all nine rows, contradicting
                // the button's own trait. Verified on device, twice.
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.appBurgundy)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    Form {
        Section {
            SelectableRow(title: DishFamily.tacos.displayName, isSelected: true) {}
            SelectableRow(title: DishFamily.pasta.displayName, isSelected: false) {}
        }
    }
}
