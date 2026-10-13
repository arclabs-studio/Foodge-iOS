//
//  EstimatedKilocalories.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import SwiftUI

/// One kilocalorie figure and, when it is one, the word that marks it an estimate.
///
/// One view for every figure the evidence screens show — the allowance's headline and each line of its
/// breakdown — so a figure is formatted and marked the same way wherever it appears.
///
/// `Text(_:format:)` rather than a pre-formatted `String`: the latter hands VoiceOver plain text with
/// no numeric metadata, so a negative figure like "−500 kcal" risks being read literally as "hyphen
/// 500" instead of "negative 500" (WCAG 1.3.1 / 4.1.2). Keeping the `Measurement` typed all the way
/// into `Text` preserves the sign.
@MainActor
struct EstimatedKilocalories: View {
    let kilocalories: Double
    let isEstimated: Bool
    /// The edge the figure and its marker align to — trailing beside a label, leading when stacked.
    var alignment: HorizontalAlignment = .trailing
    var figureFont: Font = .body

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(
                Measurement(value: kilocalories, unit: UnitEnergy.kilocalories),
                format: .measurement(width: .abbreviated, usage: .food)
            )
            .font(figureFont)
            if isEstimated {
                Text("Estimated")
                    .font(.caption)
                    .foregroundStyle(.appBurgundyMuted)
            }
        }
    }
}

#Preview(traits: .sampleData) {
    Form {
        EstimatedKilocalories(kilocalories: SampleDecisions.spentAllowance.allowanceKilocalories, isEstimated: true)
    }
}
