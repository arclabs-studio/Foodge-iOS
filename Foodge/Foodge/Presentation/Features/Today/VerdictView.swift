//
//  VerdictView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// Tonight's dinner, the category it landed in, and why.
@MainActor
struct VerdictView: View {
    @Bindable var vm: TodayViewModel
    @State private var showingAppeal = false
    @State private var showingAlternative = false

    var body: some View {
        Group {
            if let display = vm.currentDisplay {
                content(for: display)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Tonight’s verdict")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAppeal) {
            AppealSheetView(vm: vm)
        }
    }

    /// Renders from ``TodayViewModel/Display`` rather than `SavedRevision` directly: a failed
    /// save has no `SavedRevision` yet — no id, no sequence — but the computed decision must stay
    /// visible with a retry regardless, never silently dropped to a spinner.
    private func content(for display: TodayViewModel.Display) -> some View {
        Form {
            Section {
                JudgeBadgeView()
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(display.decision.category.displayName)
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .center)
                if display.decision.isProvisional {
                    Text("Provisional — there wasn’t enough to go on yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listRowBackground(Color.clear)

            dishSection(for: display.dishOutcome)

            Section("Why") {
                ForEach(display.decision.reasonCodes, id: \.self) { reason in
                    Text(reason.displayText)
                }
                Text("These are prototype product heuristics, not nutritional advice.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if case .saveFailed = vm.stage {
                Section {
                    // `.secondary` measures ~3.4:1 against the row background in standard-contrast
                    // light appearance — below the 4.5:1 WCAG 1.4.3 needs. `AppBurgundyMuted` is
                    // the brand's dedicated secondary-text color, tuned to ≥4.5:1 everywhere.
                    Text("Foodge couldn’t save this verdict. Nothing has been lost — try again.")
                        .foregroundStyle(.appBurgundyMuted)
                    Button("Retry save") {
                        Task { await vm.retrySave() }
                    }
                }
            }

            if vm.currentRevision != nil {
                Section {
                    Button("Appeal") { showingAppeal = true }
                    NavigationLink(value: TodayRoute.evidenceDetails) {
                        Text("Evidence details")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dishSection(for dishOutcome: PersistedDishOutcome) -> some View {
        switch dishOutcome {
        case let .selected(variantID, family, alternativeVariantID, alternativeFamily):
            Section {
                HStack(spacing: 16) {
                    DishArtPlaceholderView(family: showingAlternative ? (alternativeFamily ?? family) : family)
                    VStack(alignment: .leading) {
                        Text(DishCatalogue.displayName(
                            forVariantID: showingAlternative ? alternativeVariantID ?? variantID : variantID
                        ))
                        .font(.headline)
                        Text((showingAlternative ? alternativeFamily ?? family : family).displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                Button("See alternative") {
                    showingAlternative.toggle()
                }
                .disabled(alternativeVariantID == nil)
            }
        case .noMatch:
            Section {
                Text("No catalogue dish matched your constraints tonight.")
                Text("Nothing was relaxed to force a match — you can adjust your exclusions in Preferences.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Verdict", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.reopeningSavedCase(
        decision: VerdictDecision(
            category: .balanced,
            basis: .recorded(
                ratio: 1.02,
                baseline: ActivityBaseline(
                    metric: .activeEnergy,
                    median: 400,
                    observationCount: 14,
                    window: SyntheticScenarios.windowSinceMidnight(endingAt: SyntheticScenarios.evaluationDate)
                )
            ),
            reasonCodes: [.withinRecordedPattern],
            isProvisional: false,
            ruleVersion: DinnerCategoryRule.ruleVersion
        )
    )
    .makeTodayViewModel()

    NavigationStack {
        VerdictView(vm: vm)
    }
    .task { await vm.onAppear() }
}

#Preview("Save failed", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.savingFails().makeTodayViewModel()

    NavigationStack {
        VerdictView(vm: vm)
    }
    .task { await vm.requestVerdict() }
}
