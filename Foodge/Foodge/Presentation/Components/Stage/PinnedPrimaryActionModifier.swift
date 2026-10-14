//
//  PinnedPrimaryActionModifier.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// Pins a stage screen's primary action to the bottom edge at standard text sizes (WU-29-C).
///
/// A `safeAreaBar` rather than an inset, so the system draws its scroll edge effect where content
/// passes under the button. At accessibility sizes it pins nothing: the screen places the same action
/// at the end of its scrolling content instead, where a button grown tall cannot cover what is above
/// it (WCAG 1.4.10 Reflow) — the half the screen keeps, because only it knows where its content ends.
///
/// **A screen that adopts this must also place the action inline** wherever
/// `DynamicTypeSize.pinsPrimaryAction` is `false`, or it has no primary action at accessibility sizes.
/// Both halves read that one property, so they cannot disagree about the threshold.
@MainActor
struct PinnedPrimaryActionModifier<Action: View>: ViewModifier {
    let action: Action

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        content
            .safeAreaBar(edge: .bottom) {
                if dynamicTypeSize.pinsPrimaryAction {
                    action
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
    }
}

extension View {
    /// Pins `action` to the bottom edge at standard text sizes; see `PinnedPrimaryActionModifier`.
    func pinnedPrimaryAction(@ViewBuilder _ action: () -> some View) -> some View {
        modifier(PinnedPrimaryActionModifier(action: action()))
    }
}

extension DynamicTypeSize {
    /// Whether a stage screen's primary action is pinned at this size — the threshold both
    /// `PinnedPrimaryActionModifier` and the screen's inline copy read.
    var pinsPrimaryAction: Bool {
        !isAccessibilitySize
    }
}

#Preview(traits: .sampleData) {
    ScrollView {
        Image(.judgeWelcome)
            .resizable()
            .scaledToFit()
            .padding()
    }
    .pinnedPrimaryAction {
        Button("Continue") {}
            .primaryAction()
    }
    .background { StageBackground(accent: .appBurgundy) }
}
