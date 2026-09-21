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

    @ScaledMetric(relativeTo: .body) private var checkmarkSize: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var checkmarkLineWidth: CGFloat = 2

    var body: some View {
        // A plain `HStack` label rather than `LabeledContent`: inside a `Button`, the latter
        // forms its own accessibility container, which stopped the row responding to taps at
        // all and left every checkmark exposed as a separate "Selected" element — so VoiceOver
        // announced all nine dishes as selected. Caught on device, not in a preview.
        Button(action: action) {
            HStack {
                Text(title)
                Spacer(minLength: 12)
                if isSelected {
                    // A hand-drawn `Shape`, never `Image(systemName: "checkmark")`. Four attempts
                    // to hide the SF Symbol from VoiceOver with SwiftUI accessibility modifiers —
                    // on the glyph, the label content, the `Button`, and combinations of
                    // `.ignore`/`.combine` — all failed identically on device, including
                    // `.accessibilityHidden(true)` applied directly to the leaf `Image` itself.
                    // That ruled out modifier placement: iOS recognizes an SF Symbol literally
                    // named "checkmark" inside a `Form`/`List` row as a selection accessory at
                    // the system level and re-injects its own "Selected" element regardless of
                    // what the view hierarchy declares. A shape with no such name carries no
                    // symbol identity for that heuristic to key off — confirmed on a fifth
                    // on-device pass: the hierarchy dump no longer shows any element labelled
                    // "Selected" other than the row's own trait. That dump can't certify a live
                    // VoiceOver swipe count directly (the tooling has no VoiceOver-navigation
                    // command), so treat this as strong structural evidence, not a substitute for
                    // an actual swipe-through before shipping.
                    CheckmarkMark()
                        .stroke(
                            Color.appBurgundy,
                            style: StrokeStyle(lineWidth: checkmarkLineWidth, lineCap: .round, lineJoin: .round)
                        )
                        .frame(width: checkmarkSize, height: checkmarkSize)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// A plain checkmark stroke, drawn rather than an SF Symbol — see the comment above for why.
private struct CheckmarkMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
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
