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
/// reopened without regenerating anything. Dish selection and the calorie comparison join this
/// protocol on Day 20, once the catalogue exists.
protocol VerdictEngine: Sendable {
    func decideCategory(for snapshot: EvidenceSnapshot) -> CategoryOutcome
}
