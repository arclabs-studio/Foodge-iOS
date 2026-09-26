//
//  PersistedDishOutcome.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

/// A catalogue-decoupled mirror of ``DishSelectionOutcome``.
///
/// Stores a variant id and family, never a live ``CatalogueEntry``, so a saved case still reads
/// after a catalogue version renames or removes a variant — the same precedent
/// ``RecentDishSelection`` already establishes for recent-history tracking.
enum PersistedDishOutcome: Hashable, Sendable {
    case selected(variantID: String, family: DishFamily, alternativeVariantID: String?, alternativeFamily: DishFamily?)
    case noMatch(blockingIngredientIDs: Set<String>)

    init(_ outcome: DishSelectionOutcome) {
        switch outcome {
        case let .selected(recommendation, alternative):
            self = .selected(
                variantID: recommendation.id,
                family: recommendation.family,
                alternativeVariantID: alternative?.id,
                alternativeFamily: alternative?.family
            )
        case let .noMatch(blockingIngredientIDs):
            self = .noMatch(blockingIngredientIDs: blockingIngredientIDs)
        }
    }
}
