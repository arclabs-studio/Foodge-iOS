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
///
/// These are prototype product heuristics, not validated nutritional advice, and the explanation
/// the user sees has to say so.
enum DinnerCategoryRule {
    /// Ratios strictly above this are a treat.
    static let treatThreshold = 1.25
    /// Ratios strictly below this are light; the boundary itself is balanced.
    static let lightThreshold = 0.75
    /// Bumped whenever the table changes, so a saved case always says which rules produced it.
    static let ruleVersion = "1.0.0"

    static func decide(
        today: Double?,
        baseline: ActivityBaseline?,
        trackingRepresentative: Bool?,
        selfReport: SelfReportedActivity?
    ) -> CategoryOutcome {
        if let outcome = decideFromRecording(
            today: today,
            baseline: baseline,
            trackingRepresentative: trackingRepresentative
        ) {
            return outcome
        }

        // No usable comparison. The brief falls back to the user's own account, and only then to
        // a provisional ruling.
        if let selfReport {
            return .verdict(
                VerdictDecision(
                    category: category(for: selfReport),
                    basis: .selfReported(selfReport),
                    reasonCodes: [reasonCode(for: selfReport)],
                    isProvisional: false,
                    ruleVersion: ruleVersion
                )
            )
        }

        return .verdict(
            VerdictDecision(
                category: .balanced,
                basis: .provisional,
                reasonCodes: [.checkInSkipped],
                isProvisional: true,
                ruleVersion: ruleVersion
            )
        )
    }

    /// The recorded branch, or `nil` when the recording cannot decide and the fallbacks must.
    ///
    /// A missing reading for today is one of those cases: absent activity is not zero activity,
    /// so it must never fall through the "below 75%" door into a light verdict.
    private static func decideFromRecording(
        today: Double?,
        baseline: ActivityBaseline?,
        trackingRepresentative: Bool?
    ) -> CategoryOutcome? {
        guard let today, let baseline, baseline.median > 0 else { return nil }

        let ratio = today / baseline.median
        let basis = CategoryBasis.recorded(ratio: ratio, baseline: baseline)

        if ratio > treatThreshold {
            return verdict(.treat, basis: basis, reason: .aboveRecordedPattern)
        }

        if ratio >= lightThreshold {
            return verdict(.balanced, basis: basis, reason: .withinRecordedPattern)
        }

        // Below the lower threshold the brief requires asking whether the recording reflects the
        // day before ruling, because a forgotten watch looks exactly like a quiet day.
        guard trackingRepresentative == true else {
            return .needsTrackingConfirmation
        }

        return verdict(.light, basis: basis, reason: .belowRecordedPattern)
    }

    private static func verdict(
        _ category: DinnerCategory,
        basis: CategoryBasis,
        reason: ReasonCode
    ) -> CategoryOutcome {
        .verdict(
            VerdictDecision(
                category: category,
                basis: basis,
                reasonCodes: [reason],
                isProvisional: false,
                ruleVersion: ruleVersion
            )
        )
    }

    private static func category(for report: SelfReportedActivity) -> DinnerCategory {
        switch report {
        case .more: .treat
        case .usual: .balanced
        case .less: .light
        }
    }

    private static func reasonCode(for report: SelfReportedActivity) -> ReasonCode {
        switch report {
        case .more: .selfReportedMore
        case .usual: .selfReportedUsual
        case .less: .selfReportedLess
        }
    }
}
