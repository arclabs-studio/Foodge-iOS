//
//  JudgeQuipLocalizationTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 10/10/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The judge's quips are decoration with the flourish's voice rules (D146). They are proven the
/// way the narration templates are — against the **built** artefact, never a tool's return value
/// (D26) — using the `es.lproj/Localizable.strings` oracle `CatalogueNameLocalizationTests`
/// established, and against `NarrationValidator`, which is where those voice rules live.
///
/// The validator is the oracle for "obeys the voice rules" and the shipped strings are the oracle
/// for "has a Spanish line"; neither is derived from `JudgeQuip`. The English source is read from
/// `LocalizedStringResource.key`, not resolved through the running locale, so the suite gives the
/// same answer on a simulator that came up Spanish (D142). `String(localized:locale:)` is
/// deliberately not used: D37 proved it lies inside a hosted test target.
///
/// ## What the validator will refuse, so a failure here is not a surprise
///
/// A number or number word (`two`, `dos`, `mil`), a unit (`hour`, `hora`, `step`, `paso`), the
/// earning, guilt, compensation and skip-a-meal phrases, nutritional authority (`healthy`,
/// `diet`, `sano`, `dieta`), body and worth (`fat`, `discipline`, `tu cuerpo`), more than two
/// sentence terminators, and anything over 160 characters. An English line breaking a rule is a
/// copy problem; a **Spanish** line breaking one is usually a natural translation colliding with
/// the Spanish banned list, which is exactly what the template suite exists to surface.
@Suite("Judge quip localization", .tags(.integration, .critical))
struct JudgeQuipLocalizationTests {
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

    /// The English source of a quip, read from the resource itself rather than resolved through
    /// the current locale. It is also the String Catalog key and so the key of the Spanish line.
    private static func english(of quip: JudgeQuip) -> String {
        quip.text.key
    }

    /// The Spanish line the built app ships for a quip, or a loud failure naming the quip.
    private static func spanish(of quip: JudgeQuip) throws -> String {
        try #require(
            spanishStrings[english(of: quip)],
            "\(quip) ships no Spanish line: \"\(english(of: quip))\" is absent from es.lproj"
        )
    }

    /// Each group of quips that share a line, as `a, b share "line"`, sorted so a failure message
    /// reads the same every run. Empty when every quip has a line of its own.
    private static func sharedLines(_ lines: [(quip: JudgeQuip, line: String)]) -> [String] {
        Dictionary(grouping: lines, by: \.line)
            .filter { $0.value.count > 1 }
            .map { line, owners in
                "\(owners.map { "\($0.quip)" }.sorted().joined(separator: ", ")) share \"\(line)\""
            }
            .sorted()
    }

    // MARK: - English

    @Test("Every English quip satisfies the narration voice rules", arguments: JudgeQuip.allCases)
    func englishQuipsPassTheValidator(quip: JudgeQuip) {
        // Given the quip's English source
        let english = Self.english(of: quip)

        // Then the judge's decoration obeys exactly the rules imposed on the model's flourish —
        // no number, no nutritional authority, no guilt or earning framing, short and one remark.
        // `.accepted` carries the normalized text, so equality also proves the quip has no stray
        // leading, trailing or doubled whitespace.
        #expect(
            NarrationValidator.validate(english) == .accepted(english),
            "The English \(quip) quip does not satisfy the narration voice rules: \"\(english)\""
        )
    }

    @Test("The English quips are distinct")
    func englishQuipsAreDistinct() {
        // Given the English source of every quip
        let lines = JudgeQuip.allCases.map { (quip: $0, line: Self.english(of: $0)) }

        // Then no two quips say the same thing — a copy-paste would make a tap appear to do
        // nothing, and would pass every other test here
        let shared = Self.sharedLines(lines)
        #expect(shared.isEmpty, "English quips repeat each other: \(shared)")
    }

    // MARK: - Spanish

    @Test("Every quip ships a Spanish line that is not its English source", arguments: JudgeQuip.allCases)
    func everyQuipShipsASpanishLine(quip: JudgeQuip) throws {
        // Given the Spanish strings actually built into the app bundle
        try #require(
            !Self.spanishStrings.isEmpty,
            "es.lproj/Localizable.strings could not be read from the built app"
        )

        // Then the quip has a Spanish counterpart — otherwise a Spanish device shows English
        // prose in the judge's bubble — and it is a translation, not the English copied across
        let spanish = try Self.spanish(of: quip)
        #expect(
            spanish != Self.english(of: quip),
            "The Spanish \(quip) line is the English source copied across: \"\(spanish)\""
        )
    }

    @Test("The Spanish quips are distinct")
    func spanishQuipsAreDistinct() throws {
        // Given the shipped Spanish line of every quip — a missing one fails here by name rather
        // than quietly shrinking the set that is compared
        let lines = try JudgeQuip.allCases.map { try (quip: $0, line: Self.spanish(of: $0)) }

        // Then no two quips say the same thing in Spanish either
        let shared = Self.sharedLines(lines)
        #expect(shared.isEmpty, "Spanish quips repeat each other: \(shared)")
    }

    @Test("Every Spanish quip satisfies the narration voice rules", arguments: JudgeQuip.allCases)
    func spanishQuipsPassTheValidator(quip: JudgeQuip) throws {
        // Given the shipped Spanish line
        let spanish = try Self.spanish(of: quip)

        // Then it satisfies the same rules as the English one. This is what catches a natural
        // translation that collides with the Spanish banned list or number words — a line the app
        // would ship while the validator rejects the model for saying the same thing.
        #expect(
            NarrationValidator.validate(spanish) == .accepted(spanish),
            "The Spanish \(quip) quip does not satisfy the narration voice rules: \"\(spanish)\""
        )
    }
}
