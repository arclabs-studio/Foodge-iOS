//
//  NotificationScheduling.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// One notification Foodge asks the system to show.
///
/// A value rather than a set of parameters so a test double can record exactly what was asked
/// for — the time and whether it repeats are the two things the reminder rule is about.
struct ScheduledNotification: Hashable, Sendable {
    let identifier: String
    let title: String
    let body: String
    /// A local time of day. Only `hour` and `minute` are ever set, so the system matches the
    /// same wall-clock time every day rather than a fixed interval.
    let time: DateComponents
    let repeats: Bool
}

/// The only three things Foodge needs from the system's notification centre.
///
/// The seam exists for the same reason as `HealthAuthorizing` (D34): the real centre presents a
/// system permission prompt and cannot be driven off a device, so without it the one rule that
/// must never break — a refused authorization schedules nothing and is never reported as
/// scheduled — would have no reachable test.
protocol NotificationScheduling: Sendable {
    /// Asks the user for permission to show the reminder.
    ///
    /// - Returns: `true` only when the system reports the request granted. A user who has
    ///   already refused gets no second prompt and this returns `false`.
    func requestAuthorization() async throws -> Bool

    /// Adds a request, replacing any existing one with the same identifier.
    func add(_ notification: ScheduledNotification) async throws

    /// Removes pending requests. Delivered notifications are not Foodge's to withdraw.
    func removePendingNotifications(identifiers: [String]) async
}
