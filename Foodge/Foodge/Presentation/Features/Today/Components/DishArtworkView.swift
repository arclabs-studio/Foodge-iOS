//
//  DishArtworkView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// The original artwork for one dish family.
///
/// Deliberately the only place a family is mapped to artwork, mirroring `JudgeBadgeView`'s
/// reasoning (D60): the mapping stays centralized instead of being duplicated across screens.
/// Decorative: the dish name is already shown as text beside it.
@MainActor
struct DishArtworkView: View {
    let family: DishFamily

    @ScaledMetric(relativeTo: .largeTitle) private var diameter: CGFloat = 64

    var body: some View {
        Image(artwork)
            .resizable()
            .scaledToFit()
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }

    private var artwork: ImageResource {
        switch family {
        case .burgers: .dishBurger
        case .pizza: .dishPizza
        case .tacos: .dishTacos
        case .riceBowls: .dishRiceBowl
        case .tortilla: .dishTortilla
        case .pasta: .dishPasta
        case .lentilSalad: .dishLentilSalad
        case .vegetableSoup: .dishVegetableSoup
        case .vegetableWraps: .dishVegetableWrap
        }
    }
}

#Preview {
    DishArtworkView(family: .tacos)
}
