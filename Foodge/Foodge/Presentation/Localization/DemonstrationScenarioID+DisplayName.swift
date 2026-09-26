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
        case .generousAllowance:
            LocalizedStringResource("A generous allowance", comment: "Demonstration scenario: a big active day and a light lunch")
        case .modestAllowance:
            LocalizedStringResource("An ordinary allowance", comment: "Demonstration scenario: an ordinary day, squarely balanced")
        case .slimAllowance:
            LocalizedStringResource("A slim allowance", comment: "Demonstration scenario: a quiet day and a heavy lunch")
        case .allowanceSpent:
            LocalizedStringResource("The allowance is spent", comment: "Demonstration scenario: intake already exceeds the day's maintenance")
        case .estimatedResting:
            LocalizedStringResource("Resting energy estimated", comment: "Demonstration scenario: no basal samples, so the estimate comes from body basics")
        case .estimatedIntake:
            LocalizedStringResource("Meals answered by hand", comment: "Demonstration scenario: no dietary energy, so the questionnaire supplies intake")
        case .noHealthData:
            LocalizedStringResource("No readable Health data", comment: "Demonstration scenario: nothing readable from Apple Health")
        case .shortSleep:
            LocalizedStringResource("A short night", comment: "Demonstration scenario: an ordinary day on very little sleep")
        case .dstSpringForward:
            LocalizedStringResource("The hour Spain skips", comment: "Demonstration scenario: an evaluation during the daylight saving change")
        case .noCompatibleDish:
            LocalizedStringResource("Nothing on the menu fits", comment: "Demonstration scenario: exclusions block every dish in the tier")
        }
    }

    /// One line saying what the scenario is there to show.
    var detail: LocalizedStringResource {
        switch self {
        case .generousAllowance:
            LocalizedStringResource("A real workout and a light lunch, so the court is feeling generous.", comment: "Demonstration scenario detail: a large allowance")
        case .modestAllowance:
            LocalizedStringResource("An ordinary day, where dinner stays balanced.", comment: "Demonstration scenario detail: a moderate allowance")
        case .slimAllowance:
            LocalizedStringResource("A quiet day and a heavy lunch leave very little to spend.", comment: "Demonstration scenario detail: a slim allowance")
        case .allowanceSpent:
            LocalizedStringResource("Today's meals already passed the day's total, and dinner is still served.", comment: "Demonstration scenario detail: a negative allowance")
        case .estimatedResting:
            LocalizedStringResource("Apple Health has no resting energy, so your body basics stand in for it.", comment: "Demonstration scenario detail: estimated resting energy")
        case .estimatedIntake:
            LocalizedStringResource("Nothing logged what you ate, so your own answers do.", comment: "Demonstration scenario detail: estimated intake")
        case .noHealthData:
            LocalizedStringResource("Nothing readable at all, so Foodge asks you instead of guessing.", comment: "Demonstration scenario detail: no readable data")
        case .shortSleep:
            LocalizedStringResource("An ordinary day's figures on a night that was anything but.", comment: "Demonstration scenario detail: short sleep")
        case .dstSpringForward:
            LocalizedStringResource("An evaluation inside the hour the clocks jump forward.", comment: "Demonstration scenario detail: daylight saving day")
        case .noCompatibleDish:
            LocalizedStringResource("Every dish in the tier is blocked, and no exclusion is relaxed.", comment: "Demonstration scenario detail: honest no-match")
        }
    }
}
