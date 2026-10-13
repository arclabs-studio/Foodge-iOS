//
//  InlinePrimaryActionSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import SwiftUI

/// A form's primary action at accessibility sizes, where `pinnedPrimaryAction` pins nothing (D150).
///
/// The inline half of `PinnedPrimaryActionModifier`'s contract, for a `Form`: a section with no row
/// background, so the prominent button stands on the form's background as it does on a stage. Both
/// halves read `DynamicTypeSize.pinsPrimaryAction`, so they cannot disagree about the threshold. The
/// screen places this section where its content ends.
///
/// **Put a `Button` in it, never a `NavigationLink`.** Inside a `Form` a link is drawn as a list row
/// whatever style it is given: a chevron, and the prominent style's white label on a clear row —
/// rendered invisible on Apple Health at AX 2 (WU-29-H). Push through the view model's path instead.
@MainActor
struct InlinePrimaryActionSection<Action: View>: View {
    @ViewBuilder let action: Action

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if !dynamicTypeSize.pinsPrimaryAction {
            Section {
                action
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }
}

#Preview(traits: .sampleData) {
    Form {
        Section {
            Text("They stay on this iPhone, and Foodge never shows them to anyone.")
        }
        InlinePrimaryActionSection {
            Button("Save and finish") {}
                .primaryAction()
        }
    }
    .dynamicTypeSize(.accessibility2)
}

