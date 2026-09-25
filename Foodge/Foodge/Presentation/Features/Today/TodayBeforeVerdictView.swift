//
//  TodayBeforeVerdictView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Accessibility
import SwiftUI

/// Today, before a verdict has been asked for: optional context, the check-ins the category rule
/// needs, and the one button that starts an evaluation.
@MainActor
struct TodayBeforeVerdictView: View {
    @Bindable var vm: TodayViewModel

    private var evidenceFailureMessage: LocalizedStringResource {
        "Foodge couldn’t finish reading today’s evidence."
    }

    private var isEvaluating: Bool {
        if case .evaluating = vm.stage {
            true
        } else {
            false
        }
    }

    var body: some View {
        ZStack {
            Form {
                Section {
                    JudgeBadgeView(artwork: .judgeVerdict)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Tell the judge about tonight, or just ask for a verdict.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowBackground(Color.clear)

                Section {
                    Picker("Time for dinner", selection: $vm.dinnerTime) {
                        Text("No preference").tag(DinnerTime?.none)
                        ForEach(DinnerTime.allCases, id: \.self) { time in
                            Text(time.displayName).tag(DinnerTime?.some(time))
                        }
                    }
                    .pickerStyle(.navigationLink)
                    Picker("Energy", selection: $vm.energyLevel) {
                        Text("No preference").tag(EnergyLevel?.none)
                        ForEach(EnergyLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(EnergyLevel?.some(level))
                        }
                    }
                    .pickerStyle(.navigationLink)
                    Picker("Craving", selection: $vm.craving) {
                        Text("No preference").tag(DishFamily?.none)
                        ForEach(DishFamily.allCases, id: \.self) { family in
                            Text(family.displayName).tag(DishFamily?.some(family))
                        }
                    }
                    .pickerStyle(.navigationLink)
                    TextField("Add a note", text: $vm.noteText, axis: .vertical)
                        .accessibilityHint(
                            "Optional, up to \(Note.maximumLength) characters. Colours the judge’s humour only."
                        )
                } header: {
                    Text("Tonight")
                } footer: {
                    Text("Optional. This never changes the category — only the pick inside it.")
                }

                switch vm.stage {
                case .needsTrackingConfirmation:
                    TrackingConfirmationSection { reflectsToday in
                        Task { await vm.confirmTrackingReflectsToday(reflectsToday) }
                    }
                case .needsSelfReport:
                    SelfReportCheckInSection { report in
                        Task { await vm.submitSelfReport(report) }
                    }
                case .evidenceUnavailable:
                    Section {
                        Text(evidenceFailureMessage)
                        Button("Try again") {
                            Task { await vm.requestVerdict() }
                        }
                    }
                case .gathering, .evaluating, .verdict, .saveFailed:
                    EmptyView()
                }

                Section {
                    Button("Give me a verdict") {
                        Task { await vm.requestVerdict() }
                    }
                    .disabled(isEvaluating)
                }
            }
            .disabled(isEvaluating)
            .accessibilityHidden(isEvaluating)

            if isEvaluating {
                CourtLoadingView(
                    message: LocalizedStringResource(
                        "The judge is weighing tonight’s evidence…",
                        comment: "Verdict preparation loading message"
                    ),
                    artwork: .judgeVerdict
                )
            }
        }
        .navigationTitle("Today")
        .task { await vm.onAppear() }
        // The row replaces the check-in section in place, with no navigation, so VoiceOver has
        // no reason to land on it (WCAG 4.1.3). `logLabel` is the change key because `Stage`
        // carries a draft and an error and is deliberately not `Equatable`; "Try again" passes
        // through `.evaluating`, so a second failure announces too.
        .onChange(of: vm.stage.logLabel) { _, _ in
            guard case .evidenceUnavailable = vm.stage else { return }
            AccessibilityNotification.Announcement(String(localized: evidenceFailureMessage)).post()
        }
    }
}

#Preview("Gathering", traits: .sampleData) {
    NavigationStack {
        TodayBeforeVerdictView(vm: PreviewDependencies.all.makeTodayViewModel())
    }
}

#Preview("Needs tracking confirmation", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.connected(SyntheticScenarios.quietDayUnconfirmed)
        .makeTodayViewModel()

    NavigationStack {
        TodayBeforeVerdictView(vm: vm)
    }
    .task { await vm.requestVerdict() }
}
