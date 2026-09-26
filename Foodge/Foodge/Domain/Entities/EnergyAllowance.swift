//
//  EnergyAllowance.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

/// Today's resting energy, and where it came from (D113, D114).
///
/// Absence is the absence of the enum — a `RestingEnergy?` of `nil` — never a zero case, the same
/// shape `HealthAggregates` uses for its six optionals.
enum RestingEnergy: Hashable, Codable, Sendable {
    /// HealthKit `basalEnergyBurned` for the evaluation window.
    case recorded(EnergyAggregate)
    /// Mifflin–St Jeor from body basics, prorated across the window's own local day.
    case estimated(kilocalories: Double, body: BodyBasics, window: DateInterval)

    var kilocalories: Double {
        switch self {
        case .recorded(let aggregate): aggregate.kilocalories
        case .estimated(let kilocalories, _, _): kilocalories
        }
    }

    /// The window the figure covers, which the rule checks against the evaluation window.
    var window: DateInterval {
        switch self {
        case .recorded(let aggregate): aggregate.provenance.window
        case .estimated(_, _, let window): window
        }
    }

    var isEstimated: Bool {
        switch self {
        case .recorded: false
        case .estimated: true
        }
    }
}

/// What today's energy balance came to, with every component kept visible.
///
/// Named an allowance rather than a requirement or a deficit, and every figure is an estimate: the
/// product is a playful dinner suggestion, not nutritional advice, and the copy that renders this
/// has to say so.
struct EnergyAllowance: Hashable, Codable, Sendable {
    let activeKilocalories: Double
    let restingKilocalories: Double
    let intakeKilocalories: Double
    /// `resting + active`. The denominator of ``share``.
    let maintenanceKilocalories: Double
    /// `maintenance − intake`. **Never floored at zero** — a negative allowance is a valid,
    /// returned value, and it never suppresses a dinner suggestion.
    let allowanceKilocalories: Double
    /// `allowance / maintenance`. The banded figure, so the rule scales with body size (D112).
    let share: Double
    let restingIsEstimated: Bool
    let intakeIsEstimated: Bool
    /// Local midnight up to the evaluation instant. Every component covers exactly this span.
    let window: DateInterval
}
