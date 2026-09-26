//
//  SettingsPreferencesView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import SwiftUI

/// Editing, after onboarding, the same four things onboarding gathered.
///
/// The difference from `PreferencesView` is when it writes: onboarding holds everything in memory
/// until one Save, because someone who abandons it must leave nothing behind. Here the profile
/// already exists, so each change is saved as it is made and a failure is shown next to it.
///
/// The favourites and exclusions controls are the onboarding ones, reused rather than copied
/// (D63/D70/D71).
@MainActor
struct SettingsPreferencesView: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Form {
            DietProfileSection(dietProfile: $vm.draft.dietProfile) {
                Task { await vm.preferencesChanged() }
            }

            IngredientExclusionsLinkSection(
                excludedCount: vm.draft.excludedIngredientIDs.count,
                route: SettingsRoute.ingredientExclusions
            )

            ForEach(DinnerCategory.allCases, id: \.self) { category in
                FavouriteFamiliesSection(
                    category: category,
                    favourites: vm.draft.favouriteFamilies
                ) { family in
                    Task { await vm.toggleFavourite(family) }
                }
            }

            DinnerRoutineSection(dinnerRoutine: $vm.draft.dinnerRoutine) {
                Task { await vm.preferencesChanged() }
            }

            SettingsSaveFailureSection(saveState: vm.saveState)
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        SettingsPreferencesView(vm: PreviewDependencies.all.makeSettingsViewModel())
    }
}
