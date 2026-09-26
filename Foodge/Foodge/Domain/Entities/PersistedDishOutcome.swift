//
//  PersistedDishOutcome.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

/// A catalogue-decoupled mirror of ``DishSelectionResult``.
///
/// Stores a variant id and family, never a live ``CatalogueEntry``, so a saved case still reads
/// after a catalogue version renames or removes a variant — the same precedent
/// ``RecentDishSelection`` already establishes for recent-history tracking.
///
/// A struct since D139: the `noMatch` case mirrored an outcome the rule can no longer produce.
struct PersistedDishOutcome: Hashable, Sendable {
    let variantID: String
    let family: DishFamily
    let alternativeVariantID: String?
    let alternativeFamily: DishFamily?

    init(variantID: String, family: DishFamily, alternativeVariantID: String?, alternativeFamily: DishFamily?) {
        self.variantID = variantID
        self.family = family
        self.alternativeVariantID = alternativeVariantID
        self.alternativeFamily = alternativeFamily
    }

    init(_ result: DishSelectionResult) {
        self.init(
            variantID: result.recommendation.id,
            family: result.recommendation.family,
            alternativeVariantID: result.alternative?.id,
            alternativeFamily: result.alternative?.family
        )
    }
}
