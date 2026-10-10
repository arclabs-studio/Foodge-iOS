//
//  DishArtworkView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// The original artwork for one dish family, at row size — History's `HistoryCaseRow`.
///
/// The family → artwork mapping is `DishFamily.artwork`, the one place it lives (D60), shared with
/// the verdict's large `DishHeroView`.
/// Decorative: the dish name is already shown as text beside it.
@MainActor
struct DishArtworkView: View {
    let family: DishFamily

    @ScaledMetric(relativeTo: .largeTitle) private var diameter: CGFloat = 56

    var body: some View {
        Image(family.artwork)
            .resizable()
            .scaledToFit()
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

#Preview {
    DishArtworkView(family: .tacos)
}
