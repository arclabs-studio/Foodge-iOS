//
//  PersistedDishOutcome+Flourish.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

extension PersistedDishOutcome {
    /// Whether the judge's flourish is shown at all for this outcome.
    ///
    /// A no-match night has no dish to be playful about, and every reviewed template is written as
    /// if one exists — a Balanced no-match would otherwise print "Tonight's leading candidate is on
    /// the table" with no candidate on the table. ``TodayViewModel/narrateIfNeeded()`` already
    /// never asks the model in that case; this is the display half of the same rule (D106).
    var showsFlourish: Bool {
        switch self {
        case .selected: true
        case .noMatch: false
        }
    }
}
