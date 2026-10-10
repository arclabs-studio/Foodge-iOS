//
//  DietProfileSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import SwiftUI

/// What the user will eat, and the promise that Foodge never decides it for them.
///
/// Shared by onboarding and Settings. The two differ only in when they write — onboarding holds
/// the draft until one Save, Settings saves on every change (D90) — so the section takes the
/// binding and an optional "it changed" action rather than either view model.
@MainActor
struct DietProfileSection: View {
    @Binding var dietProfile: DietProfile
    /// Called after the user picks a different diet. Onboarding leaves it empty: nothing is
    /// written until its own Save.
    let onChange: () -> Void

    init(dietProfile: Binding<DietProfile>, onChange: @escaping () -> Void = {}) {
        _dietProfile = dietProfile
        self.onChange = onChange
    }

    var body: some View {
        Section {
            MenuPickerRow(title: "Diet", value: dietProfile.displayName, selection: $dietProfile) {
                ForEach(DietProfile.allCases, id: \.self) { profile in
                    Text(profile.displayName).tag(profile)
                }
            }
            .onChange(of: dietProfile) { _, _ in onChange() }
        } footer: {
            Text("Foodge never infers this from Health, and never relaxes it to find a match.")
                // A footer is drawn in `.secondary`, about 3.3:1 on the light grouped background;
                // `appBurgundyMuted` is measured there by `PaletteContrastTests` (D134, D145).
                .foregroundStyle(.appBurgundyMuted)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout, .sampleData) {
    @Previewable @State var dietProfile = DietProfile.omnivore

    Form {
        DietProfileSection(dietProfile: $dietProfile)
    }
}
