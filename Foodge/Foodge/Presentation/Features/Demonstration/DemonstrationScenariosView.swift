//
//  DemonstrationScenariosView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Accessibility
import SwiftUI

/// The ten labelled scenarios Foodge can be run on, in the order the catalogue offers them.
///
/// Choosing one replaces the whole session, which destroys this screen along with the sheet it is
/// in — so there is nothing to dismiss here and no state to keep on success.
///
/// A **failed** attempt deliberately leaves this screen standing (D105): `AppLaunch` assigns
/// `state` only on success, and `TodayFlowView` does not dismiss the sheet before starting, so the
/// failure row and its announcement below have somewhere to appear. An earlier shape routed the
/// failure through a loading state, which tore this view down before `controls.failure` could turn
/// non-nil and made a failed start invisible to everyone.
@MainActor
struct DemonstrationScenariosView: View {
    let controls: DemonstrationControls

    var body: some View {
        List {
            Section {
                ForEach(DemonstrationScenarioID.allCases) { scenario in
                    Button {
                        controls.start(scenario)
                    } label: {
                        DemonstrationScenarioRow(scenario: scenario)
                    }
                    // Without this the row is drawn in the button tint, which turns a title and
                    // its explanation into two shades of burgundy and quietly changes the
                    // contrast the accessibility audit measured. `.plain` lets the label keep the
                    // system's own primary/secondary colours; a `List` row still highlights on
                    // touch, so nothing about the affordance is lost.
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("Every scenario uses invented data. Nothing is read from Apple Health, and nothing is saved to this iPhone.")
            }

            if let failure = controls.failure {
                Section {
                    Text(failure.demonstrationMessage)
                        .foregroundStyle(.appBurgundyMuted)
                }
            }
        }
        .navigationTitle("Demonstration mode")
        // Same shape as `DeleteLocalDataSection` (WCAG 4.1.3): a failure that shows as a plain row
        // with no navigation and no focus change needs its own announcement, because nothing else
        // tells VoiceOver the list just grew a failure message.
        .onChange(of: controls.failure) { _, newValue in
            guard let failure = newValue else { return }
            AccessibilityNotification.Announcement(String(localized: failure.demonstrationMessage)).post()
        }
    }
}

/// One scenario, as a title and the line that says what it is there to show.
@MainActor
private struct DemonstrationScenarioRow: View {
    let scenario: DemonstrationScenarioID

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scenario.displayName)
                .font(.body)
                .foregroundStyle(.primary)

            Text(scenario.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        // The title and its explanation are one thing to VoiceOver — reading them as two rows
        // would make the list twice as long for no extra information.
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        DemonstrationScenariosView(controls: .previewInert)
    }
}

#Preview("Failed to start") {
    NavigationStack {
        DemonstrationScenariosView(controls: .previewFailed)
    }
}
