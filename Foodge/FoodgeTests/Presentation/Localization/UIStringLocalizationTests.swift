//
//  UIStringLocalizationTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// Sibling of `CatalogueNameLocalizationTests`: that suite proves every dish and ingredient name
/// ships a Spanish string, this one proves the same for every other UI string the String Catalog
/// declares — the copy that fell silently back to English when a key had no `es` localization at
/// all (86 of 239 keys, at one point).
///
/// The two sides of the comparison come from genuinely independent places:
/// - the **declared key set** is read straight off `Localizable.xcstrings` on disk, located via
///   `#filePath` rather than added as a test-target resource (verified: adding a resource to
///   `FoodgeTests` needs a `project.pbxproj` edit, which is forbidden here);
/// - the **shipped translations** are read from the **built** `es.lproj` inside the test host's
///   bundle (D26 — a tool's return value is not evidence, the built artefact is), covering both
///   `Localizable.strings` (flat keys) and `Localizable.stringsdict` (plural keys, e.g. "Based on
///   %lld recorded days.") since a plural key never appears in the flat file.
///
/// Neither side is produced by calling the same `LocalizedStringResource` lookup the app uses —
/// this never resolves a string through production code, it only compares two independently
/// produced artefacts.
@Suite("UI string localization", .tags(.integration, .critical))
struct UIStringLocalizationTests {
    /// A minimal decode of the String Catalog — only enough to enumerate keys and respect an
    /// explicit `shouldTranslate: false`, which marks a key as intentionally English-only.
    private struct StringCatalog: Decodable {
        let strings: [String: CatalogEntry]
    }

    private struct CatalogEntry: Decodable {
        let shouldTranslate: Bool?
    }

    /// Located relative to this source file rather than shipped as a test-target resource.
    private static let sourceCatalogURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // .../Localization (drops the file name)
        .deletingLastPathComponent() // .../Presentation
        .deletingLastPathComponent() // .../FoodgeTests
        .deletingLastPathComponent() // the project root, sibling of Foodge/ and FoodgeTests/
        .appendingPathComponent("Foodge/Resources/Localizable.xcstrings")

    /// Every key the String Catalog declares, minus any explicitly marked not to translate.
    private static let declaredKeys: Set<String> = {
        guard
            let data = try? Data(contentsOf: sourceCatalogURL),
            let catalog = try? JSONDecoder().decode(StringCatalog.self, from: data)
        else {
            return []
        }
        return Set(
            catalog.strings
                .filter { $0.value.shouldTranslate != false }
                .keys
        )
    }()

    private static let spanishFlatStrings: [String: String] = {
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

    private static let spanishPluralKeys: Set<String> = {
        guard
            let lprojURL = Bundle.main.url(forResource: "es", withExtension: "lproj"),
            let dictionary = NSDictionary(
                contentsOf: lprojURL.appendingPathComponent("Localizable.stringsdict")
            ) as? [String: Any]
        else {
            return []
        }
        return Set(dictionary.keys)
    }()

    /// Every key the built Spanish bundle actually carries a translation for, flat or plural.
    private static var shippedSpanishKeys: Set<String> {
        let nonEmptyFlatKeys = spanishFlatStrings.filter { !$0.value.isEmpty }.keys
        return Set(nonEmptyFlatKeys).union(spanishPluralKeys)
    }

    @Test("Every declared UI string ships a Spanish translation in the built app")
    func everyDeclaredUIStringShipsASpanishTranslation() throws {
        // Given the full key set the String Catalog source declares, and what the build actually
        // shipped for Spanish
        try #require(
            !Self.declaredKeys.isEmpty,
            "Localizable.xcstrings could not be parsed from \(Self.sourceCatalogURL.path)"
        )
        try #require(
            !Self.spanishFlatStrings.isEmpty || !Self.spanishPluralKeys.isEmpty,
            "Neither es.lproj/Localizable.strings nor es.lproj/Localizable.stringsdict could be read from the built app"
        )

        // When comparing every declared key against what the compiled Spanish bundle contains
        let missing = Self.declaredKeys.subtracting(Self.shippedSpanishKeys).sorted()

        // Then nothing the catalogue declares is left to fall back to English on a Spanish device
        #expect(missing.isEmpty, "No Spanish translation shipped for: \(missing.joined(separator: ", "))")
    }
}
