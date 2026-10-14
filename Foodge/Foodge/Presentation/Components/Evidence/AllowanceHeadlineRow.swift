//
//  AllowanceHeadlineRow.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import SwiftUI

/// The figure the verdict turned on — what today left for dinner — at the head of the allowance
/// breakdown, with a gauge of the share of today it is and the rule's bands beneath it (WU-29-H).
///
/// **The gauge is `.linearCapacity`**, a fill that stops at the share: `LinearGaugeStyle`, the bar with
/// a marker, is unavailable on iOS, and `.accessoryLinear` is a Lock Screen widget style. The HIG's *Gauges* guidance asks for labels naming the current value and both ends of the
/// range; they are drawn here as plain text around a bare bar rather than in the gauge's own label
/// slots, which truncated the label and wrapped "100 %" at AX 5 in Spanish (`arc-audit-accessibility`).
///
/// A negative share draws an empty bar (`gaugeShare`); the figure, the percentage and the gauge's
/// accessibility value all stay the true, negative share, because the allowance is never floored
/// (D112) — VoiceOver must not hear the clamped 0 %.
///
/// The fill is the verdict's category tint. Cheese reads under 3:1 as a shape on a light row; D151
/// extends D145's exception to this fill because the share and every band are also text.
@MainActor
struct AllowanceHeadlineRow: View {
    let allowance: EnergyAllowance
    let category: DinnerCategory

    private var isEstimated: Bool {
        allowance.restingIsEstimated || allowance.intakeIsEstimated
    }

    private var shareLabel: LocalizedStringResource {
        LocalizedStringResource(
            "Share of today left",
            comment: "Allowance gauge label: what is LEFT to spend, as a share of the day's total — never the share consumed"
        )
    }

    private var shareText: Text {
        Text(allowance.share, format: .percent.precision(.fractionLength(0)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Side by side while the figure fits beside its title; stacked at large sizes.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    title
                    Spacer()
                    figure(alignment: .trailing)
                }
                VStack(alignment: .leading, spacing: 4) {
                    title
                    figure(alignment: .leading)
                }
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: 6) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(shareLabel)
                        Spacer()
                        shareText
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shareLabel)
                            .fixedSize(horizontal: false, vertical: true)
                        shareText
                    }
                }
                // The gauge below carries the same label and value for VoiceOver.
                .accessibilityHidden(true)

                // No label slot: `.labelsHidden()` does not hide `.linearCapacity`'s label, which then
                // truncated at AX 5. The name and value are given to VoiceOver directly instead.
                Gauge(value: allowance.gaugeShare) {
                    EmptyView()
                }
                .gaugeStyle(.linearCapacity)
                .tint(Color(category.tint))
                .accessibilityLabel(Text(shareLabel))
                .accessibilityValue(shareText)

                // The range's two ends, under the ends of the bar. A percentage already says its
                // range, so VoiceOver skips the restatement.
                HStack {
                    Text(0.0, format: .percent)
                    Spacer()
                    Text(1.0, format: .percent)
                }
                .font(.caption)
                .foregroundStyle(.appBurgundyMuted)
                .accessibilityHidden(true)
            }

            AllowanceBandLegend()
        }
        .padding(.vertical, 4)
    }

    private var title: some View {
        Text(
            LocalizedStringResource(
                "Left for dinner",
                comment: "Allowance breakdown row: today's total minus what was eaten. Can be negative"
            )
        )
        .font(.headline)
    }

    private func figure(alignment: HorizontalAlignment) -> some View {
        EstimatedKilocalories(
            kilocalories: allowance.allowanceKilocalories,
            isEstimated: isEstimated,
            alignment: alignment,
            figureFont: .title2.bold()
        )
    }
}

/// The rule's three bands under the gauge, in the order the bar runs: light at the empty end, treat
/// at the full one. Read as one line by VoiceOver.
@MainActor
private struct AllowanceBandLegend: View {
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                band(.light)
                Spacer()
                band(.balanced)
                Spacer()
                band(.treat)
            }
            VStack(alignment: .leading, spacing: 2) {
                band(.light)
                band(.balanced)
                band(.treat)
            }
        }
        .font(.footnote)
        .foregroundStyle(.appBurgundyMuted)
        .accessibilityElement(children: .combine)
    }

    private func band(_ category: DinnerCategory) -> some View {
        Text(category.shareBand)
    }
}

#Preview("Recorded", traits: .sampleData) {
    Form {
        AllowanceHeadlineRow(allowance: SampleDecisions.moderateAllowance, category: .balanced)
    }
}

#Preview("Estimated and spent", traits: .sampleData) {
    Form {
        AllowanceHeadlineRow(allowance: SampleDecisions.spentAllowance, category: .light)
    }
}
