//
//  DishFamily+Artwork.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import DeveloperToolsSupport

extension DishFamily {
    /// The original artwork for this family — the single place a family is mapped to an image
    /// (D60), shared by the small `DishArtworkView` and the verdict's `DishHeroView`.
    var artwork: ImageResource {
        switch self {
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
