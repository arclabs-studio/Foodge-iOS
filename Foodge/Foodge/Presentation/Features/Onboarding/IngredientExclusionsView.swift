//
//  IngredientExclusionsView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 20/09/2026.
//

import SwiftUI

/// Choosing which ingredients this catalogue's dishes must never contain.
///
/// Shared by both screens that offer exclusions: pushed from `PreferencesView` during onboarding,
/// where toggling mutates the in-memory draft and nothing is written until Save, and from
/// `SettingsPreferencesView` afterwards, where each toggle saves immediately. It therefore takes
/// the selection and the action rather than a view model — one copy, two owners, no second list
/// to keep in step (D63/D70/D71).
///
/// Discharges D31: the catalogue now exists, so a picker over these identifiers can no longer
/// produce an exclusion that silently never bites.
@MainActor
struct IngredientExclusionsView: View {
    let excludedIngredientIDs: Set<String>
    let toggle: (String) -> Void

    @Environment(\.locale) private var locale
    @State private var searchText: String

    /// - Parameter initialSearchText: Only ever non-empty from a `#Preview` — lets the render
    ///   matrix reach the `ContentUnavailableView.search` empty state without a live device.
    init(
        excludedIngredientIDs: Set<String>,
        initialSearchText: String = "",
        toggle: @escaping (String) -> Void
    ) {
        self.excludedIngredientIDs = excludedIngredientIDs
        self.toggle = toggle
        _searchText = State(initialValue: initialSearchText)
    }

    private var ingredients: [Ingredient] {
        Ingredient.excludable(matching: searchText, in: locale)
    }

    var body: some View {
        List {
            ForEach(ingredients) { ingredient in
                SelectableRow(
                    title: ingredient.displayName,
                    isSelected: excludedIngredientIDs.contains(ingredient.id)
                ) {
                    toggle(ingredient.id)
                }
            }
        }
        .overlay {
            if ingredients.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Exclude ingredients")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Editing", traits: .sampleData) {
    NavigationStack {
        IngredientExclusionsView(excludedIngredientIDs: [Ingredient.rice.id]) { _ in }
    }
}

#Preview("No matches", traits: .sampleData) {
    NavigationStack {
        IngredientExclusionsView(
            excludedIngredientIDs: [],
            initialSearchText: "zzz-no-such-ingredient"
        ) { _ in }
    }
}
