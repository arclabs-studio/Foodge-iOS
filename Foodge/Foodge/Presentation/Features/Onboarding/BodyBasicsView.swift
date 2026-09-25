//
//  BodyBasicsView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import SwiftUI

/// Where the user gives the four figures a resting-energy estimate needs (D117).
///
/// **Skippable, and honestly so.** Without these figures Foodge simply cannot estimate resting
/// energy on a phone that has none recorded, and it says that rather than inventing one. Nothing on
/// this screen is stored until onboarding finishes.
@MainActor
struct BodyBasicsView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        Form {
            Section {
                Text("Apple Health doesn’t always record resting energy. When it doesn’t, these four figures let Foodge estimate it instead of leaving tonight’s verdict to a guess.")
                Text("They stay on this iPhone, and Foodge never shows them to anyone.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)
            }

            Section {
                Picker("Sex", selection: $vm.bodySex) {
                    Text("Not given").tag(BiologicalSex?.none)
                    ForEach(BiologicalSex.allCases, id: \.self) { sex in
                        Text(sex.displayName).tag(BiologicalSex?.some(sex))
                    }
                }

                LabeledContent("Age") {
                    TextField("Years", text: $vm.ageText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Age in years")
                }
                LabeledContent("Height") {
                    TextField("Centimetres", text: $vm.heightText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Height in centimetres")
                }
                LabeledContent("Weight") {
                    TextField("Kilograms", text: $vm.weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .accessibilityLabel("Weight in kilograms")
                }
            } footer: {
                if vm.hasStartedBodyBasics, vm.bodyBasicsFromInputs == nil {
                    Text("Foodge needs all four, in centimetres and kilograms, before it can estimate anything. Until then it will ask you about your day instead.")
                }
            }

            Section {
                NavigationLink("Continue", value: OnboardingRoute.preferences)
                    .disabled(vm.hasStartedBodyBasics && vm.bodyBasicsFromInputs == nil)

                if vm.canSkipBodyBasics {
                    NavigationLink("Skip for now", value: OnboardingRoute.preferences)
                }
            } footer: {
                Text("Skipping is fine. On a day Health records no resting energy, Foodge will ask how your day went instead.")
            }
        }
        .navigationTitle("About you")
        .navigationBarTitleDisplayMode(.inline)
        // Applied on the way out rather than on every keystroke: the draft holds a whole body or
        // nothing, never three answers and a half.
        .onDisappear {
            vm.applyBodyBasics()
        }
    }
}

#Preview("Empty") {
    NavigationStack {
        BodyBasicsView(vm: PreviewDependencies.all.makeOnboardingViewModel())
    }
}

#Preview("Half answered") {
    @Previewable @State var vm = PreviewDependencies.all.makeOnboardingViewModel()

    NavigationStack {
        BodyBasicsView(vm: vm)
    }
    .task {
        vm.bodySex = .female
        vm.ageText = "34"
    }
}
