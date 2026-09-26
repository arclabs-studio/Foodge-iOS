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
    let demonstration: DemonstrationControls

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink("Preferences", value: SettingsRoute.preferences)
                }

                // Hidden during a demonstration, both of them, because neither can tell the truth
                // there: the stubbed reminder accepts silently, so the toggle would read "on" for
                // a reminder the system never received, and the delete copy promises every saved
                // case is gone from this iPhone when nothing was ever on the iPhone (D102).
                if !demonstration.isRunning {
                    EveningReminderSection(vm: vm)
                }
                HealthGuidanceSection()
                JudgeFlourishSection(vm: vm)
                DemonstrationSection(controls: demonstration)
                if !demonstration.isRunning {
                    DeleteLocalDataSection(vm: vm)
                }
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
                case .demonstration:
                    DemonstrationScenariosView(controls: demonstration)
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
    SettingsView(vm: PreviewDependencies.all.makeSettingsViewModel(), onLocalDataErased: {}, demonstration: .previewInert)
}

#Preview("During a demonstration", traits: .sampleData) {
    SettingsView(
        vm: PreviewDependencies.all.makeSettingsViewModel(),
        onLocalDataErased: {},
        demonstration: .previewRunning
    )
}

#Preview("Reminder refused", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies
        .reminderRefused()
        .makeSettingsViewModel()

    SettingsView(vm: vm, onLocalDataErased: {}, demonstration: .previewInert)
        .task {
            vm.reminderEnabled = true
            await vm.reminderEnabledChanged(to: true)
        }
}
