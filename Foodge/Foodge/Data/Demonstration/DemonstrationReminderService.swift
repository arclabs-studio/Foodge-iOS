//
//  DemonstrationReminderService.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// Accepts the evening reminder and forgets it, so a demonstration can never schedule a real
/// notification or raise a permission prompt (D102).
///
/// `UNUserNotificationCenter` is unreachable from here — that is the whole safety property, and it
/// is asserted by wiring rather than by behaviour, in `DemonstrationSessionTests`: an empty body
/// has nothing observable to test.
///
/// Because this accepts silently, the evening-reminder row would read "on" for a reminder the
/// system never received. `SettingsView` therefore hides that row while a demonstration runs,
/// rather than letting a control say something untrue (D61/D92).
struct DemonstrationReminderService: ReminderService {
    func schedule(at _: DateComponents) async throws {}

    func cancel() async {}
}
