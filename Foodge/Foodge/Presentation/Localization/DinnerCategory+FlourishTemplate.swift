//
//  DinnerCategory+FlourishTemplate.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import Foundation

extension DinnerCategory {
    /// The reviewed flourish shown whenever no validated model line exists — which is the default
    /// state, and stays the state for every failure: Apple Intelligence off, unsupported, still
    /// downloading, refused, too slow, or rejected by ``NarrationValidator``.
    ///
    /// **Keyed by category only, with no dish-name interpolation**, deliberately. A category-keyed
    /// template renders correctly for a `.noMatch` outcome, where no dish name exists at all, and
    /// for a historical case whose stored `variantID` a later catalogue no longer resolves —
    /// `DishCatalogue.displayName(forVariantID:)` falls back to the raw id, and a raw id must never
    /// reach prose.
    ///
    /// These are editorial lines in the judge's voice. Nothing here claims a nutritional fact,
    /// names a number, or comments on the person.
    var flourishTemplate: LocalizedStringResource {
        switch self {
        case .treat:
            LocalizedStringResource(
                "The court has reviewed the evidence and finds no objection to something generous tonight.",
                comment: "The judge's decorative flourish for a Treat verdict"
            )
        case .balanced:
            LocalizedStringResource(
                "The court has reviewed the evidence. Tonight’s leading candidate is on the table.",
                comment: "The judge's decorative flourish for a Balanced verdict"
            )
        case .light:
            LocalizedStringResource(
                "The court is inclined towards something lighter tonight. The defence may still appeal.",
                comment: "The judge's decorative flourish for a Light verdict"
            )
        }
    }
}
