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
            // A footer is already footnote-sized, so only the color is set here. `.secondary`
            // measures ~3.4:1 against the grouped background in standard-contrast light
            // appearance — below the 4.5:1 WCAG 1.4.3 needs. `appBurgundyMuted` is the brand's
            // dedicated secondary-text color, tuned to ≥4.5:1 in every appearance/contrast
            // combination.
            Text("These figures are estimates, not nutritional advice.")
                .foregroundStyle(.appBurgundyMuted)
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
            VStack(alignment: .trailing, spacing: 2) {
                // `Text(_:format:)` rather than a pre-formatted `String`: the latter hands
                // VoiceOver plain text with no numeric metadata, so a negative figure like
                // "−500 kcal" risks being read literally as "hyphen 500" instead of "negative
                // 500" (WCAG 1.3.1 / 4.1.2). Keeping the `Measurement` typed all the way into
                // `Text` preserves the sign semantics the same way `allowance.share` already does
                // two lines below via `Text(_:format:)`.
                Text(
                    Measurement(value: kilocalories, unit: UnitEnergy.kilocalories),
                    format: .measurement(width: .abbreviated, usage: .food)
                )
                if isEstimated {
                    Text("Estimated")
                        .font(.caption)
                        .foregroundStyle(.appBurgundyMuted)
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
