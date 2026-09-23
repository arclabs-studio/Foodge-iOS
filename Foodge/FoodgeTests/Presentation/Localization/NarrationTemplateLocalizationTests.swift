//
//  NarrationTemplateLocalizationTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 23/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The templates are the protected half of narration — the half that ships whenever the model
/// path fails, which is most of the time. They are proven against the **built** artefact, never a
/// tool's return value (D26), using the same `es.lproj/Localizable.strings` oracle
/// `CatalogueNameLocalizationTests` established. `String(localized:locale:)` is deliberately not
/// used: D37 proved it lies inside a hosted test target.
@Suite("Narration template localization", .tags(.integration, .critical))
struct NarrationTemplateLocalizationTests {
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

    /// The English source string for a category's template — which, with English as the source
    /// language, is also its String Catalog key.
    private static func englishTemplate(for category: DinnerCategory) -> String {
        String(localized: category.flourishTemplate)
    }

    @Test("Every category ships a Spanish template")
    func everyCategoryShipsASpanishTemplate() throws {
        // Given the Spanish strings actually built into the app bundle
        try #require(
            !Self.spanishStrings.isEmpty,
            "es.lproj/Localizable.strings could not be read from the built app"
        )

        // Then no category can fall back to English prose on a Spanish device
        for category in DinnerCategory.allCases {
            let key = Self.englishTemplate(for: category)
            #expect(Self.spanishStrings[key] != nil, "\(category) ships no Spanish flourish template")
        }
    }

    @Test("The three Spanish templates are distinct")
    func spanishTemplatesAreDistinct() throws {
        // Given the shipped Spanish templates
        let templates = try DinnerCategory.allCases.map { category in
            try #require(Self.spanishStrings[Self.englishTemplate(for: category)])
        }

        // Then each category says something of its own — a copy-paste that gave two categories the
        // same line would otherwise pass every other test here
        #expect(Set(templates).count == DinnerCategory.allCases.count)
    }

    @Test("Every Spanish template passes the validator")
    func spanishTemplatesPassTheValidator() throws {
        // Given the shipped Spanish templates
        try #require(
            !Self.spanishStrings.isEmpty,
            "es.lproj/Localizable.strings could not be read from the built app"
        )

        // Then the protected half satisfies exactly the rules imposed on the expendable half.
        // This is what catches a collision between the Spanish copy and the Spanish banned list —
        // a template the app would happily ship while the validator rejects the model for saying
        // the same thing.
        for category in DinnerCategory.allCases {
            let spanish = try #require(Self.spanishStrings[Self.englishTemplate(for: category)])
            #expect(
                NarrationValidator.validate(spanish, note: nil) == .accepted(spanish),
                "The Spanish \(category) template does not satisfy the narration voice rules"
            )
        }
    }
}
