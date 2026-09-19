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
/// Ingredient exclusions are deliberately absent. The catalogue they would be chosen from
/// arrives on Day 20, and a picker over identifiers that do not exist yet would produce
/// exclusions that silently never bite (D31).
@MainActor
struct PreferencesView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        Form {
            Section {
                Picker("Diet", selection: $vm.draft.dietProfile) {
                    ForEach(DietProfile.allCases, id: \.self) { profile in
                        Text(profile.displayName).tag(profile)
                    }
                }
            } footer: {
                Text("Foodge never infers this from Health, and never relaxes it to find a match.")
            }

            ForEach(DinnerCategory.allCases, id: \.self) { category in
                FavouriteFamiliesSection(
                    category: category,
                    favourites: vm.draft.favouriteFamilies,
                    toggle: vm.toggleFavourite
                )
            }

            Section {
                Picker("Most evenings", selection: $vm.draft.dinnerRoutine) {
                    Text("No preference").tag(DinnerTime?.none)
                    ForEach(DinnerTime.allCases, id: \.self) { time in
                        Text(time.displayName).tag(DinnerTime?.some(time))
                    }
                }
            } header: {
                Text("Dinner routine")
            } footer: {
                Text(vm.draft.dinnerRoutine.footerDescription)
            }

            Section {
                Button("Save and finish") {
                    Task { await vm.finish() }
                }
                .disabled(vm.saveState == .saving)

                if vm.saveState == .saving {
                    ProgressView()
                }

                if case .failed = vm.saveState {
                    Text("Foodge couldn’t save your choices. Nothing has been lost — try again.")
                        .foregroundStyle(.secondary)
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
