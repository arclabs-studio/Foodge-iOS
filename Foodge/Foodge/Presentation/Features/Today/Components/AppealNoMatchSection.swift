//
//  AppealNoMatchSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 22/09/2026.
//

import SwiftUI

/// Honest no-match: nothing in the craved family satisfies every constraint, and nothing was
/// relaxed to force one.
@MainActor
struct AppealNoMatchSection: View {
    let family: DishFamily
    let blockingIngredientIDs: Set<String>
    let tryAnother: () -> Void

    var body: some View {
        Section {
            Text("No compatible match for \(String(localized: family.displayName)) tonight.")
            Text("Nothing was relaxed to force a match — you can adjust your exclusions in Preferences.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Try another craving") { tryAnother() }
        }
    }
}

#Preview {
    Form {
        AppealNoMatchSection(
            family: .tacos,
            blockingIngredientIDs: [Ingredient.blackBeans.id],
            tryAnother: {}
        )
    }
}
