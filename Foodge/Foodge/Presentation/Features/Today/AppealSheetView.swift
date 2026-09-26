//
//  AppealSheetView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 22/09/2026.
//

import SwiftUI

/// Negotiates an appeal as a modal sheet, extending `VerdictView`'s existing sheet in place
/// rather than a pushed `NavigationStack` screen (minimum change over `DESIGN.md`'s screen-table
/// framing, consistent with D61's precedent). Accepting an appeal only adds a fact to the
/// existing revision — it never mutates `vm.stage`, so the verdict behind this sheet stays
/// exactly as it was for as long as the sheet is open.
@MainActor
struct AppealSheetView: View {
    @Bindable var vm: TodayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var freeText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    JudgeBadgeView(artwork: .judgeAppeal)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowBackground(Color.clear)

                switch vm.appealStage {
                case .choosingCraving:
                    AppealCravingSection(
                        choose: { family in Task { await vm.proposeCraving(family) } },
                        chooseFreeText: { vm.beginFreeText() }
                    )
                case let .compatibleFound(family, entry):
                    AppealCompatibleSection(craving: family, entry: entry) {
                        Task { await vm.acceptCompatible(entry: entry) }
                    }
                case let .noMatchFound(family, blockingIngredientIDs):
                    AppealNoMatchSection(family: family, blockingIngredientIDs: blockingIngredientIDs) {
                        vm.beginAppeal()
                    }
                case .enteringFreeText:
                    AppealFreeTextSection(text: $freeText, canSubmit: vm.canSubmitFreeText(freeText)) {
                        Task { await vm.submitFreeText(freeText) }
                    }
                case let .recorded(choice):
                    AppealRecordedSection(choice: choice)
                case .appealFailed:
                    AppealFailedSection { Task { await vm.retryAppeal() } }
                }
            }
            .navigationTitle("Appeal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(role: .close) { dismiss() }
            }
        }
        // The fresh appeal is begun by whoever *presents* this sheet, not here (D136). The reset
        // used to run from this view's `.onAppear`, with a comment claiming it was ordered ahead
        // of any caller's `.task`. It is not: five of the six previews below drove themselves to
        // a later stage and every one of them rendered the craving list, because the reset landed
        // last and wiped it. Resetting at the button is deterministic — state first, then the
        // sheet — and it is what lets a preview reach the stage it is named after.
    }
}

#Preview("Choosing craving", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.reopeningSavedCase(
        decision: VerdictDecision(
            category: .light,
            basis: .energyBalance(SampleDecisions.slimAllowance),
            reasonCodes: [.slimAllowance],
            isProvisional: false,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    )
    .makeTodayViewModel()

    AppealSheetView(vm: vm)
        .task { await vm.onAppear() }
}

#Preview("Compatible variant found", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.reopeningSavedCase(
        preferencesDraft: PreferencesDraft(
            dietProfile: .vegetarian,
            excludedIngredientIDs: [Ingredient.halloumi.id]
        ),
        decision: VerdictDecision(
            category: .light,
            basis: .provisional,
            reasonCodes: [.checkInSkipped],
            isProvisional: true,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    )
    .makeTodayViewModel()

    AppealSheetView(vm: vm)
        .task {
            await vm.onAppear()
            await vm.proposeCraving(.burgers)
        }
}

#Preview("Honest no-match", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.reopeningSavedCase(
        preferencesDraft: PreferencesDraft(
            dietProfile: .vegan,
            excludedIngredientIDs: [Ingredient.blackBeans.id]
        ),
        decision: VerdictDecision(
            category: .light,
            basis: .provisional,
            reasonCodes: [.checkInSkipped],
            isProvisional: true,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    )
    .makeTodayViewModel()

    AppealSheetView(vm: vm)
        .task {
            await vm.onAppear()
            await vm.proposeCraving(.tacos)
        }
}

#Preview("Free text", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.reopeningSavedCase(
        decision: VerdictDecision(
            category: .balanced,
            basis: .provisional,
            reasonCodes: [.checkInSkipped],
            isProvisional: true,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    )
    .makeTodayViewModel()

    AppealSheetView(vm: vm)
        .task {
            await vm.onAppear()
            vm.beginFreeText()
        }
}

#Preview("Recorded", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.reopeningSavedCase(
        decision: VerdictDecision(
            category: .balanced,
            basis: .provisional,
            reasonCodes: [.checkInSkipped],
            isProvisional: true,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    )
    .makeTodayViewModel()

    AppealSheetView(vm: vm)
        .task {
            await vm.onAppear()
            await vm.submitFreeText("Grandma’s stew")
        }
}

#Preview("Save failed, with retry", traits: .sampleData) {
    @Previewable @State var vm = PreviewDependencies.reopeningSavedCase(
        appealFailure: .saveFailed,
        decision: VerdictDecision(
            category: .balanced,
            basis: .provisional,
            reasonCodes: [.checkInSkipped],
            isProvisional: true,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    )
    .makeTodayViewModel()

    AppealSheetView(vm: vm)
        .task {
            await vm.onAppear()
            await vm.submitFreeText("Grandma’s stew")
        }
}
