//
//  DinnerRoutineSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import SwiftUI

/// How much time the user usually has for dinner, and what that changes.
///
/// Shared by onboarding and Settings, for the same reason as ``DietProfileSection``: identical
/// copy and identical control, two owners that differ only in when they write.
@MainActor
struct DinnerRoutineSection: View {
    @Binding var dinnerRoutine: DinnerTime?
    /// Called after the user picks a different routine. Onboarding leaves it empty.
    let onChange: () -> Void

    init(dinnerRoutine: Binding<DinnerTime?>, onChange: @escaping () -> Void = {}) {
        _dinnerRoutine = dinnerRoutine
        self.onChange = onChange
    }

    var body: some View {
        Section {
            Picker("Most evenings", selection: $dinnerRoutine) {
                Text("No preference").tag(DinnerTime?.none)
                ForEach(DinnerTime.allCases, id: \.self) { time in
                    Text(time.displayName).tag(DinnerTime?.some(time))
                }
            }
            .onChange(of: dinnerRoutine) { _, _ in onChange() }
        } header: {
            Text("Dinner routine")
        } footer: {
            Text(dinnerRoutine.footerDescription)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var dinnerRoutine: DinnerTime?

    Form {
        DinnerRoutineSection(dinnerRoutine: $dinnerRoutine)
    }
}
