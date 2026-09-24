//
//  FoodgeError+ReminderMessage.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

extension FoodgeError {
    /// What Settings says when the evening reminder could not be set.
    ///
    /// Two sentences, never one: a refusal is something the user can undo in the Settings app,
    /// and a failure is not — telling them apart is the same honesty rule that keeps "no readable
    /// data" separate from "denied" everywhere else in this app.
    var reminderMessage: LocalizedStringResource {
        switch self {
        case .reminderNotAuthorized:
            "Notifications are off for Foodge. Turn them on in the Settings app to use a reminder."
        default:
            "Foodge couldn’t set the reminder. Nothing was changed — try again."
        }
    }
}
