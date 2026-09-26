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
                        // `.secondary` measures ~3.4:1 against the row background in
                        // standard-contrast light — below WCAG 1.4.3's 4.5:1.
                        // `appBurgundyMuted` is ≥4.5:1 (D134).
                        .foregroundStyle(.appBurgundyMuted)
                }
            }

            CategoryHeaderSection(category: revision.decision.category, isProvisional: revision.decision.isProvisional)

            dishSection(for: revision.dishOutcome)

            // The header carries the case's date because the reason codes are stored, not
            // recomputed: they are phrased for the day they were written ("Today's activity came
            // in…"), so on a past case the date is what makes "today" read as the day being
            // quoted rather than as now. `VerdictView` shows the same codes undated, where today
            // really is today.
            Section {
                ForEach(revision.decision.reasonCodes, id: \.self) { reason in
                    Text(reason.displayText)
                }
            } header: {
                HStack {
                    Text("Why")
                    Spacer()
                    Text(revision.createdAt, format: .dateTime.year().month().day())
                }
                .accessibilityElement(children: .combine)
            } footer: {
                // Same placement as `VerdictView`'s copy of this sentence: it qualifies the
                // reasons above it, so it is a footer rather than one more row among them
                // (`arc-audit-hig`, WU-EB). A footer is already footnote-sized, so only the
                // color is set — `.secondary` measures ~3.4:1 in standard-contrast light,
                // below WCAG 1.4.3's 4.5:1, while `appBurgundyMuted` is ≥4.5:1 (D134).
                Text("These are prototype product heuristics, not nutritional advice.")
                    .foregroundStyle(.appBurgundyMuted)
            }

            EvidenceSectionsView(evidence: revision.evidence, basis: revision.decision.basis)

            // `narrationText` is nil for every case recorded before narration existed, and stays
            // nil whenever the model did not produce a validated line. The reviewed template
            // covers all of that. The one case it does not cover is a no-match, where the section
            // renders nothing at all rather than promising a candidate that was never found
            // (D106) — so History shows a flourish for every case except those.
            NarrationSection(
                text: revision.narrationText,
                category: revision.decision.category,
                dishOutcome: revision.dishOutcome
            )

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
                    .foregroundStyle(.appBurgundyMuted)
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
                            basis: .energyBalance(SampleDecisions.moderateAllowance),
                            reasonCodes: [.moderateAllowance],
                            isProvisional: false,
                            ruleVersion: CheatMealAllowanceRule.ruleVersion
                        ),
                        evidence: SyntheticScenarios.modestAllowance.snapshot,
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
                            basis: .energyBalance(SampleDecisions.moderateAllowance),
                            reasonCodes: [.moderateAllowance],
                            isProvisional: false,
                            ruleVersion: CheatMealAllowanceRule.ruleVersion
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
                            basis: .energyBalance(SampleDecisions.slimAllowance),
                            reasonCodes: [.slimAllowance],
                            isProvisional: false,
                            ruleVersion: CheatMealAllowanceRule.ruleVersion
                        ),
                        evidence: SyntheticScenarios.slimAllowance.snapshot,
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
