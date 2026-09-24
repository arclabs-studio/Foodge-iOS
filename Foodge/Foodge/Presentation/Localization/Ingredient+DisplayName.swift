//
//  Ingredient+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 20/09/2026.
//

import Foundation

extension Ingredient {
    /// The ingredient's name as the user sees it.
    ///
    /// `nameKey` holds English prose, not a dotted identifier (D37): the built app ships no
    /// `en.lproj`, so with English as the source language the String Catalog key *is* the
    /// English string. `stringLiteral:` and never interpolation — `"\(nameKey)"` would build a
    /// *format string* with a substitution and look up a key that does not exist.
    var displayName: LocalizedStringResource {
        LocalizedStringResource(String.LocalizationValue(stringLiteral: nameKey))
    }

    /// The same name as a plain `String`, for sorting and searching in a given locale.
    ///
    /// Looks the key up in `locale`'s own `.lproj` table directly, rather than through
    /// `String(localized:locale:)` — that API resolves against the *current* locale's bundle
    /// resolution machinery, which in a hosted unit test (`TEST_HOST` set) does not follow the
    /// same bundle chain as `Bundle.main.url(forResource:)`, silently falling back to the source
    /// string for an explicit non-current locale. Falls back to `nameKey` itself when no table
    /// exists for `locale` — which is exactly the source-language case, since the built app
    /// ships no `en.lproj`.
    func localizedName(in locale: Locale) -> String {
        Self.localizedString(for: nameKey, in: locale)
    }

    /// The catalogue's ingredients, alphabetically ordered in `locale` and filtered by
    /// `searchText`, diacritic- and case-insensitively.
    ///
    /// A display helper on the model rather than a method on one screen's view model: two
    /// screens now offer the same exclusion list (onboarding and Settings), and only Presentation
    /// knows display names — the Domain catalogue orders ingredients by first appearance, not
    /// alphabetically.
    static func excludable(matching searchText: String, in locale: Locale) -> [Ingredient] {
        let candidates = searchText.isEmpty
            ? DishCatalogue.ingredients
            : DishCatalogue.ingredients.filter {
                $0.localizedName(in: locale).localizedStandardContains(searchText)
            }
        return candidates.sorted {
            $0.localizedName(in: locale).localizedStandardCompare($1.localizedName(in: locale)) == .orderedAscending
        }
    }

    static func localizedString(for key: String, in locale: Locale) -> String {
        guard
            let languageCode = locale.language.languageCode?.identifier,
            let lprojURL = Bundle.main.url(forResource: languageCode, withExtension: "lproj"),
            let bundle = Bundle(url: lprojURL)
        else {
            return key
        }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}
