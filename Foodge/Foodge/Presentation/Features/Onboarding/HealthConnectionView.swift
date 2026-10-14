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
///
/// The screen's one primary action is the stage's (D150): *Connect Apple Health* until Health has
/// answered, then *Continue* — pinned to the bottom edge, or the form's last section at
/// accessibility sizes. *Continue without Health* stays a row: it is the way out, not the way on.
@MainActor
struct HealthConnectionView: View {
    @Bindable var vm: OnboardingViewModel
    @State private var judge = JudgeReaction()
    /// Where VoiceOver goes once Health answers: the button the user just activated is replaced by
    /// *Continue*, a different view, and focus on a view that left the screen is lost (WCAG 2.4.3).
    @AccessibilityFocusState private var isContinueFocused: Bool

    var body: some View {
        Form {
            FormJudgeHeroSection(reaction: judge)

            Section {
                Text("Foodge reads what Health already recorded today and works out what you have left to spend on dinner.")
                // `.secondary` measures ~3.4:1 against a Form row's white/elevated background in
                // standard-contrast light appearance — below the 4.5:1 WCAG 1.4.3 needs.
                // `AppBurgundyMuted` is the brand's dedicated secondary-text color, already
                // tuned to ≥4.5:1 in every appearance/contrast combination.
                Text("It reads on this iPhone and writes nothing back. Your figures never leave the device.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)
            } footer: {
                // Says what the pinned *Connect Apple Health* will do, so it closes the section that
                // explains why Foodge asks.
                Text("Apple asks for the permission, not Foodge. You choose what to share in its own sheet.")
                    .formCaption()
            }

            if vm.healthState == .requesting {
                Section {
                    ProgressView("Waiting for Health")
                }
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
                        .formCaption()
                }
            }

            HealthUnavailableSection(state: vm.healthState) {
                Task { await vm.connectHealth() }
            }

            if vm.healthState.awaitsConnection {
                Section {
                    Button("Continue without Health") {
                        vm.skipHealth()
                    }
                }
            }

            InlinePrimaryActionSection {
                primaryAction
            }
        }
        .pinnedPrimaryAction {
            primaryAction
        }
        .onChange(of: vm.healthState.awaitsConnection) { _, awaits in
            guard !awaits else { return }
            isContinueFocused = true
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The same action in both places it can sit — pinned, or inline at accessibility sizes.
    @ViewBuilder
    private var primaryAction: some View {
        if vm.healthState.awaitsConnection {
            Button("Connect Apple Health") {
                Task { await vm.connectHealth() }
            }
            .disabled(vm.healthState == .requesting)
            .primaryAction()
        } else {
            // A button, not a `NavigationLink`: see `OnboardingViewModel.continueToBodyBasics()`.
            Button("Continue") {
                vm.continueToBodyBasics()
            }
            .primaryAction()
            .accessibilityFocused($isContinueFocused)
        }
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
