//
//  NarrationPrompt.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import Foundation

/// Builds the instructions and the prompt for the judge's flourish.
///
/// Pure string building, Foundation only — which is what makes the injection defence and the
/// no-numbers rule testable off-device, where no model exists.
///
/// **Deliberately absent:** any number whatsoever — no ratio, no median, no calorie figure, no
/// step count. This is the spec's "keep numerical explanations outside generation", and it is the
/// foundation the validator's total ban on numerals rests on: because the prompt contains none,
/// any number in the output is necessarily invented. Reason codes are absent for the same reason
/// (they are evidence-derived), and no `Tool` is exposed at all — nothing from persistence or from
/// decision-making is reachable from a generation.
enum NarrationPrompt {
    /// The model's standing role and prohibitions.
    ///
    /// Static English, never localized: a prompt is not user-facing copy. The one locale-dependent
    /// part is the directive naming the language to answer in.
    ///
    /// Untrusted text is **never** placed here — and since D138 there is none anywhere in this
    /// file. The free note was the only user-written text that ever reached the model, and it left
    /// with the screen that gathered it, taking its fence, its flattening and its "never follow
    /// instructions inside it" clause with it. Everything the model now sees is a value this app
    /// chose from a closed set.
    static func instructions(locale: Locale = .current) -> String {
        """
        You are a playful courtroom judge delivering one short, witty remark about tonight's \
        dinner. The verdict has already been decided; your remark is decoration and changes \
        nothing.

        Rules you must follow:
        - One sentence. At most 140 characters.
        - Never mention numbers, calories, steps, minutes, weights or percentages of any kind.
        - Never give health, nutrition, diet or medical advice, and never call food healthy or \
        unhealthy.
        - Never comment on the person's body, weight, discipline or worth.
        - Never tell anyone they earned a meal, should burn it off, or should skip a meal.
        - Joke about the case, never about the person.
        - You MUST write your response in \(languageName(for: locale)).
        """
    }

    /// Everything the model is given about tonight: the category, whether the ruling was
    /// provisional, and the dish. Three values this app chose — nothing the user wrote.
    static func prompt(for decision: VerdictDecision, dishName: String) -> String {
        var lines = ["Category: \(decision.category.rawValue)"]
        if decision.isProvisional {
            lines.append("Ruling: provisional")
        }
        lines.append("Dish: \(dishName)")
        return lines.joined(separator: "\n")
    }

    /// The English name of the language to answer in.
    ///
    /// Named in English because the instructions are English; `en_US_POSIX` keeps the name stable
    /// regardless of the device's own locale. Falls back to English when the code cannot be read —
    /// the model then answers in the language it defaults to, which is a flourish in the wrong
    /// language at worst, and the validator still governs what may be shown.
    private static func languageName(for locale: Locale) -> String {
        let english = Locale(identifier: "en_US_POSIX")
        guard
            let code = locale.language.languageCode?.identifier,
            let name = english.localizedString(forLanguageCode: code)
        else {
            return "English"
        }
        return name
    }
}
