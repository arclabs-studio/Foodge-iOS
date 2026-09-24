//
//  PreferencesView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// What the user will eat, what they like, and how much time they usually have.
///
/// This is the screen that writes: everything before it was gathered in memory, and the single
/// save happens here. A failed save keeps the whole form visible with a retry — it is never
/// reported as a save.
///
/// Ingredient exclusions push to their own screen rather than living inline here (D31, resolved
/// in WU-20-A): the catalogue now exists, so a picker over its real identifiers can no longer
/// produce an exclusion that silently never bites.
@MainActor
struct PreferencesView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        Form {
            DietProfileSection(dietProfile: $vm.draft.dietProfile)

            IngredientExclusionsLinkSection(
                excludedCount: vm.draft.excludedIngredientIDs.count,
                route: OnboardingRoute.ingredientExclusions
            )

            ForEach(DinnerCategory.allCases, id: \.self) { category in
                FavouriteFamiliesSection(
                    category: category,
                    favourites: vm.draft.favouriteFamilies,
                    toggle: vm.toggleFavourite
                )
            }

            DinnerRoutineSection(dinnerRoutine: $vm.draft.dinnerRoutine)

            Section {
                Button("Save and finish") {
                    Task { await vm.finish() }
                }
                .disabled(vm.saveState == .saving)

                if vm.saveState == .saving {
                    ProgressView()
                }

                if case .failed = vm.saveState {
                    // `.secondary` measures ~3.4:1 against the row background in standard-contrast
                    // light appearance — below the 4.5:1 WCAG 1.4.3 needs. `AppBurgundyMuted` is
                    // the brand's dedicated secondary-text color, tuned to ≥4.5:1 everywhere.
                    Text("Foodge couldn’t save your choices. Nothing has been lost — try again.")
                        .foregroundStyle(.appBurgundyMuted)
                }
            }
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Editing", traits: .sampleData) {
    NavigationStack {
        PreferencesView(vm: PreviewDependencies.all.makeOnboardingViewModel())
    }
}

#Preview("Save failed") {
    @Previewable @State var vm = PreviewDependencies.savingFails().makeOnboardingViewModel()

    NavigationStack {
        PreferencesView(vm: vm)
    }
    .task { await vm.finish() }
}
