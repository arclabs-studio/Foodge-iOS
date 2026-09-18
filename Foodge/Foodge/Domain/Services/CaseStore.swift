//
//  CaseStore.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Saves and reads the one case per local day.
///
/// Reopening an unchanged case returns the saved decision instead of regenerating it, and a
/// failed save is reported as a failure — never as a save. Revisions and appeals join this
/// protocol on Day 21, when their models enter the schema.
protocol CaseStore: Sendable {
    /// Saves a decision as the current state of the case for `day`.
    func save(_ decision: VerdictDecision, for day: Date) async throws
    /// The decision already stored for `day`, or `nil` when there is none.
    func decision(for day: Date) async throws -> VerdictDecision?
}
