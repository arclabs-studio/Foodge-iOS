//
//  DemonstrationScenarioID+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

extension DemonstrationScenarioID {
    /// The name the scenario is offered under.
    var displayName: LocalizedStringResource {
        switch self {
        case .activeDay:
            LocalizedStringResource("An active day", comment: "Demonstration scenario: activity well above the usual pattern")
        case .typicalDay:
            LocalizedStringResource("A typical day", comment: "Demonstration scenario: activity inside the usual band")
        case .restDay:
            LocalizedStringResource("A rest day", comment: "Demonstration scenario: a quiet day the user confirmed")
        case .noHealthData:
            LocalizedStringResource("No readable Health data", comment: "Demonstration scenario: nothing readable from Apple Health")
        case .partialTracking:
            LocalizedStringResource("Tracking that doesn’t reflect the day", comment: "Demonstration scenario: recorded activity the user marked unrepresentative")
        case .stepsFallback:
            LocalizedStringResource("Steps instead of energy", comment: "Demonstration scenario: the comparison falls back to step count")
        case .shortSleep:
            LocalizedStringResource("A short night", comment: "Demonstration scenario: a usual day on very little sleep")
        case .dstSpringForward:
            LocalizedStringResource("The hour Spain skips", comment: "Demonstration scenario: an evaluation during the daylight saving change")
        case .quietDayUnconfirmed:
            LocalizedStringResource("A quiet day, not yet confirmed", comment: "Demonstration scenario: a low reading awaiting the check-in")
        case .noCompatibleDish:
            LocalizedStringResource("Nothing on the menu fits", comment: "Demonstration scenario: exclusions block every dish in the category")
        }
    }

    /// One line saying what the scenario is there to show.
    var detail: LocalizedStringResource {
        switch self {
        case .activeDay:
            LocalizedStringResource("Well above your recorded pattern, so the court is feeling generous.", comment: "Demonstration scenario detail: above-pattern day")
        case .typicalDay:
            LocalizedStringResource("Right inside the usual band, where dinner stays balanced.", comment: "Demonstration scenario detail: inside-the-band day")
        case .restDay:
            LocalizedStringResource("A quiet day you’ve confirmed was really that quiet.", comment: "Demonstration scenario detail: confirmed low-activity day")
        case .noHealthData:
            LocalizedStringResource("Nothing readable at all, so Foodge asks you instead of guessing.", comment: "Demonstration scenario detail: no readable data")
        case .partialTracking:
            LocalizedStringResource("The watch stayed on the table, and the recorded days say so.", comment: "Demonstration scenario detail: unrepresentative tracking")
        case .stepsFallback:
            LocalizedStringResource("Energy is missing on most days, so steps carry the comparison.", comment: "Demonstration scenario detail: steps fallback")
        case .shortSleep:
            LocalizedStringResource("A usual day’s activity on a night that was anything but.", comment: "Demonstration scenario detail: short sleep")
        case .dstSpringForward:
            LocalizedStringResource("An evaluation inside the hour the clocks jump forward.", comment: "Demonstration scenario detail: daylight saving day")
        case .quietDayUnconfirmed:
            LocalizedStringResource("Below your pattern, with the check-in still waiting for an answer.", comment: "Demonstration scenario detail: unconfirmed quiet day")
        case .noCompatibleDish:
            LocalizedStringResource("Every dish in the category is blocked, and no exclusion is relaxed.", comment: "Demonstration scenario detail: honest no-match")
        }
    }
}
