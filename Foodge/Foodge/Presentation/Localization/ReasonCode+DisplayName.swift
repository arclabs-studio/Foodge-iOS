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
    /// `.baselineUnavailable`, `.trackingMarkedUnrepresentative`, `.shortSleep` and
    /// `.lowReportedEnergy` are written but unreachable this unit — `DinnerCategoryRule` never
    /// assigns them yet (D62), the same idiom as D54's unwritten `narrationText` column. They stay
    /// here rather than being left out, so a future caller finds the sentence already reviewed.
    var displayText: LocalizedStringResource {
        switch self {
        case .aboveRecordedPattern:
            LocalizedStringResource(
                "Today’s activity came in well above your recorded pattern.",
                comment: "Verdict reason: today ranked as a treat against the recorded pattern"
            )
        case .withinRecordedPattern:
            LocalizedStringResource(
                "Today’s activity sat within your recorded pattern.",
                comment: "Verdict reason: today ranked as balanced against the recorded pattern"
            )
        case .belowRecordedPattern:
            LocalizedStringResource(
                "Today’s activity came in below your recorded pattern.",
                comment: "Verdict reason: today ranked as light against the recorded pattern"
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
                "There was no recorded pattern or check-in to go on, so this is a provisional call.",
                comment: "Verdict reason: neither Health nor a self-report was available"
            )
        case .baselineUnavailable:
            LocalizedStringResource(
                "There wasn’t enough recorded history to build a pattern.",
                comment: "Verdict reason: not enough recorded days existed to compare against"
            )
        case .trackingMarkedUnrepresentative:
            LocalizedStringResource(
                "You said your recorded days don’t reflect how you usually live.",
                comment: "Verdict reason: the recorded pattern was marked unrepresentative"
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
        }
    }
}
