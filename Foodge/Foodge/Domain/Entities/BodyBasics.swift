//
//  BodyBasics.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

/// The parameter Mifflin–St Jeor selects on.
///
/// Deliberately not a general model of sex or gender: it exists because the published equation
/// has two forms, it is named after what it selects, and nothing outside
/// ``BasalMetabolicRate`` reads it.
enum BiologicalSex: String, Codable, CaseIterable, Hashable, Sendable {
    case female
    case male
}

/// The four figures a resting-energy estimate needs when Health cannot supply one (D113, D117).
///
/// Failable rather than clamping, and validating on decode as well as on init, for the same
/// reason ``Note`` is: an unanswered questionnaire and a nonsense one both mean "no estimate is
/// possible", and a clamped 300 kg would silently become a plausible-looking maintenance figure
/// that the whole verdict then rests on. `nil` is the honest answer, and the rule has a named
/// reason for it (`AllowanceUnavailableReason.noRestingBasis`).
struct BodyBasics: Hashable, Codable, Sendable {
    /// Ranges wide enough to hold any real user of a dinner app and narrow enough that a typo or
    /// a unit mix-up (inches for centimetres, pounds for kilograms) falls outside them.
    static let ageYearsRange = 13...120
    static let heightCentimetresRange = 120.0...230.0
    static let weightKilogramsRange = 30.0...300.0

    let sex: BiologicalSex
    let ageYears: Int
    let heightCentimetres: Double
    let weightKilograms: Double

    /// Creates the basics, or returns `nil` when any figure is outside its plausible range or is
    /// not a finite number.
    init?(
        sex: BiologicalSex,
        ageYears: Int,
        heightCentimetres: Double,
        weightKilograms: Double
    ) {
        guard
            Self.ageYearsRange.contains(ageYears),
            heightCentimetres.isFinite,
            weightKilograms.isFinite,
            Self.heightCentimetresRange.contains(heightCentimetres),
            Self.weightKilogramsRange.contains(weightKilograms)
        else { return nil }

        self.sex = sex
        self.ageYears = ageYears
        self.heightCentimetres = heightCentimetres
        self.weightKilograms = weightKilograms
    }

    /// Decodes the basics, rejecting stored figures that break the invariant rather than silently
    /// admitting them — the same contract ``Note`` decodes under.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try BodyBasics(
            sex: container.decode(BiologicalSex.self, forKey: .sex),
            ageYears: container.decode(Int.self, forKey: .ageYears),
            heightCentimetres: container.decode(Double.self, forKey: .heightCentimetres),
            weightKilograms: container.decode(Double.self, forKey: .weightKilograms)
        )

        guard let decoded else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Stored body basics are outside the plausible ranges."
                )
            )
        }

        self = decoded
    }
}
