//
//  EvidenceSectionsView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import SwiftUI

/// What Foodge actually read, and the allowance it added up to.
///
/// Shared between `EvidenceDetailsView` (today's flow) and `CaseDetailView` (History) so the two
/// screens stay provably identical in how they present Health evidence — one place formats it,
/// rather than two copies that could quietly drift apart.
@MainActor
struct EvidenceSectionsView: View {
    let evidence: EvidenceSnapshot
    let basis: CategoryBasis

    private var today: HealthAggregates {
        evidence.today
    }

    /// Energy, formatted exactly as `AllowanceFigureRow` formats it — the same unit on the same
    /// screen has one presentation, grouped and localized by the formatter.
    ///
    /// The interpolated `"\(Int(kilocalories)) kcal"` these rows used before put a unit outside the
    /// String Catalog and printed `1200` next to the allowance's `1,200 Cal` (D142).
    private static func energyText(_ aggregate: EnergyAggregate) -> String {
        Measurement(value: aggregate.kilocalories, unit: UnitEnergy.kilocalories)
            .formatted(.measurement(width: .abbreviated, usage: .food))
    }

    /// A step count, grouped by the locale's own separator rather than printed as raw digits.
    private static func stepText(_ aggregate: StepAggregate) -> String {
        aggregate.count.formatted(.number.precision(.fractionLength(0)))
    }

    var body: some View {
        Group {
            Section("Sources") {
                ProvenanceRow(
                    title: HealthKind.activeEnergy.displayName,
                    valueText: today.activeEnergy.map(Self.energyText),
                    readAt: today.activeEnergy?.provenance.readAt
                )
                ProvenanceRow(
                    title: HealthKind.restingEnergy.displayName,
                    valueText: today.restingEnergy.map(Self.energyText),
                    readAt: today.restingEnergy?.provenance.readAt
                )
                ProvenanceRow(
                    title: HealthKind.steps.displayName,
                    valueText: today.steps.map(Self.stepText),
                    readAt: today.steps?.provenance.readAt
                )
                ProvenanceRow(
                    title: HealthKind.dietaryEnergy.displayName,
                    valueText: today.dietaryEnergy.map(Self.energyText),
                    readAt: today.dietaryEnergy?.provenance.readAt
                )
            }

            Section {
                AllowanceBreakdownRow(basis: basis)
            } header: {
                Text("Tonight’s allowance")
            } footer: {
                AllowanceDisclaimerFooter(basis: basis)
            }

            Section("Sleep") {
                if let sleep = today.sleep {
                    LabeledContent(
                        "Asleep",
                        value: sleep.asleepDuration.formatted(.units(allowed: [.hours, .minutes], width: .narrow))
                    )
                    LabeledContent("Intervals", value: sleep.intervalCount, format: .number)
                } else {
                    // `.secondary` measures ~3.4:1 against the row background in
                    // standard-contrast light — below WCAG 1.4.3's 4.5:1.
                    // `appBurgundyMuted` is ≥4.5:1 (D134).
                    Text("No readable data")
                        .foregroundStyle(.appBurgundyMuted)
                }
            }
        }
    }
}

#Preview(traits: .sampleData) {
    Form {
        EvidenceSectionsView(
            evidence: SyntheticScenarios.modestAllowance.snapshot,
            basis: .energyBalance(SampleDecisions.moderateAllowance)
        )
    }
}
