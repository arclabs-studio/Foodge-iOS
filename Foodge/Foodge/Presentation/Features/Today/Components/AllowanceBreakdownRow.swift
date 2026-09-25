//
//  AllowanceBreakdownRow.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import SwiftUI

/// What the verdict was actually decided from: today's energy allowance, a self-report, or neither.
///
/// Reads straight off `VerdictDecision.basis` rather than recomputing anything — the basis carries
/// the exact figures the decision used, so this can never drift from them. **Every figure carries
/// its own provenance**: an estimated resting figure and a recorded one are both shown, and shown
/// differently, because the difference is the user's to judge.
@MainActor
struct AllowanceBreakdownRow: View {
    let basis: CategoryBasis

    var body: some View {
        switch basis {
        case let .energyBalance(allowance):
            AllowanceFigureRow(
                title: LocalizedStringResource(
                    "Resting energy",
                    comment: "Allowance breakdown row: the energy the body spent at rest so far today"
                ),
                kilocalories: allowance.restingKilocalories,
                isEstimated: allowance.restingIsEstimated
            )
            AllowanceFigureRow(
                title: LocalizedStringResource(
                    "Active energy",
                    comment: "Allowance breakdown row: the energy movement and workouts spent so far today"
                ),
                kilocalories: allowance.activeKilocalories,
                isEstimated: false
            )
            AllowanceFigureRow(
                title: LocalizedStringResource(
                    "Today’s total",
                    comment: "Allowance breakdown row: resting plus active energy — what the day has spent so far, not an allowance"
                ),
                kilocalories: allowance.maintenanceKilocalories,
                isEstimated: allowance.restingIsEstimated
            )
            AllowanceFigureRow(
                title: LocalizedStringResource(
                    "Eaten so far",
                    comment: "Allowance breakdown row: the energy eaten so far today"
                ),
                kilocalories: allowance.intakeKilocalories,
                isEstimated: allowance.intakeIsEstimated
            )
            AllowanceFigureRow(
                title: LocalizedStringResource(
                    "Left for dinner",
                    comment: "Allowance breakdown row: today's total minus what was eaten. Can be negative"
                ),
                kilocalories: allowance.allowanceKilocalories,
                isEstimated: allowance.restingIsEstimated || allowance.intakeIsEstimated
            )
            LabeledContent {
                Text(allowance.share, format: .percent.precision(.fractionLength(0)))
            } label: {
                Text(
                    LocalizedStringResource(
                        "Share of today",
                        comment: "Allowance breakdown row: what is LEFT to spend, as a share of the day's total — never the share consumed"
                    )
                )
            }
            Text("These figures are estimates, not nutritional advice.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case let .selfReported(report):
            LabeledContent("Your account") {
                Text(report.displayName)
            }
        case .provisional:
            Text("Nothing readable to go on — this verdict is provisional.")
                .foregroundStyle(.secondary)
        }
    }
}

/// One kilocalorie figure and, when it is one, the fact that it is an estimate.
///
/// Its own view rather than a computed property: a view is the unit of invalidation, and the
/// estimate label is announced together with its figure rather than as a separate element.
@MainActor
struct AllowanceFigureRow: View {
    let title: LocalizedStringResource
    let kilocalories: Double
    let isEstimated: Bool

    var body: some View {
        LabeledContent {
            VStack(alignment: .trailing, spacing: 2) {
                Text(
                    Measurement(value: kilocalories, unit: UnitEnergy.kilocalories)
                        .formatted(.measurement(width: .abbreviated, usage: .food))
                )
                if isEstimated {
                    Text("Estimated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Text(title)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Recorded") {
    Form {
        AllowanceBreakdownRow(basis: .energyBalance(SampleDecisions.moderateAllowance))
    }
}

#Preview("Estimated and spent") {
    Form {
        AllowanceBreakdownRow(basis: .energyBalance(SampleDecisions.spentAllowance))
    }
}

#Preview("Self-reported") {
    Form {
        AllowanceBreakdownRow(basis: .selfReported(.less))
    }
}
