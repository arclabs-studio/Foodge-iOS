//
//  ReasonCode+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

extension ReasonCode {
    /// One sentence explaining this reason, assembled into the verdict's explanation.
    ///
    /// **No sentence here names a number.** The figures are rendered separately, from the
    /// allowance itself, by the evidence screen — so a reason sentence can never drift out of step
    /// with the arithmetic it describes. D62's four unreachable codes are gone rather than
    /// reinstated: every case below is assigned by `CheatMealAllowanceRule`.
    var displayText: LocalizedStringResource {
        switch self {
        case .generousAllowance:
            LocalizedStringResource(
                "Today left you a generous allowance to spend on dinner.",
                comment: "Verdict reason: the allowance is a large share of the day's maintenance"
            )
        case .moderateAllowance:
            LocalizedStringResource(
                "Today left you a fair allowance for dinner.",
                comment: "Verdict reason: the allowance is a moderate share of the day's maintenance"
            )
        case .slimAllowance:
            LocalizedStringResource(
                "Today left you a slim allowance for dinner.",
                comment: "Verdict reason: the allowance is a small share of the day's maintenance"
            )
        case .allowanceSpent:
            LocalizedStringResource(
                "Today’s meals have already passed what the day added up to.",
                comment: "Verdict reason: intake exceeds maintenance, so the allowance is negative"
            )
        case .restingEnergyEstimated:
            LocalizedStringResource(
                "Apple Health had no resting energy today, so this is estimated from your body basics.",
                comment: "Verdict reason: resting energy came from the Mifflin-St Jeor estimate"
            )
        case .intakeEstimated:
            LocalizedStringResource(
                "Nothing logged what you ate today, so this uses your own answers.",
                comment: "Verdict reason: intake came from the questionnaire rather than Health"
            )
        case .strongActivityToday:
            LocalizedStringResource(
                "You put real work in today, and it counts through the energy you spent.",
                comment: "Verdict reason: a workout or a high step count was recorded"
            )
        case .shortSleep:
            LocalizedStringResource(
                "Last night’s sleep was on the short side.",
                comment: "Verdict reason: sleep duration was short"
            )
        case .lowReportedEnergy:
            LocalizedStringResource(
                "You said your energy was low today.",
                comment: "Verdict reason: self-reported energy level was low"
            )
        case .selfReportedMore:
            LocalizedStringResource(
                "You said today was more active than usual.",
                comment: "Verdict reason: self-reported activity was 'more'"
            )
        case .selfReportedUsual:
            LocalizedStringResource(
                "You said today was about as active as usual.",
                comment: "Verdict reason: self-reported activity was 'usual'"
            )
        case .selfReportedLess:
            LocalizedStringResource(
                "You said today was less active than usual.",
                comment: "Verdict reason: self-reported activity was 'less'"
            )
        case .checkInSkipped:
            LocalizedStringResource(
                "There was nothing readable to go on and no check-in, so this is a provisional call.",
                comment: "Verdict reason: neither an allowance nor a self-report was available"
            )
        }
    }
}
