//
//  FixtureNotificationCentre.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation

/// A notification centre that answers however a test needs it to, and remembers what it was
/// asked for.
///
/// The real centre raises a system permission prompt and cannot be driven off a device, so
/// without this the rule "a refused authorization schedules nothing and is never reported as
/// scheduled" would have no reachable test at all.
actor FixtureNotificationCentre: NotificationScheduling {
    private(set) var added: [ScheduledNotification] = []
    private(set) var removedIdentifiers: [[String]] = []
    private(set) var authorizationRequestCount = 0

    private let isAuthorized: Bool
    private let authorizationFailure: (any Error)?
    private let addFailure: (any Error)?

    init(
        isAuthorized: Bool = true,
        authorizationFailure: (any Error)? = nil,
        addFailure: (any Error)? = nil
    ) {
        self.isAuthorized = isAuthorized
        self.authorizationFailure = authorizationFailure
        self.addFailure = addFailure
    }

    func requestAuthorization() async throws -> Bool {
        authorizationRequestCount += 1
        if let authorizationFailure {
            throw authorizationFailure
        }
        return isAuthorized
    }

    func add(_ notification: ScheduledNotification) async throws {
        if let addFailure {
            throw addFailure
        }
        added.append(notification)
    }

    func removePendingNotifications(identifiers: [String]) async {
        removedIdentifiers.append(identifiers)
    }
}
