//
//  CaseHeroSection.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// The top of case detail: the verdict's stamp and dish, standing still (D145).
///
/// The same parts the verdict reveals — `VerdictStampSection`, `DishHeroView`, `DishTitleView` — with
/// no reveal and no confetti: a filed case is read, not announced. It shows the dish that day named;
/// the stored runner-up was never chosen, so it stays off the screen.
@MainActor
struct CaseHeroSection: View {
    let category: DinnerCategory
    let isProvisional: Bool
    let variantID: String
    let family: DishFamily

    var body: some View {
        Section {
            VStack(spacing: 16) {
                VerdictStampSection(category: category, isProvisional: isProvisional)
                DishHeroView(family: family)
                DishTitleView(variantID: variantID, family: family)
            }
            .frame(maxWidth: .infinity)
        }
        .listRowBackground(Color.clear)
    }
}

#Preview(traits: .sampleData) {
    Form {
        CaseHeroSection(
            category: SampleDecisions.balancedVerdict.category,
            isProvisional: SampleDecisions.balancedVerdict.isProvisional,
            variantID: SampleDecisions.dishOutcome.variantID,
            family: SampleDecisions.dishOutcome.family
        )
    }
}

#Preview("Longest name", traits: .sampleData) {
    Form {
        CaseHeroSection(
            category: SampleDecisions.treatVerdict.category,
            isProvisional: SampleDecisions.treatVerdict.isProvisional,
            variantID: SampleDecisions.longestNameDishOutcome.variantID,
            family: SampleDecisions.longestNameDishOutcome.family
        )
    }
}
