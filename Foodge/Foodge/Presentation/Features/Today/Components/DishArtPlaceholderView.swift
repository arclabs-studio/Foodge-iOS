//
//  DishArtPlaceholderView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// One dish family, standing in as an SF Symbol until the artwork lands on Day 24.
///
/// Deliberately the only place a family is drawn, mirroring `JudgeBadgeView`'s reasoning (D60):
/// that swap should touch exactly one file, not a symbol map duplicated across screens.
/// Decorative: the dish name is already shown as text beside it.
@MainActor
struct DishArtPlaceholderView: View {
    let family: DishFamily

    @ScaledMetric(relativeTo: .largeTitle) private var diameter: CGFloat = 64

    var body: some View {
        Image(systemName: symbolName)
            .resizable()
            .scaledToFit()
            .frame(width: diameter, height: diameter)
            .foregroundStyle(.appBurgundy)
            .accessibilityHidden(true)
    }

    private var symbolName: String {
        switch family {
        case .burgers: "takeoutbag.and.cup.and.straw.fill"
        case .pizza: "triangle.fill"
        case .tacos: "birthday.cake.fill"
        case .riceBowls: "cup.and.saucer.fill"
        case .tortilla: "circle.fill"
        case .pasta: "circle.grid.2x2.fill"
        case .lentilSalad: "leaf.fill"
        case .vegetableSoup: "flame.fill"
        case .vegetableWraps: "scroll.fill"
        }
    }
}

#Preview {
    DishArtPlaceholderView(family: .tacos)
}
