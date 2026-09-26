//
//  FixtureReminderService.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation

/// A reminder service that records what Settings asked of it, and can refuse.
///
/// Used where the subject is the *view model's* behaviour — what it stores, shows and claims
/// after a refusal — rather than how a notification is built, which `LocalReminderServiceTests`
/// covers against its own seam.
actor FixtureReminderService: ReminderService {
    private(set) var scheduledTimes: [DateComponents] = []
    private(set) var cancelCount = 0

    private var failure: (any Error)?

    init(failure: (any Error)? = nil) {
        self.failure = failure
    }

    /// Lets a scripted refusal be lifted, so "they turned notifications on and tried again" is
    /// reachable in a test.
    func stopFailing() {
        failure = nil
    }

    func schedule(at time: DateComponents) async throws {
        if let failure {
            throw failure
        }
        scheduledTimes.append(time)
    }

    func cancel() async {
        cancelCount += 1
    }
}
