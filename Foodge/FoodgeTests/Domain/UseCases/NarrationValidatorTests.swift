//
//  NarrationValidatorTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 23/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The validator is the only thing standing between untrusted model output and the user, so every
/// rule is asserted against a concrete string with a concrete expected rejection — never "it came
/// back nil".
@Suite("Narration validator", .tags(.unit, .domain, .critical))
struct NarrationValidatorTests {
    // MARK: - Acceptance

    @Test("A clean English flourish is accepted, normalized")
    func cleanEnglishFlourishIsAccepted() {
        // Given a one-sentence remark with ragged whitespace
        let candidate = "   The court finds   the defence charming.  "

        // When it is validated
        let result = NarrationValidator.validate(candidate, note: nil)

        // Then it is accepted trimmed and whitespace-collapsed, exactly
        #expect(result == .accepted("The court finds the defence charming."))
    }

    @Test("A clean Spanish flourish is accepted, unchanged")
    func cleanSpanishFlourishIsAccepted() {
        // Given a Spanish remark that is already clean
        let candidate = "El tribunal declara la cena aprobada sin objeciones."

        // When it is validated
        let result = NarrationValidator.validate(candidate, note: nil)

        // Then it survives intact — accents and all
        #expect(result == .accepted("El tribunal declara la cena aprobada sin objeciones."))
    }

    @Test("Every shipped template passes its own rules")
    func everyShippedTemplatePasses() {
        // The English templates are the source strings themselves, so they can be validated
        // directly here. Their Spanish counterparts are validated against the built bundle in
        // `NarrationTemplateLocalizationTests`, which is where the ES copy actually lives.
        for category in DinnerCategory.allCases {
            let english = String(localized: category.flourishTemplate)
            #expect(
                NarrationValidator.validate(english, note: nil) == .accepted(english),
                "The \(category) template does not satisfy the rules it imposes on model output"
            )
        }
    }

    // MARK: - Length

    @Test("The length boundary admits 160 and refuses 161")
    func lengthBoundaryIsExact() {
        // Given two candidates either side of the limit
        let atLimit = String(repeating: "a", count: NarrationValidator.maximumCharacters)
        let overLimit = String(repeating: "a", count: NarrationValidator.maximumCharacters + 1)

        // Then the boundary itself is inclusive, and one character more is not
        #expect(NarrationValidator.validate(atLimit, note: nil) == .accepted(atLimit))
        #expect(NarrationValidator.validate(overLimit, note: nil) == .rejected(.tooLong))
    }

    // MARK: - Shape

    @Test("Nothing at all is rejected as empty")
    func emptyCandidateIsRejected() {
        #expect(NarrationValidator.validate("", note: nil) == .rejected(.empty))
        #expect(NarrationValidator.validate("   \n\t  ", note: nil) == .rejected(.empty))
    }

    @Test(
        "A candidate that is not one short remark is rejected on shape",
        arguments: [
            "Sure! Here's a line:\nThe court approves.",
            "The court approves. The court insists. The court adjourns.",
            "The court approves.\u{0007}",
        ]
    )
    func unsuitableShapesAreRejected(candidate: String) {
        #expect(NarrationValidator.validate(candidate, note: nil) == .rejected(.unsuitableShape))
    }

    // MARK: - Numeric claims

    @Test(
        "Any numeral is refused, ASCII or not",
        arguments: [
            "The court notes 430 units of effort.",
            "The court notes ٣ units of effort.",
            "The court awards ½ a portion.",
            "The court awards a portion³.",
        ]
    )
    func numeralsAreRejected(candidate: String) {
        #expect(NarrationValidator.validate(candidate, note: nil) == .rejected(.numericClaim))
    }

    @Test(
        "Number words are refused in both languages",
        arguments: [
            "The court awards double helpings.",
            "The court counted a dozen objections.",
            "El tribunal concede doble ración.",
            "El tribunal contó cien objeciones.",
            "El tribunal aprueba por ciento de la defensa.",
        ]
    )
    func numberWordsAreRejected(candidate: String) {
        #expect(NarrationValidator.validate(candidate, note: nil) == .rejected(.numericClaim))
    }

    @Test(
        "A unit of measurement is a claim even with no digit in sight",
        arguments: [
            "The court finds plenty of calories in evidence.",
            "The court admires your steps today.",
            "El tribunal reconoce tus pasos de hoy.",
            "El tribunal valora las calorías presentadas.",
        ]
    )
    func measurementUnitsAreRejected(candidate: String) {
        #expect(NarrationValidator.validate(candidate, note: nil) == .rejected(.numericClaim))
    }

    @Test(
        "Indefinite articles are not numbers — the negative control",
        arguments: [
            "The court allows one small objection.",
            "El tribunal admite una objeción pequeña.",
            "El tribunal admite un argumento sabroso.",
            "El tribunal declara uno de los platos aprobado.",
        ]
    )
    func indefiniteArticlesAreAccepted(candidate: String) {
        // This test fails the moment someone "completes" the number-word list with one/un/una/uno.
        // Without it, that change would silently reject nearly every valid Spanish flourish while
        // every other test in this suite still passed.
        #expect(NarrationValidator.validate(candidate, note: nil) == .accepted(candidate))
    }

    // MARK: - Banned phrases

    @Test(
        "Banned framing is caught through case and accents alike",
        arguments: [
            "TE LO HAS GANÁDO con creces.",
            "Puedes quémalo mañana.",
            "Sáltate la cena y listo.",
            "You earned this one.",
            "Burn it off tomorrow.",
            "A healthy choice tonight.",
            "Una cena saludable te espera.",
            "Perfecto para adelgazar.",
            "Your body will thank you.",
        ]
    )
    func bannedPhrasesAreRejected(candidate: String) {
        #expect(NarrationValidator.validate(candidate, note: nil) == .rejected(.bannedPhrase))
    }

    @Test(
        "Cheat-meal framing is accepted in English (D118)",
        arguments: [
            "The court grants one cheat meal.",
            "Consider it a cheat day, by order of the bench.",
            "A guilt free verdict, for once.",
        ]
    )
    func cheatMealFramingIsAccepted(candidate: String) {
        // The inverse of `bannedPhrasesAreRejected`, and the reason D119's change is exactly three
        // string removals: the product is a judge granting a cheat meal, and a validator that
        // refused the words could never let it say so. This test fails if any of the three is put
        // back into `bannedPhrases`.
        #expect(NarrationValidator.validate(candidate, note: nil) == .accepted(candidate))
    }

    @Test(
        "Exempting \"guilt free\" does not unban guilt itself (D128)",
        arguments: [
            "A guilty pleasure, says the court.",
            "The guilt is yours to carry.",
            "Sin culpa alguna.",
            "Un pecado delicioso.",
        ]
    )
    func theGuiltExemptionDoesNotReachActualGuiltFraming(candidate: String) {
        // The exemption excises "guilt free" before the banned sweep, so the risk it creates is
        // that it swallows the bare "guilt" ban with it. Each of these contains a guilt word that
        // is *not* part of the exempt phrase, and each must still be refused — otherwise the
        // exemption has quietly reopened exactly what D118 keeps banned.
        #expect(NarrationValidator.validate(candidate, note: nil) == .rejected(.bannedPhrase))
    }

    @Test("The hyphenated spelling is exempt too, because the word scan strips the hyphen")
    func theHyphenatedGuiltFreeSpellingIsAccepted() {
        // "guilt-free" and "guilt free" reach the banned sweep as the same words, so an exemption
        // written for one must cover the other. This is the spelling D119's rationale actually
        // named — "a guilt-free burger".
        let candidate = "A guilt-free burger, by order of the bench."
        #expect(NarrationValidator.validate(candidate, note: nil) == .accepted(candidate))
    }

    @Test(
        "The Spanish guilt framing stays banned even though the English is allowed",
        arguments: [
            "Hoy toca comida trampa.",
            "Una cena sin culpa.",
        ]
    )
    func spanishGuiltFramingIsStillRejected(candidate: String) {
        // *Comida trampa* is not the Spanish for a cheat meal in this product's voice: *trampa* is
        // cheating-as-transgression. The Spanish copy says *capricho*, and this is what stops a
        // well-meaning future edit from "matching" the English relaxation (D118).
        #expect(NarrationValidator.validate(candidate, note: nil) == .rejected(.bannedPhrase))
    }

    @Test(
        "Fence and instruction artifacts are caught",
        arguments: [
            "```The court approves.```",
            "NOTE>>> The court approves.",
            "As an AI, the court approves.",
        ]
    )
    func injectionArtifactsAreRejected(candidate: String) {
        #expect(NarrationValidator.validate(candidate, note: nil) == .rejected(.bannedPhrase))
    }

    // MARK: - Note echo

    @Test("A candidate that quotes the note back is rejected")
    func quotingTheNoteIsRejected() throws {
        // Given a note long enough to quote
        let note = try #require(Note("I had a rough meeting with the whole leadership team today"))

        // When the candidate repeats a long stretch of it verbatim
        let candidate = "The court notes: a rough meeting with the whole leadership team."

        // Then it is rejected — colouring the humour never requires quoting
        #expect(NarrationValidator.validate(candidate, note: note) == .rejected(.echoesNote))
    }

    @Test("Writing about the same subject without quoting is fine")
    func benignSameSubjectIsAccepted() throws {
        // Given the same note
        let note = try #require(Note("I had a rough meeting with the whole leadership team today"))

        // When the candidate is about the same day without reproducing it
        let candidate = "The court has heard about your afternoon and rules with sympathy."

        // Then it is accepted — the echo rule catches quotation, not subject matter
        #expect(NarrationValidator.validate(candidate, note: note) == .accepted(candidate))
    }

    @Test("A note shorter than the echo window cannot be echoed")
    func shortNotesCannotBeEchoed() throws {
        // Given a note shorter than the 24-character window
        let note = try #require(Note("pasta"))

        // When the candidate contains it
        let candidate = "The court proposes pasta."

        // Then there is no echo to reject: a five-letter overlap is a coincidence, not a quotation
        #expect(NarrationValidator.validate(candidate, note: note) == .accepted(candidate))
    }

    // MARK: - Determinism

    @Test("A doubly-violating candidate always reports the same rejection")
    func evaluationOrderIsFixed() {
        // Given a candidate that breaks the numeric rule and the banned-phrase rule at once
        let candidate = "You earned 400 of something."

        // When it is validated twice
        let first = NarrationValidator.validate(candidate, note: nil)
        let second = NarrationValidator.validate(candidate, note: nil)

        // Then both report the earlier rule in the documented order — numeric before banned
        #expect(first == .rejected(.numericClaim))
        #expect(first == second)
    }
}
