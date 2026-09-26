//
//  VerdictDecision.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// What the category was actually decided from.
enum CategoryBasis: Hashable, Codable, Sendable {
    /// Today's energy allowance as a share of maintenance (D112).
    case energyBalance(EnergyAllowance)
    /// The user's own account, because no allowance could be computed.
    case selfReported(SelfReportedActivity)
    /// Neither was available and the check-in was skipped.
    case provisional
}

/// The individual reasons behind a verdict, so the explanation can be assembled from facts rather
/// than from prose.
///
/// Every case is reachable: the band codes and `allowanceSpent` come from the arithmetic, the two
/// provenance codes from where the figures came from, the three contextual codes from today's other
/// readings, and the last four from the fallbacks. The four unreachable codes D62 tolerated are
/// deliberately not reintroduced.
enum ReasonCode: String, Codable, CaseIterable, Hashable, Sendable {
    case generousAllowance
    case moderateAllowance
    case slimAllowance
    /// The allowance is zero or negative — its own sentence, because "a slim allowance" and
    /// "you have already spent it" are different things to be told.
    case allowanceSpent
    case restingEnergyEstimated
    case intakeEstimated
    case strongActivityToday
    case shortSleep
    case lowReportedEnergy
    case selfReportedMore
    case selfReportedUsual
    case selfReportedLess
    case checkInSkipped
}

/// A completed category decision, with everything needed to explain and to reproduce it.
struct VerdictDecision: Hashable, Codable, Sendable {
    let category: DinnerCategory
    let basis: CategoryBasis
    let reasonCodes: [ReasonCode]
    let isProvisional: Bool
    let ruleVersion: String
}
