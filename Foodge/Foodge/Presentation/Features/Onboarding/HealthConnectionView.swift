//
//  HealthConnectionView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// Where the user connects Apple Health, or decides not to.
///
/// Every outcome leads somewhere. Nothing here is a dead end, and nothing here says a word
/// about permission being denied — HealthKit cannot tell an app that.
@MainActor
struct HealthConnectionView: View {
    @Bindable var vm: OnboardingViewModel
    @State private var judge = JudgeReaction()

    var body: some View {
        Form {
            // The judge at the head of the form, on the form's own background: a data-entry screen
            // keeps the system grouped background rather than a stage (D148).
            Section {
                JudgeHeroView(artwork: .judgeWelcome, height: StageArtworkSize.formJudge, reaction: judge)
                    .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)

            Section {
                Text("Foodge reads what Health already recorded today and works out what you have left to spend on dinner.")
                // `.secondary` measures ~3.4:1 against a Form row's white/elevated background in
                // standard-contrast light appearance — below the 4.5:1 WCAG 1.4.3 needs.
                // `AppBurgundyMuted` is the brand's dedicated secondary-text color, already
                // tuned to ≥4.5:1 in every appearance/contrast combination.
                Text("It reads on this iPhone and writes nothing back. Your figures never leave the device.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)
            }

            Section {
                Button("Connect Apple Health") {
                    Task { await vm.connectHealth() }
                }
                .disabled(vm.healthState == .requesting)

                if vm.healthState == .requesting {
                    ProgressView("Waiting for Health")
                }
            } footer: {
                Text("Apple asks for the permission, not Foodge. You choose what to share in its own sheet.")
                    // Footers are drawn in `.secondary`, about 3.3:1 on the light grouped background;
                    // `appBurgundyMuted` is measured there (D134, D145).
                    .foregroundStyle(.appBurgundyMuted)
            }

            if let missing = vm.healthState.missingKinds {
                Section {
                    if missing.isEmpty {
                        Text("Everything Foodge asks for is there today.")
                    } else {
                        ForEach(HealthKind.allCases.filter(missing.contains), id: \.self) { kind in
                            LabeledContent(kind.displayName) {
                                // `.secondary` measures ~3.4:1 against the row background in
                                // standard-contrast light — below WCAG 1.4.3's 4.5:1.
                                // `appBurgundyMuted` is ≥4.5:1 (D134).
                                Text("No readable data")
                                    .foregroundStyle(.appBurgundyMuted)
                            }
                        }
                        Text("No readable data is not the same as a refusal — Apple Health cannot tell Foodge which it was. Anything missing is either estimated from what you tell it, or left out.")
                            .font(.footnote)
                            .foregroundStyle(.appBurgundyMuted)
                    }
                } header: {
                    Text("What Health could read")
                        // Headers are drawn in `.secondary` too (D134, D145).
                        .foregroundStyle(.appBurgundyMuted)
                }
            }

            HealthUnavailableSection(state: vm.healthState) {
                Task { await vm.connectHealth() }
            }

            Section {
                switch vm.healthState {
                case .idle, .requesting:
                    Button("Continue without Health") {
                        vm.skipHealth()
                    }
                case .connected, .noReadableData, .previouslyAnswered, .unavailable, .requestFailed:
                    NavigationLink("Continue", value: OnboardingRoute.bodyBasics)
                }
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension OnboardingViewModel.HealthState {
    /// The kinds that came back empty in a connected state, or `nil` for every other state.
    ///
    /// Lets the screen read one value instead of switching over six cases to find it. An **empty
    /// set** and `nil` are deliberately different: empty means "connected, nothing missing", `nil`
    /// means the read has not happened.
    var missingKinds: Set<HealthKind>? {
        guard case let .connected(missing) = self else { return nil }
        return missing
    }
}

#Preview("Not connected yet", traits: .sampleData) {
    NavigationStack {
        HealthConnectionView(vm: PreviewDependencies.all.makeOnboardingViewModel())
    }
}

#Preview("Connected", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.connected(SyntheticScenarios.modestAllowance).makeOnboardingViewModel()

    NavigationStack {
        HealthConnectionView(vm: vm)
    }
    .task { await vm.connectHealth() }
}

#Preview("Some kinds missing", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.connected(SyntheticScenarios.estimatedResting)
        .makeOnboardingViewModel()

    NavigationStack {
        HealthConnectionView(vm: vm)
    }
    .task { await vm.connectHealth() }
}

#Preview("No readable data", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.connected(SyntheticScenarios.noHealthData)
        .makeOnboardingViewModel()

    NavigationStack {
        HealthConnectionView(vm: vm)
    }
    .task { await vm.connectHealth() }
}

#Preview("Health unavailable", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.healthUnavailable().makeOnboardingViewModel()

    NavigationStack {
        HealthConnectionView(vm: vm)
    }
    .task { await vm.connectHealth() }
}
