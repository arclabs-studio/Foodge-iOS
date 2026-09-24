//
//  DemonstrationSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import SwiftUI

/// The sixth Settings row: running Foodge on clearly labelled example data.
///
/// While a demonstration is running the row does the opposite thing and says so — a control that
/// reads "Demonstration mode" and would start a second one, or does nothing, is what D61/D92 rule
/// against.
@MainActor
struct DemonstrationSection: View {
    let controls: DemonstrationControls

    var body: some View {
        Section {
            if controls.isRunning {
                Button("Exit demonstration", action: controls.exit)
            } else {
                NavigationLink("Demonstration mode", value: SettingsRoute.demonstration)
            }
        } footer: {
            // The footer tracks the state the same way the row label does. Left unbranched, an
            // invitation to start one would sit directly under the control that ends it.
            if controls.isRunning {
                Text("A demonstration is running. Nothing is being read from Apple Health, and nothing is saved to this iPhone.")
            } else {
                Text("Run Foodge on clearly labelled example data. Nothing is read from Apple Health, and nothing is saved to this iPhone.")
            }
        }
    }
}

#Preview("Live", traits: .sizeThatFitsLayout) {
    NavigationStack {
        Form {
            DemonstrationSection(controls: .previewInert)
        }
    }
}

#Preview("Running", traits: .sizeThatFitsLayout) {
    NavigationStack {
        Form {
            DemonstrationSection(controls: .previewRunning)
        }
    }
}
