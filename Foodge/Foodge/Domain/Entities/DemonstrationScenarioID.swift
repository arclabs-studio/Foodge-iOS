//
//  DemonstrationScenarioID.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// The labelled demonstration scenarios Foodge can be run on, as a Domain value.
///
/// The scenarios themselves live in Data (`SyntheticScenarios`), which Presentation may not name
/// (D34). This enum is what crosses instead: Settings renders it, `AppLaunch` carries it, and Data
/// turns it back into a scenario through an exhaustive switch (D99). No protocol seam — there is
/// no I/O here and no failure mode, which is exactly the case D36 rules a seam out for.
///
/// **Declaration order is the offer order.** It matches `SyntheticScenarios.all` one for one, and
/// `DemonstrationScenarioCatalogueTests` fails if the two ever drift apart.
///
/// All ten cases were replaced with the rebuild (D111): the four that demonstrated the recorded
/// pattern have nothing left to demonstrate, and the four allowance bands are what a verdict now
/// turns on.
enum DemonstrationScenarioID: String, CaseIterable, Hashable, Sendable, Identifiable {
    case generousAllowance
    case modestAllowance
    case slimAllowance
    case allowanceSpent
    case estimatedResting
    case estimatedIntake
    case noHealthData
    case shortSleep
    case dstSpringForward
    case noCompatibleDish

    var id: String { rawValue }
}
