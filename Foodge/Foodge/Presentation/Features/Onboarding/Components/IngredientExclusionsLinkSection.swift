//
//  IngredientExclusionsLinkSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import SwiftUI

/// The row that leads to the exclusion list, showing how many are set.
///
/// Generic over the route value because the two stacks that show it use different route enums
/// (`OnboardingRoute` and `SettingsRoute`) — the row itself is the same row, so it is written
/// once rather than twice (platform rule 7).
@MainActor
struct IngredientExclusionsLinkSection<Route: Hashable>: View {
    let excludedCount: Int
    let route: Route

    var body: some View {
        Section {
            NavigationLink(value: route) {
                LabeledContent(
                    "Ingredients to exclude",
                    value: excludedCount,
                    format: .number
                )
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    NavigationStack {
        Form {
            IngredientExclusionsLinkSection(
                excludedCount: 3,
                route: SettingsRoute.ingredientExclusions
            )
        }
    }
}
