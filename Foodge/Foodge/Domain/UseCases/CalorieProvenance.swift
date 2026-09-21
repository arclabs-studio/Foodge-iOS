//
//  CalorieProvenance.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

/// A dietary intake reading for one comparison attempt.
///
/// A manual figure **replaces** a Health-recorded total outright, never adds to it — modelled as
/// an enum rather than two optional fields so a caller cannot physically supply both to be summed.
enum RecordedIntake: Hashable, Sendable {
    case recordedFromHealth(EnergyAggregate)
    case manual(kilocalories: Double, window: DateInterval)
}

/// Everything one calorie-comparison attempt needs, bundled to keep the call site readable rather
/// than passing five loose parameters into ``CalorieProvenance/compare(_:)``.
struct CalorieComparisonRequest: Sendable {
    let activeEnergy: EnergyAggregate?
    let restingEnergy: EnergyAggregate?
    let intake: RecordedIntake?
    /// Whether the user has confirmed intake logging is complete for this period. A parameter,
    /// not a persisted field (D48) — there is no store to read it from yet, and the rule about
    /// what counts as "confirmed" belongs with the rule, not with a store that has no conformer.
    let intakeConfirmedComplete: Bool
}

/// A comparison of three recorded values kept visibly separate, plus the net the brief defines.
///
/// Labelled as a comparison of recorded values, never a "remaining food allowance" or a full-day
/// energy requirement — `netKilocalories` can be negative, and a negative result is a valid,
/// returned value, never suppressed.
struct CalorieComparison: Hashable, Sendable {
    let activeKilocalories: Double
    let restingKilocalories: Double
    let intakeKilocalories: Double
    let netKilocalories: Double
    let cutoff: DateInterval
    let intakeSource: IntakeSource

    enum IntakeSource: Hashable, Sendable {
        case health
        case manual
    }
}

/// Why no numerical comparison is available.
///
/// Never thrown — an unusable comparison is a correct consequence of missing or unconfirmed data,
/// the same reasoning ``DishSelectionOutcome/noMatch(blockingIngredientIDs:)`` uses (D43).
enum CalorieComparisonUnavailableReason: Hashable, Sendable {
    case missingActiveEnergy
    case missingRestingEnergy
    case missingIntake
    case intakeNotConfirmedComplete
    case cutoffMismatch
}

enum CalorieComparisonOutcome: Hashable, Sendable {
    case comparison(CalorieComparison)
    case unavailable(CalorieComparisonUnavailableReason)
}

/// What a dish variant's calorie display resolved to.
enum DishCalorieOutcome: Hashable, Sendable {
    case verified(CalorieReference)
    case unknown
}

/// Keeps active, resting and dietary energy as three separate recorded facts and only ever
/// combines them into one comparison when every precondition the product brief names actually
/// holds — never a floor-of-zero "remaining allowance", never an invented calorie value for a
/// dish with no verified reference.
enum CalorieProvenance {
    /// The calculation is: recorded active + recorded resting − confirmed recorded intake.
    static func compare(_ request: CalorieComparisonRequest) -> CalorieComparisonOutcome {
        guard let activeEnergy = request.activeEnergy else {
            return .unavailable(.missingActiveEnergy)
        }
        guard let restingEnergy = request.restingEnergy else {
            return .unavailable(.missingRestingEnergy)
        }
        guard let intake = request.intake else {
            return .unavailable(.missingIntake)
        }
        guard request.intakeConfirmedComplete else {
            return .unavailable(.intakeNotConfirmedComplete)
        }

        let (intakeKilocalories, intakeWindow, intakeSource): (Double, DateInterval, CalorieComparison.IntakeSource)
        switch intake {
        case .recordedFromHealth(let aggregate):
            intakeKilocalories = aggregate.kilocalories
            intakeWindow = aggregate.provenance.window
            intakeSource = .health
        case .manual(let kilocalories, let window):
            intakeKilocalories = kilocalories
            intakeWindow = window
            intakeSource = .manual
        }

        guard
            activeEnergy.provenance.window == restingEnergy.provenance.window,
            activeEnergy.provenance.window == intakeWindow
        else {
            return .unavailable(.cutoffMismatch)
        }

        let net = activeEnergy.kilocalories + restingEnergy.kilocalories - intakeKilocalories
        return .comparison(
            CalorieComparison(
                activeKilocalories: activeEnergy.kilocalories,
                restingKilocalories: restingEnergy.kilocalories,
                intakeKilocalories: intakeKilocalories,
                netKilocalories: net,
                cutoff: activeEnergy.provenance.window,
                intakeSource: intakeSource
            )
        )
    }

    /// `references` is a parameter, not a reach into ``CalorieReferenceCatalogue`` — matches
    /// `DishSelection.select(from:request:...)` taking `entries` as a parameter, so tests can
    /// exercise this against a synthetic list.
    static func calories(for variant: DishVariant, references: [CalorieReference]) -> DishCalorieOutcome {
        guard let referenceID = variant.calorieReferenceID else {
            return .unknown
        }
        guard let reference = references.first(where: { $0.id == referenceID }) else {
            return .unknown
        }
        return .verified(reference)
    }
}
