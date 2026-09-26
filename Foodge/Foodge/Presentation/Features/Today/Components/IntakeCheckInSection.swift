//
//  IntakeCheckInSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import SwiftUI

/// Where the user says what they have eaten so far, for the days Health did not log it.
///
/// Three pickers, each with a "Not answered" option that is **not** the same as "Skipped": an
/// unanswered meal contributes nothing and leaves the questionnaire unusable, while a skipped one is
/// an answer worth zero. The rule depends on that distinction, so the control has to offer both.
@MainActor
struct IntakeCheckInSection: View {
    @Bindable var vm: TodayViewModel

    var body: some View {
        Section {
            MealPortionPicker(title: "Breakfast", portion: $vm.breakfast)
            MealPortionPicker(title: "Lunch", portion: $vm.lunch)
            MealPortionPicker(title: "Snacks", portion: $vm.snacks)
        } header: {
            Text("Eaten so far")
        } footer: {
            Text("Only used when Apple Health has no food logged for today. What Health recorded always replaces these answers rather than adding to them.")
        }
    }
}

/// One meal's picker, in the same `.navigationLink` style as the Tonight section's.
@MainActor
struct MealPortionPicker: View {
    let title: LocalizedStringKey
    @Binding var portion: MealPortion?

    var body: some View {
        Picker(title, selection: $portion) {
            Text("Not answered").tag(MealPortion?.none)
            ForEach(MealPortion.allCases, id: \.self) { portion in
                Text(portion.displayName).tag(MealPortion?.some(portion))
            }
        }
        .pickerStyle(.navigationLink)
    }
}

#Preview(traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.all.makeTodayViewModel()

    NavigationStack {
        Form {
            IntakeCheckInSection(vm: vm)
        }
    }
}
