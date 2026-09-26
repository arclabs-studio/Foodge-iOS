//
//  VerdictNarrator.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Produces the judge's optional flourish for a verdict that has already been decided.
///
/// The deterministic decision is complete before narration starts, and the flourish can never
/// change it. Returning `nil` means "use the reviewed template" — unavailable, disabled, refused,
/// too slow or failed validation all look the same from here, so core functionality never
/// depends on a model being present.
protocol VerdictNarrator: Sendable {
    func flourish(
        for decision: VerdictDecision,
        dishName: String,
        note: Note?
    ) async -> String?
}
