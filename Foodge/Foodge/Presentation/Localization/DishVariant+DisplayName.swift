//
//  DishVariant+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 20/09/2026.
//

import Foundation

extension DishVariant {
    /// The variant's name as the user sees it.
    ///
    /// `nameKey` holds English prose, not a dotted identifier (D37) — see
    /// `Ingredient.displayName` for why, and why this must never interpolate `nameKey`.
    var displayName: LocalizedStringResource {
        LocalizedStringResource(String.LocalizationValue(stringLiteral: nameKey))
    }

    /// The same name as a plain `String`, for sorting and searching in a given locale.
    ///
    /// See `Ingredient.localizedName(in:)` for why this looks the key up directly in `locale`'s
    /// own `.lproj` table rather than through `String(localized:locale:)`.
    func localizedName(in locale: Locale) -> String {
        Ingredient.localizedString(for: nameKey, in: locale)
    }
}
