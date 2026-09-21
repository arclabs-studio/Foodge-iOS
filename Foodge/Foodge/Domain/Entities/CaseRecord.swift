//
//  CaseRecord.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

/// The chosen dinner an appeal names — a compatible catalogue craving, or a free-text dish
/// outside the catalogue that receives no invented nutritional analysis (`foodge-plan.md`
/// section 3). Appeal negotiation itself (matching a compatible craving, honest no-match) is
/// WU-22-A's job; this only gives an appeal a place to be recorded.
enum AppealChoice: Hashable, Sendable {
    case catalogue(variantID: String, family: DishFamily)
    case freeText(String)
}

/// An appeal a caller wants recorded against one revision, before it has an id.
struct AppealDraft: Sendable {
    let createdAt: Date
    let choice: AppealChoice
}

/// An appeal as it was actually saved.
struct SavedAppeal: Hashable, Sendable, Identifiable {
    let id: UUID
    let createdAt: Date
    let choice: AppealChoice
}

/// A new revision a caller wants recorded, before it has an id or a sequence.
struct NewRevisionDraft: Sendable {
    let decision: VerdictDecision
    let evidence: EvidenceSnapshot
    let catalogueVersion: String
    let dishOutcome: PersistedDishOutcome
}

/// A revision as it was actually saved, carrying everything needed to reopen it without
/// regenerating anything.
struct SavedRevision: Hashable, Sendable, Identifiable {
    let id: UUID
    let sequence: Int
    let createdAt: Date
    let decision: VerdictDecision
    let evidence: EvidenceSnapshot
    let catalogueVersion: String
    let dishOutcome: PersistedDishOutcome
    /// `nil` until WU-23-A adds narration.
    let narrationText: String?
    let appeals: [SavedAppeal]
}

/// The one case for a local day, in the form that can cross the persistence actor's boundary.
///
/// Live `@Model` objects stay bound to `PersistenceActor`'s context; nothing above ``CaseStore``
/// ever sees one, the same rule ``PreferencesDraft`` already follows for preferences.
struct SavedCase: Hashable, Sendable {
    let localDayKey: String
    /// Ascending by sequence, oldest first.
    let revisions: [SavedRevision]

    var latestRevision: SavedRevision? {
        revisions.max { $0.sequence < $1.sequence }
    }
}
