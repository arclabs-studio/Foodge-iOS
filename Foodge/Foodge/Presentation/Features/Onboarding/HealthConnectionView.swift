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

    var body: some View {
        Form {
            Section {
                Text("Foodge compares today with the fortnight Health already recorded.")
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
            }

            if let summary = vm.healthState.connectedSummary {
                RecordedPatternSection(summary: summary) {
                    vm.markUnrepresentative(false)
                }

                if case .success = summary.pattern {
                    Section {
                        Button("These days aren’t typical for me") {
                            vm.markUnrepresentative(true)
                        }
                    }
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
                case .connected, .noReadableData, .unavailable, .requestFailed:
                    NavigationLink("Continue", value: OnboardingRoute.preferences)
                }
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension OnboardingViewModel.HealthState {
    /// The summary of a connected state, or `nil` for every other state.
    ///
    /// Lets the screen read one value instead of switching over six cases to find it.
    var connectedSummary: RecordedPatternSummary? {
        guard case let .connected(summary) = self else { return nil }
        return summary
    }
}

#Preview("Not connected yet") {
    NavigationStack {
        HealthConnectionView(vm: PreviewDependencies.all.makeOnboardingViewModel())
    }
}

#Preview("Connected") {
    @Previewable @State var vm = PreviewDependencies.connected(SyntheticScenarios.typicalDay).makeOnboardingViewModel()

    NavigationStack {
        HealthConnectionView(vm: vm)
    }
    .task { await vm.connectHealth() }
}

#Preview("Not enough recorded days") {
    @Previewable @State var vm = PreviewDependencies.connected(SyntheticScenarios.stepsFallback)
        .makeOnboardingViewModel()

    NavigationStack {
        HealthConnectionView(vm: vm)
    }
    .task {
        await vm.connectHealth()
        vm.markUnrepresentative(true)
    }
}

#Preview("No readable data") {
    @Previewable @State var vm = PreviewDependencies.connected(SyntheticScenarios.noHealthData)
        .makeOnboardingViewModel()

    NavigationStack {
        HealthConnectionView(vm: vm)
    }
    .task { await vm.connectHealth() }
}

#Preview("Health unavailable") {
    @Previewable @State var vm = PreviewDependencies.healthUnavailable().makeOnboardingViewModel()

    NavigationStack {
        HealthConnectionView(vm: vm)
    }
    .task { await vm.connectHealth() }
}
