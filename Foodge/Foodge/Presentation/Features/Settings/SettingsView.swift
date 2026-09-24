//
//  SettingsView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import SwiftUI

/// Settings: preferences, the evening reminder, what Foodge reads from Health, the judge's
/// flourish, and deleting everything kept here.
///
/// Presented as a sheet carrying its own `NavigationStack` rather than pushed onto Today's:
/// Today's stack belongs to the verdict flow, and pushing Settings into it would leave Settings
/// sitting on the path back from a verdict.
@MainActor
struct SettingsView: View {
    @Bindable var vm: SettingsViewModel
    /// Called once the local store has actually been emptied, so the app can go back to its
    /// first-launch state instead of showing a profile that no longer exists.
    let onLocalDataErased: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink("Preferences", value: SettingsRoute.preferences)
                }

                EveningReminderSection(vm: vm)
                HealthGuidanceSection()
                JudgeFlourishSection(vm: vm)
                DeleteLocalDataSection(vm: vm)
                SettingsSaveFailureSection(saveState: vm.saveState)
            }
            .navigationTitle("Settings")
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .preferences:
                    SettingsPreferencesView(vm: vm)
                case .ingredientExclusions:
                    IngredientExclusionsView(
                        excludedIngredientIDs: vm.draft.excludedIngredientIDs
                    ) { ingredientID in
                        Task { await vm.toggleExclusion(ingredientID) }
                    }
                }
            }
            .toolbar {
                // The role, not a title: iOS 27 draws the Liquid Glass close glyph and supplies
                // the accessibility label itself. `.close` rather than `.cancel` because there
                // is no draft to lose — every change on this screen is already saved (D90). Same
                // shape as `AppealSheetView`'s dismissal.
                Button(role: .close) { dismiss() }
            }
            .task { await vm.load() }
            .onChange(of: vm.deleteState) { _, state in
                guard state == .deleted else { return }
                onLocalDataErased()
            }
        }
    }
}

#Preview(traits: .sampleData) {
    SettingsView(vm: PreviewDependencies.all.makeSettingsViewModel()) {}
}

#Preview("Reminder refused", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies
        .reminderRefused()
        .makeSettingsViewModel()

    SettingsView(vm: vm) {}
        .task {
            vm.reminderEnabled = true
            await vm.reminderEnabledChanged(to: true)
        }
}
