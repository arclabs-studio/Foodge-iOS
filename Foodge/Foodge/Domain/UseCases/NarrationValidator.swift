//
//  NarrationValidator.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import Foundation

/// Why a candidate flourish was refused.
///
/// The specific case exists so each rule has its own oracle in tests and its own label in the
/// device log. `ValidatingNarrator` collapses every case to `nil` at the layer boundary, so the
/// user never learns that a line was rejected.
enum NarrationRejection: Hashable, Sendable {
    case empty
    case tooLong
    /// Newlines, control characters, or more sentences than a one-line flourish can be.
    case unsuitableShape
    case numericClaim
    case bannedPhrase
    case echoesNote

    /// A label that is safe to log: the rule that fired, never the candidate that fired it.
    var logLabel: String {
        switch self {
        case .empty: "empty"
        case .tooLong: "tooLong"
        case .unsuitableShape: "unsuitableShape"
        case .numericClaim: "numericClaim"
        case .bannedPhrase: "bannedPhrase"
        case .echoesNote: "echoesNote"
        }
    }
}

/// The outcome of validating one candidate flourish.
enum NarrationValidation: Hashable, Sendable {
    /// Trimmed and whitespace-collapsed — this exact string is what may be shown and saved.
    case accepted(String)
    case rejected(NarrationRejection)
}

/// The product's voice rules, applied to a candidate flourish before anything can show or save it.
///
/// Pure and Foundation-only, so the rules can be exercised off-device against production code: the
/// simulator has no Apple Intelligence at all, and rules welded inside the model call would be
/// untestable. Two layers consume it — the narrator chain, and the tests that prove the shipped
/// templates satisfy the same rules imposed on model output.
///
/// **False rejects are cheap; false accepts are not.** A rejected line silently becomes the
/// reviewed template, which is a perfectly good outcome; an accepted bad line reaches the user.
enum NarrationValidator {
    /// The longest flourish that may be shown. The prompt asks for 140, leaving headroom below
    /// this threshold rather than aiming at it.
    static let maximumCharacters = 160

    /// Validates one candidate against every voice rule, in a **fixed order** so a string that
    /// breaks two rules always reports the same one.
    ///
    /// Order: normalize → empty → shape → length → numeric claim → banned phrase → note echo.
    static func validate(_ candidate: String, note: Note?) -> NarrationValidation {
        let normalized = normalize(candidate)
        guard !normalized.isEmpty else { return .rejected(.empty) }
        guard !hasUnsuitableShape(normalized) else { return .rejected(.unsuitableShape) }
        guard normalized.count <= maximumCharacters else { return .rejected(.tooLong) }

        let folded = fold(normalized)
        let words = wordScan(folded)

        guard !makesNumericClaim(folded: folded, words: words) else { return .rejected(.numericClaim) }
        guard !containsBannedPhrase(folded: folded, words: words) else { return .rejected(.bannedPhrase) }
        guard !echoes(note, in: folded) else { return .rejected(.echoesNote) }

        return .accepted(normalized)
    }

    // MARK: - Normalization

    /// Trims the ends and collapses runs of **horizontal** whitespace only.
    ///
    /// Newlines and control characters deliberately survive this step: they are what
    /// ``NarrationRejection/unsuitableShape`` exists to catch, and collapsing them into spaces
    /// first would hide a model that answered with a list or a preamble.
    private static func normalize(_ candidate: String) -> String {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        var result = ""
        var lastWasSpace = false
        for character in trimmed {
            if character == " " || character == "\t" {
                if !lastWasSpace {
                    result.append(" ")
                }
                lastWasSpace = true
            } else {
                result.append(character)
                lastWasSpace = false
            }
        }
        return result
    }

    /// Case, accent and width insensitive, in a fixed locale — so `TE LO HAS GANÁDO` and
    /// `quémalo` are matched by their plain forms without listing every spelling.
    private static func fold(_ text: String) -> String {
        text.folding(
            options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    /// Reduces folded text to space-separated words, padded at both ends.
    ///
    /// Every non-alphanumeric character becomes a separator, so `" dieta "` matches `dieta,` and
    /// `¡dieta!` alike, and a multi-word phrase like `" por ciento "` matches across punctuation.
    /// Searching this form is what makes every word match a **whole-word** match: `una` can never
    /// be found inside `unas`.
    private static func wordScan(_ folded: String) -> String {
        var result = " "
        var lastWasSpace = true
        for character in folded {
            if character.isLetter || character.isNumber {
                result.append(character)
                lastWasSpace = false
            } else if !lastWasSpace {
                result.append(" ")
                lastWasSpace = true
            }
        }
        if !lastWasSpace {
            result.append(" ")
        }
        return result
    }

    private static func contains(_ phrase: String, in words: String) -> Bool {
        words.contains(" \(phrase) ")
    }

    // MARK: - Shape

    private static let sentenceTerminators: Set<Character> = [".", "!", "?", "…"]

    /// A flourish is one short remark. Newlines, control characters, or a third sentence mean the
    /// model answered with something else — a list, a preamble, an explanation.
    private static func hasUnsuitableShape(_ text: String) -> Bool {
        let hasControlCharacter = text.unicodeScalars.contains { scalar in
            CharacterSet.newlines.contains(scalar) || CharacterSet.controlCharacters.contains(scalar)
        }
        if hasControlCharacter {
            return true
        }
        return text.filter { sentenceTerminators.contains($0) }.count > 2
    }

    // MARK: - Numeric claims

    /// Number words that can only be a quantity.
    ///
    /// **`one`, `un`, `una` and `uno` are deliberately absent.** `una` is the Spanish indefinite
    /// article; listing it would reject nearly every valid Spanish flourish. A negative-control
    /// test pins this, so "completing" the list fails loudly rather than silently killing the
    /// Spanish path.
    private static let numberWords = [
        "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "hundred", "thousand", "dozen", "twice", "double", "half", "percent",
        "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez",
        "cien", "ciento", "mil", "docena", "doble", "mitad", "por ciento",
    ]

    /// Units of measurement. These catch a claim with no digit in it at all — "plenty of
    /// calories" invents a measurement just as surely as "430 calories" does.
    private static let measurementUnits = [
        "kcal", "calorie", "calories", "caloria", "calorias",
        "gram", "grams", "gramo", "gramos",
        "step", "steps", "paso", "pasos",
        "minute", "minutes", "minuto", "minutos",
        "hour", "hours", "hora", "horas",
    ]

    /// Any numeral, number word or unit is refused — **total, and legitimately so**: the prompt
    /// contains no number of any kind (pinned by `NarrationPromptTests`), so any number in the
    /// output is necessarily invented.
    ///
    /// `Character.isNumber` covers far more than ASCII digits: `٣`, `½` and `³` are all caught.
    private static func makesNumericClaim(folded: String, words: String) -> Bool {
        if folded.contains(where: \.isNumber) {
            return true
        }
        if folded.contains("%") {
            return true
        }
        return numberWords.contains { contains($0, in: words) }
            || measurementUnits.contains { contains($0, in: words) }
    }

    // MARK: - Banned phrases

    /// Grouped by the `DESIGN.md` voice rule each one enforces. Jokes are about the case, never
    /// about a person's body, discipline or worth — and Foodge never speaks as a nutritionist.
    private static let bannedPhrases = [
        // Earning framing.
        "you earned", "you have earned", "earned it", "you deserve", "well deserved",
        "te lo has ganado", "te lo ganaste", "te lo mereces", "merecido",
        // Compensation framing.
        "burn it off", "burn off", "burn them off", "work it off", "make up for it",
        "quemalo", "quemarlo", "quemar", "compensar", "compensalo",
        // Guilt, and guilty-food framing.
        "guilt", "guilty", "guilt free", "cheat meal", "cheat day", "sinful", "indulgence you",
        "culpa", "culpable", "sin culpa", "pecado", "pecaminoso", "comida trampa",
        // Skipping a meal.
        "skip dinner", "skip a meal", "skip the meal", "skip supper", "go hungry",
        "saltate la cena", "saltarse la cena", "salta la cena", "no cenes", "ayuno", "ayunar",
        // Medical and nutritional authority.
        "healthy", "unhealthy", "nutritious", "nutrition", "nutritional", "diet", "dieting",
        "lose weight", "weight loss", "detox", "cleanse", "macros", "protein",
        "saludable", "sano", "sana", "nutritivo", "nutritiva", "nutricion", "dieta",
        "adelgazar", "perder peso", "bajar de peso", "desintoxicar", "proteina",
        // Body, discipline and worth.
        "your body", "willpower", "self control", "discipline", "disciplined", "fat", "skinny",
        "tu cuerpo", "fuerza de voluntad", "autocontrol", "disciplina", "gordo", "gorda", "flaco",
        // Injection artifacts that are words rather than punctuation.
        "ignore previous", "ignore your instructions", "ignore the above", "as an ai",
        "ignora las instrucciones", "como una ia", "system prompt",
    ]

    /// Fence and markup tokens, matched on the folded text directly — ``wordScan(_:)`` strips
    /// punctuation, so these could never be found in it.
    private static let bannedTokens = ["```", "<<<", ">>>"]

    private static func containsBannedPhrase(folded: String, words: String) -> Bool {
        bannedTokens.contains { folded.contains($0) }
            || bannedPhrases.contains { contains($0, in: words) }
    }

    // MARK: - Note echo

    /// How much of the note has to reappear before it counts as a quotation rather than a
    /// coincidence. Short enough to catch a fragment, long enough that two flourishes about the
    /// same dinner do not collide.
    private static let noteEchoWindow = 24

    /// Rejects a candidate that quotes the user's note back.
    ///
    /// The output half of the injection defence. The product rule is that a note may colour the
    /// judge's humour only — and colouring never requires quoting, so any substantial verbatim
    /// overlap means the model treated the note as content to reproduce.
    private static func echoes(_ note: Note?, in folded: String) -> Bool {
        guard let note else { return false }
        let foldedNote = fold(note.text)
        let characters = Array(foldedNote)
        guard characters.count >= noteEchoWindow else { return false }

        for start in 0...(characters.count - noteEchoWindow) {
            let window = String(characters[start ..< start + noteEchoWindow])
            if folded.contains(window) {
                return true
            }
        }
        return false
    }
}
