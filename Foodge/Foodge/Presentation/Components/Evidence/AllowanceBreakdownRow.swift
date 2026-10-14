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
///
/// The allowance itself leads (`AllowanceHeadlineRow`, WU-29-H); the four figures it is worked out
/// from follow. `category` only tints the gauge.
@MainActor
struct AllowanceBreakdownRow: View {
    let basis: CategoryBasis
    let category: DinnerCategory

    var body: some View {
        switch basis {
        case let .energyBalance(allowance):
            AllowanceHeadlineRow(allowance: allowance, category: category)
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
        case let .selfReported(report):
            LabeledContent("Your account") {
                Text(report.displayName)
            }
        case .provisional:
            Text("Nothing readable to go on — this verdict is provisional.")
                .foregroundStyle(.appBurgundyMuted)
        }
    }
}

/// The estimates disclaimer, for a `Section` footer rather than a list row.
///
/// It qualifies the figures above it, so a footer is where it belongs (`arc-audit-hig`, WU-EB):
/// as a row it read as one more piece of evidence, and VoiceOver reached it as a sibling of the
/// figures instead of as the section's own caption.
///
/// It is a view rather than a `String?` on the caller because it is only true of
/// ``CategoryBasis/energyBalance``: a self-reported night has no figures to qualify, and a
/// provisional one says its own sentence in the row. `EmptyView` in the other two cases leaves the
/// section with no footer at all.
@MainActor
struct AllowanceDisclaimerFooter: View {
    let basis: CategoryBasis

    var body: some View {
        switch basis {
        case .energyBalance:
            Text("These figures are estimates, not nutritional advice.")
                .formCaption()
        case .selfReported, .provisional:
            EmptyView()
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
            EstimatedKilocalories(kilocalories: kilocalories, isEstimated: isEstimated)
        } label: {
            Text(title)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Recorded", traits: .sampleData) {
    Form {
        AllowanceBreakdownRow(basis: .energyBalance(SampleDecisions.moderateAllowance), category: .balanced)
    }
    .labeledContentStyle(.readableValue)
}

#Preview("Estimated and spent", traits: .sampleData) {
    Form {
        AllowanceBreakdownRow(basis: .energyBalance(SampleDecisions.spentAllowance), category: .light)
    }
    .labeledContentStyle(.readableValue)
}

#Preview("Self-reported", traits: .sampleData) {
    Form {
        AllowanceBreakdownRow(basis: .selfReported(.less), category: .light)
    }
    .labeledContentStyle(.readableValue)
}
