//
//  UserNotificationCentre.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation
import UserNotifications

/// The real notification centre, kept as thin as it can be.
///
/// Holds no reference of its own — each call reaches for `UNUserNotificationCenter.current()` —
/// so this type is a trivially `Sendable` struct and nothing here has to reason about the
/// sendability of a system singleton. Every decision worth testing lives one layer up in
/// ``LocalReminderService``; this file is the part that can only be verified on a device.
struct UserNotificationCentre: NotificationScheduling {
    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func add(_ notification: ScheduledNotification) async throws {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: notification.time,
            repeats: notification.repeats
        )

        try await UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: notification.identifier,
                content: content,
                trigger: trigger
            )
        )
    }

    func removePendingNotifications(identifiers: [String]) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: identifiers
        )
    }
}
