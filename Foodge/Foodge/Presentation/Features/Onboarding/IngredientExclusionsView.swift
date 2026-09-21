//
//  IngredientExclusionsView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 20/09/2026.
//

import SwiftUI

/// Choosing which ingredients this catalogue's dishes must never contain.
///
/// Pushed from `PreferencesView`, which is the one screen that writes — toggling here only
/// mutates the shared draft in memory, and nothing is persisted until Save. Discharges D31: the
/// catalogue now exists, so a picker over these identifiers can no longer produce an exclusion
/// that silently never bites.
@MainActor
struct IngredientExclusionsView: View {
    @Bindable var vm: OnboardingViewModel
    @Environment(\.locale) private var locale
    @State private var searchText: String

    /// - Parameter initialSearchText: Only ever non-empty from a `#Preview` — lets the render
    ///   matrix reach the `ContentUnavailableView.search` empty state without a live device.
    init(vm: OnboardingViewModel, initialSearchText: String = "") {
        self.vm = vm
        _searchText = State(initialValue: initialSearchText)
    }

    private var ingredients: [Ingredient] {
        vm.excludableIngredients(matching: searchText, locale: locale)
    }

    var body: some View {
        List {
            ForEach(ingredients) { ingredient in
                SelectableRow(
                    title: ingredient.displayName,
                    isSelected: vm.draft.excludedIngredientIDs.contains(ingredient.id)
                ) {
                    vm.toggleExclusion(ingredient.id)
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
        IngredientExclusionsView(vm: PreviewDependencies.all.makeOnboardingViewModel())
    }
}

#Preview("No matches", traits: .sampleData) {
    NavigationStack {
        IngredientExclusionsView(
            vm: PreviewDependencies.all.makeOnboardingViewModel(),
            initialSearchText: "zzz-no-such-ingredient"
        )
    }
}
