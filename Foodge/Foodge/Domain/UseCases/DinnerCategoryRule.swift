//
//  DinnerCategoryRule.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// The category decision table, as a pure function.
///
/// Above ``treatThreshold`` of the recorded pattern is a treat; between ``lightThreshold`` and
/// ``treatThreshold`` inclusive is balanced; below ``lightThreshold`` is light, but only once the
/// user has confirmed the recorded activity reflects the day. Without a usable comparison the
/// user's own account decides, and with nothing at all the verdict is a provisional balanced.
enum DinnerCategoryRule {
    /// Ratios strictly above this are a treat.
    static let treatThreshold = 1.25
    /// Ratios strictly below this are light; the boundary itself is balanced.
    static let lightThreshold = 0.75
    /// Bumped whenever the table changes, so a saved case always says which rules produced it.
    static let ruleVersion = "1.0.0"

    /// - Note: Not implemented yet — WU-19-A. It returns the provisional branch so the suites
    ///   that pin the real behaviour are red rather than crashing the test run.
    static func decide(
        today: Double?,
        baseline: ActivityBaseline?,
        trackingRepresentative: Bool?,
        selfReport: SelfReportedActivity?
    ) -> CategoryOutcome {
        .verdict(
            VerdictDecision(
                category: .balanced,
                basis: .provisional,
                reasonCodes: [.checkInSkipped],
                isProvisional: true,
                ruleVersion: ruleVersion
            )
        )
    }
}
