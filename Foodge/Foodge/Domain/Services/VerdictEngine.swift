//
//  VerdictEngine.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Turns a snapshot into a decision, deterministically.
///
/// The same snapshot must always produce the same outcome: this is what lets a saved case be
/// reopened without regenerating anything.
///
/// Dish selection does not join this protocol: `DinnerCategoryRule` already put the category
/// rule outside it, and ``DishSelection`` follows the same pattern — a pure function taking flat
/// scalars, not a second declaration of a contract this protocol has no conformer for.
protocol VerdictEngine: Sendable {
    func decideCategory(for snapshot: EvidenceSnapshot) -> CategoryOutcome
}
