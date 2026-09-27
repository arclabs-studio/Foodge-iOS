//
//  OnboardingLog.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import OSLog

/// The onboarding flow's log, and the rule about what may go into it.
///
/// **Only state labels.** Never a Health value, never a user's note, never model output. That
/// is why every call site passes ``OnboardingViewModel/HealthState/logLabel`` rather than the
/// state itself: `.connected` carries the recorded median, so interpolating the state with
/// `String(describing:)` would put someone's health data in the device log.
///
/// Physical-device verification here is `RunProject` plus the console (D21), so these lines are
/// the only way to see what the app decided on a real iPhone.
enum OnboardingLog {
    static let logger = Logger(subsystem: "com.arclabs.Foodge", category: "onboarding")
}
