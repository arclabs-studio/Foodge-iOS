//
//  FoodgeError+DemonstrationMessage.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

extension FoodgeError {
    /// What the scenario list says when a demonstration refused to start.
    ///
    /// Deliberately the **same** line whatever the cause — `self` is not switched on. Only
    /// `storeUnavailable` and `saveFailed` can reach it, and the distinction between them is of
    /// no use to someone who just wanted to see a scenario. What the line does say is the thing
    /// that matters: the live session kept running and nothing about the real store changed. A
    /// broken demonstration must never read like a broken app.
    var demonstrationMessage: LocalizedStringResource {
        "Foodge couldn’t start the demonstration. Nothing changed — choose a scenario to try again."
    }
}
