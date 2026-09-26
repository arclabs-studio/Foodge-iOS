//
//  CaseStore.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Saves and reads the one case per local day.
///
/// Reopening an unchanged case returns the saved revisions instead of regenerating them; an
/// explicit "update evidence" appends an immutable new revision rather than overwriting the
/// first; and an appeal attaches to one specific revision. A failed save is reported as a
/// failure — never as a save.
protocol CaseStore: Sendable {
    /// The case matching the local day `evidence` was evaluated on, or `nil` if none exists.
    /// Never mutates anything — the "reopen without regenerating" read.
    func savedCase(matching evidence: EvidenceSnapshot) async throws -> SavedCase?

    /// Appends a new revision, creating the case on first use. Prior revisions are preserved
    /// unchanged — this never overwrites or deletes.
    @discardableResult
    func recordRevision(_ draft: NewRevisionDraft) async throws -> SavedRevision

    /// Attaches an appeal to one specific revision.
    /// - Throws: ``FoodgeError/revisionNotFound`` if no revision with that id exists.
    func recordAppeal(_ draft: AppealDraft, to revisionID: UUID) async throws

    /// Attaches validated narration to one specific revision, **once**.
    ///
    /// A revision that already carries narration is returned unchanged — reopening a case must be
    /// stable, so a second narration can never overwrite the first. Only genuine, validated model
    /// output is ever passed here; the reviewed template is never persisted.
    ///
    /// Returns the updated revision because ``SavedRevision`` is a let-only value that callers
    /// must replace rather than mutate.
    /// - Throws: ``FoodgeError/revisionNotFound`` if no revision with that id exists.
    @discardableResult
    func attachNarration(_ text: String, to revisionID: UUID) async throws -> SavedRevision

    /// Every saved case, most recently recorded local day first.
    ///
    /// A day whose stored revisions fail to decode is skipped rather than failing the whole list —
    /// one corrupted day must never hide every other day's history.
    func allCases() async throws -> [SavedCase]
}
