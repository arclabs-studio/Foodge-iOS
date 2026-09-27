//
//  BodyBasicsView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Accessibility
import SwiftUI

/// The last onboarding step: the diet, the four figures a resting-energy estimate needs (D117),
/// and the single write.
///
/// **The figures are skippable, and honestly so.** Without them Foodge simply cannot estimate
/// resting energy on a phone that has none recorded, and it says that rather than inventing one.
/// Nothing on this screen is stored until the button at the bottom succeeds.
///
/// The diet moved here when the preferences step was deleted (D138). It is the one thing that step
/// gathered which the app still needs: the judge would otherwise propose a burger to a vegetarian
/// with no way of knowing.
@MainActor
struct BodyBasicsView: View {
    @Bindable var vm: OnboardingViewModel

    private var saveFailureMessage: LocalizedStringResource {
        "Foodge couldn’t save your choices. Nothing has been lost — try again."
    }

    var body: some View {
        Form {
            Section {
                Text(
                    """
                    Apple Health doesn’t always record resting energy. When it doesn’t, these four \
                    figures let Foodge estimate it instead of leaving tonight’s verdict to a guess.
                    """
                )
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
                    Text(
                        """
                        Foodge needs all four, in centimetres and kilograms, before it can estimate \
                        anything. Until then it will ask you about your day instead.
                        """
                    )
                }
            }

            DietProfileSection(dietProfile: $vm.draft.dietProfile)

            Section {
                // Both buttons write. The difference is only what they write: a complete set of
                // figures, or none. `applyBodyBasics()` records whatever currently parses, which
                // is `nil` for a half-filled step — so skipping discards the partial answer
                // rather than storing three quarters of a body (D126).
                Button("Save and finish") {
                    vm.applyBodyBasics()
                    Task { await vm.finish() }
                }
                .disabled(vm.saveState == .saving || (vm.hasStartedBodyBasics && vm.bodyBasicsFromInputs == nil))

                if vm.canSkipBodyBasics {
                    Button("Finish without the figures") {
                        vm.applyBodyBasics()
                        Task { await vm.finish() }
                    }
                    .disabled(vm.saveState == .saving)
                    // Both buttons write, and read next to each other their labels already say
                    // what differs — but only the label. The hint spells out the one part that
                    // is not obvious from "Save and finish" sitting right above it: anything
                    // already typed above is discarded, not stored partially (WCAG 3.3.2).
                    .accessibilityHint("Discards anything typed above rather than saving part of it.")
                }

                if vm.saveState == .saving {
                    ProgressView()
                }

                if case .failed = vm.saveState {
                    // `.secondary` measures ~3.4:1 against the row background in standard-contrast
                    // light appearance — below the 4.5:1 WCAG 1.4.3 needs. `AppBurgundyMuted` is
                    // the brand's dedicated secondary-text color, tuned to ≥4.5:1 everywhere.
                    Text(saveFailureMessage)
                        .foregroundStyle(.appBurgundyMuted)
                }
            } footer: {
                // Gated on the same condition as the button it describes: once all four figures
                // parse, `Finish without the figures` is gone and this footer was still telling
                // the user that skipping is fine.
                if vm.canSkipBodyBasics {
                    Text(
                        """
                        Skipping is fine. On a day Health records no resting energy, Foodge will ask how \
                        your day went instead.
                        """
                    )
                }
            }
        }
        .navigationTitle("About you")
        .navigationBarTitleDisplayMode(.inline)
        // Nothing navigates on a failed save: the row appears inside the form the user is already
        // on, so VoiceOver has no reason to visit it (WCAG 4.1.3). `finish()` passes through
        // `.saving`, so a failed retry is a real state change and announces again.
        .onChange(of: vm.saveState) { _, newValue in
            guard case .failed = newValue else { return }
            AccessibilityNotification.Announcement(String(localized: saveFailureMessage)).post()
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

#Preview("Complete") {
    @Previewable @State var vm = PreviewDependencies.all.makeOnboardingViewModel()

    NavigationStack {
        BodyBasicsView(vm: vm)
    }
    // The state the other two previews cannot show: with all four figures valid, both the
    // skip button and the footer describing it are gone, and only `Save and finish` is left.
    .task {
        vm.bodySex = .male
        vm.ageText = "35"
        vm.heightText = "175"
        vm.weightText = "70"
    }
}
