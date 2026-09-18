//
//  VerdictDecision.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// What the category was actually decided from.
enum CategoryBasis: Hashable, Codable, Sendable {
    /// A real comparison of today against the recorded pattern.
    case recorded(ratio: Double, baseline: ActivityBaseline)
    /// The user's own account, because no usable comparison existed.
    case selfReported(SelfReportedActivity)
    /// Neither was available and the check-in was skipped.
    case provisional
}

/// The individual reasons behind a verdict, so the explanation can be assembled from facts
/// rather than from prose.
enum ReasonCode: String, Codable, CaseIterable, Hashable, Sendable {
    case aboveRecordedPattern
    case withinRecordedPattern
    case belowRecordedPattern
    case selfReportedMore
    case selfReportedUsual
    case selfReportedLess
    case checkInSkipped
    case baselineUnavailable
    case trackingMarkedUnrepresentative
    case shortSleep
    case lowReportedEnergy
}

/// A completed category decision, with everything needed to explain and to reproduce it.
struct VerdictDecision: Hashable, Codable, Sendable {
    let category: DinnerCategory
    let basis: CategoryBasis
    let reasonCodes: [ReasonCode]
    let isProvisional: Bool
    let ruleVersion: String
}

/// The result of asking for a category.
///
/// A low-activity reading does not go straight to a verdict: Foodge first asks whether the
/// recorded activity reflects the day, and only then rules.
enum CategoryOutcome: Hashable, Sendable {
    case verdict(VerdictDecision)
    case needsTrackingConfirmation
}
