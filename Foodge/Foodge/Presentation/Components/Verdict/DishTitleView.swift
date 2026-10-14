//
//  DishTitleView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// A dish's name — the screen's largest text (D145) — and its family below it, under the dish's
/// artwork on the verdict and on case detail.
@MainActor
struct DishTitleView: View {
    let variantID: String
    let family: DishFamily

    var body: some View {
        VStack(spacing: 4) {
            Text(DishCatalogue.displayName(forVariantID: variantID))
                .font(.largeTitle.bold())
            Text(family.displayName)
                .font(.headline)
                // `appBurgundyMuted` is measured on every stage top and every system surface by
                // `PaletteContrastTests` (D134, D145).
                .foregroundStyle(.appBurgundyMuted)
        }
        .multilineTextAlignment(.center)
        // The height its wrapped lines need, so a `Form` row (case detail) cannot truncate the name.
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .sampleData) {
    DishTitleView(variantID: SampleDecisions.dishOutcome.variantID, family: SampleDecisions.dishOutcome.family)
        .padding()
        .background { StageBackground(accent: Color(DinnerCategory.balanced.tint)) }
}
