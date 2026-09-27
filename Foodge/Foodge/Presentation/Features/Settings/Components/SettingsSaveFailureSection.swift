//
//  SettingsSaveFailureSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Accessibility
import SwiftUI

/// The one thing both Settings screens must say when a write does not complete.
///
/// Settings saves each change as it is made, so the failure has to be visible wherever the edit
/// was: the root screen and the preferences screen both render this, from one definition rather
/// than two copies of the sentence (D63/D70/D71).
@MainActor
struct SettingsSaveFailureSection: View {
    let saveState: SettingsViewModel.SaveState

    private var failureMessage: LocalizedStringResource {
        "Foodge couldn’t save that change. What you see here is what you chose — try again."
    }

    var body: some View {
        Group {
            if case .failed = saveState {
                Section {
                    // `.secondary` falls below 4.5:1 on this background in standard-contrast
                    // light appearance; `AppBurgundyMuted` is the brand's secondary-text colour.
                    Text(failureMessage)
                        .foregroundStyle(.appBurgundyMuted)
                }
            }
        }
        .onChange(of: saveState) { _, newValue in
            // The row appears with no navigation and no focus change, so VoiceOver never reaches
            // it on its own (WCAG 4.1.3) — unlike D79's decorative narration line, a save failure
            // is something the user must act on.
            guard case .failed = newValue else { return }
            AccessibilityNotification.Announcement(String(localized: failureMessage)).post()
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    Form {
        SettingsSaveFailureSection(saveState: .failed(.saveFailed))
    }
}
