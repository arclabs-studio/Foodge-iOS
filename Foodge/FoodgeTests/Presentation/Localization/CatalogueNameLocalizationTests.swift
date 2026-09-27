//
//  CatalogueNameLocalizationTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 20/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// Proves the localization gate against the **built** artefact, never a tool's return value
/// (D26). `Bundle.main` is `Foodge.app` here because `TEST_HOST` is set, so `es.lproj` is read
/// exactly as a Spanish user's device would read it.
///
/// The built app ships no `en.lproj` — English is the source language, so a String Catalog key
/// *is* the English string. That is what makes `es.lproj/Localizable.strings` a real, readable
/// oracle: a plain plist inside the test host's bundle.
@Suite("Catalogue name localization", .tags(.integration, .critical))
struct CatalogueNameLocalizationTests {
    private static let spanishStrings: [String: String] = {
        guard
            let lprojURL = Bundle.main.url(forResource: "es", withExtension: "lproj"),
            let dictionary = NSDictionary(
                contentsOf: lprojURL.appendingPathComponent("Localizable.strings")
            ) as? [String: String]
        else {
            return [:]
        }
        return dictionary
    }()

    private static let spanish = Locale(identifier: "es")

    private static var allNameKeys: Set<String> {
        Set(DishCatalogue.ingredients.map(\.nameKey) + DishCatalogue.entries.map(\.variant.nameKey))
    }

    @Test("Every catalogue name ships a Spanish string")
    func everyCatalogueNameShipsASpanishString() throws {
        // Given the Spanish strings actually built into the app bundle
        try #require(
            !Self.spanishStrings.isEmpty,
            "es.lproj/Localizable.strings could not be read from the built app"
        )

        // Then every English name the catalogue can show has a Spanish counterpart shipped
        for key in Self.allNameKeys {
            #expect(Self.spanishStrings[key] != nil, "\"\(key)\" has no Spanish translation shipped")
        }
    }

    @Test("Dynamic resolution actually works")
    func dynamicResolutionMatchesTheShippedValue() throws {
        // Given a name resolved dynamically from its English nameKey
        // Then it equals exactly what the build shipped for Spanish — catching the
        // interpolation-vs-stringLiteral mistake that test 1 alone would not
        for ingredient in DishCatalogue.ingredients {
            let expected = try #require(Self.spanishStrings[ingredient.nameKey])
            #expect(ingredient.localizedName(in: Self.spanish) == expected)
        }
        for entry in DishCatalogue.entries {
            let expected = try #require(Self.spanishStrings[entry.variant.nameKey])
            #expect(entry.variant.localizedName(in: Self.spanish) == expected)
        }
    }

    @Test("No nameKey is an identifier")
    func noNameKeyIsAnIdentifier() {
        // Guards the one failure mode the missing en.lproj creates: a dotted id used as a
        // nameKey would render the raw identifier on screen, in every language.
        for ingredient in DishCatalogue.ingredients {
            #expect(ingredient.nameKey != ingredient.id)
            #expect(!ingredient.nameKey.hasPrefix("ingredient."))
        }
        for entry in DishCatalogue.entries {
            #expect(entry.variant.nameKey != entry.variant.id)
            #expect(!entry.variant.nameKey.hasPrefix("dish."))
        }
    }
}
