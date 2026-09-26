//
//  VerdictView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Accessibility
import SwiftUI

/// Tonight's dinner, the category it landed in, and why.
@MainActor
struct VerdictView: View {
    @Bindable var vm: TodayViewModel
    @State private var showingAppeal = false
    @State private var showingAlternative = false

    private var saveFailureMessage: LocalizedStringResource {
        "Foodge couldn’t save this verdict. Nothing has been lost — try again."
    }

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
        // Identity is the revision, so SwiftUI restarts narration on a new verdict and cancels it
        // on disappear — navigation away is handled by the framework, with no stored `Task` here.
        .task(id: vm.currentRevision?.id) {
            await vm.narrateIfNeeded()
        }
        .sheet(isPresented: $showingAppeal) {
            AppealSheetView(vm: vm)
        }
        // The first failure pushes `.verdict` onto the path, so VoiceOver announces a screen
        // change — but that reads the navigation title, not what went wrong, and a failed *retry*
        // re-enters `.saveFailed` with the row already on screen and no push at all (WCAG 4.1.3).
        // `logLabel` is the change key because `Stage` carries a draft and an error and is
        // deliberately not `Equatable`; the retry passes through `.evaluating`, so a second
        // failure is a real change of label and does announce.
        .onChange(of: vm.stage.logLabel) { _, _ in
            guard case .saveFailed = vm.stage else { return }
            AccessibilityNotification.Announcement(String(localized: saveFailureMessage)).post()
        }
    }

    /// Renders from ``TodayViewModel/Display`` rather than `SavedRevision` directly: a failed
    /// save has no `SavedRevision` yet — no id, no sequence — but the computed decision must stay
    /// visible with a retry regardless, never silently dropped to a spinner.
    private func content(for display: TodayViewModel.Display) -> some View {
        Form {
            CategoryHeaderSection(category: display.decision.category, isProvisional: display.decision.isProvisional)

            dishSection(for: display.dishOutcome)

            Section("Why") {
                ForEach(display.decision.reasonCodes, id: \.self) { reason in
                    Text(reason.displayText)
                }
                // `.secondary` measures ~3.4:1 against the row background in standard-contrast
                // light appearance — below the 4.5:1 WCAG 1.4.3 needs, same as the `.saveFailed`
                // text below. `appBurgundyMuted` is the brand's dedicated secondary-text color,
                // tuned to ≥4.5:1 everywhere.
                Text("These are prototype product heuristics, not nutritional advice.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)
            }

            if vm.currentRevision != nil {
                // Gated on a saved revision for the same reason the Appeal section below is: a
                // decorative flourish over a verdict that has not actually been recorded reads as
                // if everything went fine. `arc-audit-hig` caught this — `.saveFailed` still has a
                // `display`, so an ungated section showed the template over an unsaved verdict.
                NarrationSection(
                    text: vm.narrationStage.text,
                    category: display.decision.category,
                    dishOutcome: display.dishOutcome
                )
            }

            if case .saveFailed = vm.stage {
                Section {
                    // `.secondary` measures ~3.4:1 against the row background in standard-contrast
                    // light appearance — below the 4.5:1 WCAG 1.4.3 needs. `AppBurgundyMuted` is
                    // the brand's dedicated secondary-text color, tuned to ≥4.5:1 everywhere.
                    Text(saveFailureMessage)
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
            let displayedVariantID = showingAlternative ? (alternativeVariantID ?? variantID) : variantID
            let displayedFamily = showingAlternative ? (alternativeFamily ?? family) : family
            Section {
                DishSummaryRow(variantID: displayedVariantID, family: displayedFamily)
                Button("See alternative") {
                    showingAlternative.toggle()
                }
                .disabled(alternativeVariantID == nil)
            }
        case .noMatch:
            Section {
                Text("No catalogue dish matched your constraints tonight.")
                // Same WCAG 1.4.3 fix as the "Why" section's disclaimer above: `.secondary`
                // falls short of 4.5:1 at footnote size here.
                Text("Nothing was relaxed to force a match — you can adjust your exclusions in Preferences.")
                    .font(.footnote)
                    .foregroundStyle(.appBurgundyMuted)
            }
        }
    }
}

#Preview("Verdict", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.reopeningSavedCase(
        decision: VerdictDecision(
            category: .balanced,
            basis: .energyBalance(SampleDecisions.moderateAllowance),
            reasonCodes: [.moderateAllowance],
            isProvisional: false,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
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
