//
//  SettingsPreferencesView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import SwiftUI

/// Editing the diet profile after onboarding.
///
/// The difference from the onboarding step is when it writes: onboarding holds everything in
/// memory until one Save, because someone who abandons it must leave nothing behind. Here the
/// profile already exists, so the change is saved as it is made and a failure is shown next to it.
///
/// One section, where there were four: favourites, the exclusions link and the dinner routine all
/// left with D138. `DietProfileSection` is still the onboarding control, reused rather than copied
/// (D63).
@MainActor
struct SettingsPreferencesView: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Form {
            DietProfileSection(dietProfile: $vm.draft.dietProfile) {
                Task { await vm.preferencesChanged() }
            }

            SettingsSaveFailureSection(saveState: vm.saveState)
        }
        .navigationTitle("Diet")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview(traits: .sampleData) {
    NavigationStack {
        SettingsPreferencesView(vm: PreviewDependencies.all.makeSettingsViewModel())
    }
}
