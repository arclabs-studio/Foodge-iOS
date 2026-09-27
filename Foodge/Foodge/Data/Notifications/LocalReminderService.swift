//
//  LocalReminderService.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// The single optional evening reminder, as one repeating local notification.
///
/// Composes a ``NotificationScheduling`` rather than calling `UNUserNotificationCenter` itself,
/// so every rule below is reachable in a test with no device and no permission prompt.
///
/// Two rules this type exists to keep:
/// - A refused authorization schedules nothing and throws ``FoodgeError/reminderNotAuthorized``.
///   It is never reported as scheduled, the same class of honesty as "no readable data".
/// - The content is generic. Nothing derived from Health, from a note or from a verdict may
///   appear on a lock screen (`foodge-plan.md` §"Privacy and reminders"), and tapping it only
///   opens the app — it promises no background evaluation and no background generation.
struct LocalReminderService: ReminderService {
    /// One identifier, always reused: scheduling replaces the previous reminder rather than
    /// stacking a second one, and cancelling has exactly one thing to remove.
    static let requestIdentifier = "com.arclabs.Foodge.eveningReminder"

    private let centre: any NotificationScheduling

    init(centre: any NotificationScheduling) {
        self.centre = centre
    }

    /// Asks for permission, then schedules the reminder to repeat at that local time of day.
    ///
    /// Only `hour` and `minute` are passed on: a repeating calendar trigger matches the same
    /// wall-clock time every day, which stays correct across a daylight-saving change in a way
    /// a fixed 24-hour interval would not.
    ///
    /// - Throws: ``FoodgeError/reminderNotAuthorized`` when permission was refused;
    ///   ``FoodgeError/reminderSchedulingFailed`` when the request itself did not complete.
    func schedule(at time: DateComponents) async throws {
        let isAuthorized: Bool
        do {
            isAuthorized = try await centre.requestAuthorization()
        } catch {
            throw FoodgeError.reminderSchedulingFailed
        }

        guard isAuthorized else {
            throw FoodgeError.reminderNotAuthorized
        }

        let notification = ScheduledNotification(
            identifier: Self.requestIdentifier,
            title: String(localized: "Dinner verdict"),
            body: String(localized: "The judge is ready when you are."),
            time: DateComponents(hour: time.hour, minute: time.minute),
            repeats: true
        )

        do {
            try await centre.add(notification)
        } catch {
            throw FoodgeError.reminderSchedulingFailed
        }
    }

    /// Removes the pending reminder. Safe to call when there is none.
    func cancel() async {
        await centre.removePendingNotifications(identifiers: [Self.requestIdentifier])
    }
}
