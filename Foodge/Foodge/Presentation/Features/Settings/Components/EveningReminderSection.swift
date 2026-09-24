//
//  EveningReminderSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Accessibility
import SwiftUI

/// The one optional reminder: whether it exists, and at what time.
///
/// Permission is requested here and nowhere earlier — the plan's progressive-onboarding rule is
/// that notification permission comes when someone actually asks for a reminder. The time picker
/// only appears once the toggle is on, so the screen never offers a setting that does nothing.
@MainActor
struct EveningReminderSection: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Section {
            Toggle("Evening reminder", isOn: $vm.reminderEnabled)
                .onChange(of: vm.reminderEnabled) { _, isEnabled in
                    Task { await vm.reminderEnabledChanged(to: isEnabled) }
                }

            if vm.reminderEnabled {
                DatePicker(
                    "Time",
                    selection: $vm.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: vm.reminderTime) { _, _ in
                    Task { await vm.reminderTimeChanged() }
                }
            }

            if let failure = vm.reminderFailure {
                // `.secondary` measures below 4.5:1 on this background in standard-contrast light
                // appearance; `AppBurgundyMuted` is the brand's secondary-text colour, tuned to
                // meet WCAG 1.4.3 in all four appearances.
                Text(failure.reminderMessage)
                    .foregroundStyle(.appBurgundyMuted)
            }
        } header: {
            Text("Reminder")
        } footer: {
            Text("A nudge at the time you choose. It says nothing about your day — Foodge reads nothing while you are away.")
        }
        .onChange(of: vm.reminderFailure) { _, failure in
            // The toggle already reverted itself with no navigation and no focus change, so
            // VoiceOver would never encounter the message below it without this — the same
            // failure-must-be-heard rule as `SettingsSaveFailureSection` (WCAG 4.1.3).
            guard let failure else { return }
            AccessibilityNotification.Announcement(String(localized: failure.reminderMessage)).post()
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    Form {
        EveningReminderSection(vm: PreviewDependencies.all.makeSettingsViewModel())
    }
}
