//
//  TodayBeforeVerdictView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// Today, before a verdict has been asked for: optional context, the check-ins the category rule
/// needs, and the one button that starts an evaluation.
@MainActor
struct TodayBeforeVerdictView: View {
    @Bindable var vm: TodayViewModel

    private var isEvaluating: Bool {
        if case .evaluating = vm.stage {
            true
        } else {
            false
        }
    }

    var body: some View {
        Form {
            Section {
                JudgeBadgeView()
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
                    Text("Foodge couldn’t finish reading today’s evidence.")
                    Button("Try again") {
                        Task { await vm.requestVerdict() }
                    }
                }
            case .gathering, .evaluating, .verdict, .saveFailed:
                EmptyView()
            }

            Section {
                Button {
                    Task { await vm.requestVerdict() }
                } label: {
                    if isEvaluating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Give me a verdict")
                    }
                }
                .disabled(isEvaluating)
            }
        }
        .navigationTitle("Today")
        .task { await vm.onAppear() }
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
