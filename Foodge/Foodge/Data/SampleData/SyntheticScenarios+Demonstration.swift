//
//  SyntheticScenarios+Demonstration.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

extension SyntheticScenarios {
    /// The scenario demonstration mode offers under `id`.
    ///
    /// An exhaustive switch rather than a lookup in ``all``: it is total by construction, so there
    /// is no optional to unwrap and no "unknown scenario" path to invent (D99). Adding a case to
    /// ``DemonstrationScenarioID`` fails this switch to compile until the scenario exists.
    static func scenario(for id: DemonstrationScenarioID) -> SyntheticScenario {
        switch id {
        case .generousAllowance: generousAllowance
        case .modestAllowance: modestAllowance
        case .slimAllowance: slimAllowance
        case .allowanceSpent: allowanceSpent
        case .estimatedResting: estimatedResting
        case .estimatedIntake: estimatedIntake
        case .noHealthData: noHealthData
        case .shortSleep: shortSleep
        case .dstSpringForward: dstSpringForward
        case .noCompatibleDish: noCompatibleDish
        }
    }
}
