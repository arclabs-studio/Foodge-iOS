//
//  DishHeroView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import SwiftUI

/// Tonight's dish, large: the verdict's centrepiece (D145).
///
/// Decorative — the dish name is the text right below it. The family → artwork mapping is
/// `DishFamily.artwork`, the one place it lives (D60).
@MainActor
struct DishHeroView: View {
    let family: DishFamily

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Image(family.artwork)
            .resizable()
            .scaledToFit()
            .frame(height: StageArtworkSize.height(StageArtworkSize.dish, at: dynamicTypeSize))
            .accessibilityHidden(true)
    }
}

#Preview {
    DishHeroView(family: SampleDecisions.dishOutcome.family)
}
