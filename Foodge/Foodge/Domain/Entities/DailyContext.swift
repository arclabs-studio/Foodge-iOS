//
//  DailyContext.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// How much time the user has for dinner tonight.
enum DinnerTime: String, Codable, CaseIterable, Hashable, Sendable {
    case quick
    case relaxed
}

/// How the user says they feel, independent of what Health recorded.
enum EnergyLevel: String, Codable, CaseIterable, Hashable, Sendable {
    case low
    case normal
}

/// The user's own account of the day's activity, used only when recorded evidence cannot
/// produce a usable comparison.
enum SelfReportedActivity: String, Codable, CaseIterable, Hashable, Sendable {
    case more
    case usual
    case less
}

/// A short free-text note from the user.
///
/// The note may colour the judge's humour and nothing else. It can never move a measurement, a
/// dietary constraint, a calorie value or a decision rule, and it is treated as untrusted content
/// wherever it reaches the language model.
struct Note: Hashable, Codable, Sendable {
    /// The longest note Foodge accepts.
    static let maximumLength = 240

    let text: String

    /// Creates a note, or returns `nil` when the text is empty or longer than ``maximumLength``.
    init?(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= Self.maximumLength else { return nil }
        self.text = trimmed
    }

    /// Decodes a note, rejecting stored text that breaks the length invariant rather than
    /// silently admitting it.
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try container.decode(String.self)
        guard let note = Note(decoded) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "A note must be non-empty and at most \(Self.maximumLength) characters."
            )
        }
        self = note
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(text)
    }
}

/// The optional context the user can add before asking for a verdict.
///
/// Structured choices refine the pick inside the decided category; they never change the category
/// rule itself.
struct DailyContext: Hashable, Codable, Sendable {
    let dinnerTime: DinnerTime?
    let energyLevel: EnergyLevel?
    let craving: DishFamily?
    let selfReportedActivity: SelfReportedActivity?
    let note: Note?

    init(
        dinnerTime: DinnerTime? = nil,
        energyLevel: EnergyLevel? = nil,
        craving: DishFamily? = nil,
        selfReportedActivity: SelfReportedActivity? = nil,
        note: Note? = nil
    ) {
        self.dinnerTime = dinnerTime
        self.energyLevel = energyLevel
        self.craving = craving
        self.selfReportedActivity = selfReportedActivity
        self.note = note
    }

    /// The context of a user who added nothing.
    static let empty = DailyContext()
}
