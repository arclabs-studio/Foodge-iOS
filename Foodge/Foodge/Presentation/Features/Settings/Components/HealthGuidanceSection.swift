//
//  HealthGuidanceSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import SwiftUI

/// What Foodge reads from Health, and where to change it.
///
/// Read-only on purpose. An app cannot ask Health what it was granted, so this section never
/// reports a state: it says what is read and points at the Health app, in absence wording. There
/// is no "denied" here and there never will be — HealthKit cannot tell an app that.
@MainActor
struct HealthGuidanceSection: View {
    var body: some View {
        Section {
            Text("Foodge reads steps, active and resting energy, workouts, dietary energy and sleep. It only ever reads, and it never writes to Health.")
            Text("Change what Foodge can read in the Health app, under Sharing. With nothing readable, Foodge asks you how the day went instead.")
        } header: {
            Text("Health")
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    Form {
        HealthGuidanceSection()
    }
}
