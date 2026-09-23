//
//  CaseDetailView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import SwiftUI

/// One day, exactly as Foodge ruled it: the evidence, rule version, dish and appeals that day
/// actually used — never recomputed against today's rules or catalogue.
///
/// Renders `savedCase.latestRevision` only. The data model supports multiple revisions per day,
/// but no UI trigger for creating a second one exists yet, so a multi-revision layout would be
/// speculative. If `latestRevision` were ever `nil`, the `Group` below renders nothing —
/// documented-unreachable, per the same reasoning as `VerdictRevision.dishOutcome`'s fallback: a
/// `DailyCase` is never inserted without its first revision.
@MainActor
struct CaseDetailView: View {
    let savedCase: SavedCase

    var body: some View {
        Group {
            if let revision = savedCase.latestRevision {
                content(for: revision)
            }
        }
        .navigationTitle("Case detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(for revision: SavedRevision) -> some View {
        Form {
            if revision.evidence.isSynthetic {
                Section {
                    Text("Demonstration data")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            CategoryHeaderSection(category: revision.decision.category, isProvisional: revision.decision.isProvisional)

            dishSection(for: revision.dishOutcome)

            Section("Why") {
                ForEach(revision.decision.reasonCodes, id: \.self) { reason in
                    Text(reason.displayText)
                }
                Text("These are prototype product heuristics, not nutritional advice.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            EvidenceSectionsView(evidence: revision.evidence, basis: revision.decision.basis)

            // Unconditional: `narrationText` is nil for every case recorded before narration
            // existed, and stays nil whenever the model did not produce a validated line. The
            // reviewed template covers all of it, so History never shows a case with no flourish.
            NarrationSection(text: revision.narrationText, category: revision.decision.category)

            ForEach(revision.appeals) { appeal in
                AppealRecordedSection(choice: appeal.choice)
            }

            Section("Recorded") {
                LabeledContent("Rule version", value: revision.decision.ruleVersion)
                LabeledContent("Catalogue version", value: revision.catalogueVersion)
            }
        }
    }

    @ViewBuilder
    private func dishSection(for dishOutcome: PersistedDishOutcome) -> some View {
        switch dishOutcome {
        case let .selected(variantID, family, _, _):
            Section {
                DishSummaryRow(variantID: variantID, family: family)
            }
        case .noMatch:
            Section {
                Text("No catalogue dish matched your constraints that night.")
                Text("Nothing was relaxed to force a match.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Dish match", traits: .sampleData) {
    NavigationStack {
        CaseDetailView(
            savedCase: SavedCase(
                localDayKey: "2026-09-18",
                revisions: [
                    SavedRevision(
                        id: UUID(),
                        sequence: 0,
                        createdAt: SyntheticScenarios.evaluationDate,
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
                        ),
                        evidence: SyntheticScenarios.typicalDay.snapshot,
                        catalogueVersion: DishCatalogue.version,
                        dishOutcome: .selected(
                            variantID: "dish.pasta.pesto",
                            family: .pasta,
                            alternativeVariantID: nil,
                            alternativeFamily: nil
                        ),
                        narrationText: nil,
                        appeals: []
                    ),
                ]
            )
        )
    }
}

#Preview("No match", traits: .sampleData) {
    NavigationStack {
        CaseDetailView(
            savedCase: SavedCase(
                localDayKey: "2026-09-17",
                revisions: [
                    SavedRevision(
                        id: UUID(),
                        sequence: 0,
                        createdAt: SyntheticScenarios.evaluationDate,
                        decision: VerdictDecision(
                            category: .balanced,
                            basis: .recorded(
                                ratio: 1.0,
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
                        ),
                        evidence: SyntheticScenarios.noCompatibleDish.snapshot,
                        catalogueVersion: DishCatalogue.version,
                        dishOutcome: .noMatch(blockingIngredientIDs: [Ingredient.rice.id, Ingredient.pasta.id]),
                        narrationText: nil,
                        appeals: []
                    ),
                ]
            )
        )
    }
}

#Preview("Appealed", traits: .sampleData) {
    NavigationStack {
        CaseDetailView(
            savedCase: SavedCase(
                localDayKey: "2026-09-16",
                revisions: [
                    SavedRevision(
                        id: UUID(),
                        sequence: 0,
                        createdAt: SyntheticScenarios.evaluationDate,
                        decision: VerdictDecision(
                            category: .light,
                            basis: .recorded(
                                ratio: 0.45,
                                baseline: ActivityBaseline(
                                    metric: .activeEnergy,
                                    median: 400,
                                    observationCount: 14,
                                    window: SyntheticScenarios.windowSinceMidnight(endingAt: SyntheticScenarios.evaluationDate)
                                )
                            ),
                            reasonCodes: [.belowRecordedPattern],
                            isProvisional: false,
                            ruleVersion: DinnerCategoryRule.ruleVersion
                        ),
                        evidence: SyntheticScenarios.restDay.snapshot,
                        catalogueVersion: DishCatalogue.version,
                        dishOutcome: .selected(
                            variantID: "dish.lentilSalad.tomato",
                            family: .lentilSalad,
                            alternativeVariantID: nil,
                            alternativeFamily: nil
                        ),
                        narrationText: nil,
                        appeals: [
                            SavedAppeal(
                                id: UUID(),
                                createdAt: SyntheticScenarios.evaluationDate,
                                choice: .catalogue(variantID: "dish.tacos.beef", family: .tacos)
                            ),
                        ]
                    ),
                ]
            )
        )
    }
}
