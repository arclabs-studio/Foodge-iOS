//
//  PersistenceActor.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import OSLog
import SwiftData

/// The single place anything is written.
///
/// Views read with `@Query` and never insert, delete or save; every mutation arrives here as a
/// `Sendable` draft and is applied off the main actor. Live model objects never leave this
/// actor, because they belong to its context alone.
@ModelActor
actor PersistenceActor: PreferencesStore {
    /// Saves the user's preferences, creating the single record on first use.
    ///
    /// - Throws: ``FoodgeError/saveFailed`` if the write does not complete. The caller keeps the
    ///   result visible and offers a retry; it must never report a failed save as a save.
    func savePreferences(_ draft: PreferencesDraft) throws {
        let preferences: UserPreferences
        if let existing = try modelContext.fetch(FetchDescriptor<UserPreferences>()).first {
            preferences = existing
        } else {
            preferences = UserPreferences()
            modelContext.insert(preferences)
        }

        preferences.apply(draft)

        do {
            try modelContext.save()
        } catch {
            throw FoodgeError.saveFailed
        }
    }

    /// The stored preferences as a value, or `nil` when onboarding has never been completed.
    ///
    /// Returns a draft rather than the model object so nothing bound to this context escapes it.
    func preferences() throws -> PreferencesDraft? {
        guard let stored = try modelContext.fetch(FetchDescriptor<UserPreferences>()).first else {
            return nil
        }

        return PreferencesDraft(
            dietProfile: stored.dietProfile,
            excludedIngredientIDs: Set(stored.excludedIngredientIDs),
            favouriteFamilies: stored.favouriteFamilies,
            dinnerRoutine: stored.dinnerRoutine,
            trackingRepresentative: stored.trackingRepresentative,
            onboardingCompletedAt: stored.onboardingCompletedAt,
            narrationEnabled: stored.narrationEnabled,
            reminderHour: stored.reminderHour,
            reminderMinute: stored.reminderMinute
        )
    }
}

extension PersistenceActor: CaseStore {
    /// The case matching the local day `evidence` was evaluated on, or `nil` if none exists.
    ///
    /// Never mutates anything — the "reopen without regenerating" read.
    ///
    /// - Throws: ``FoodgeError/caseCorrupted`` if a stored revision fails to decode.
    func savedCase(matching evidence: EvidenceSnapshot) throws -> SavedCase? {
        let key = Self.localDayKey(for: evidence)
        let descriptor = FetchDescriptor<DailyCase>(predicate: #Predicate { $0.localDayKey == key })

        guard let stored = try modelContext.fetch(descriptor).first else { return nil }

        let revisions = try stored.revisions
            .sorted { $0.sequence < $1.sequence }
            .map { try $0.asSavedRevision() }

        return SavedCase(localDayKey: stored.localDayKey, revisions: revisions)
    }

    /// Appends a new revision, creating the case on first use. Prior revisions are preserved
    /// unchanged.
    ///
    /// - Throws: ``FoodgeError/saveFailed`` if the write does not complete.
    @discardableResult
    func recordRevision(_ draft: NewRevisionDraft) throws -> SavedRevision {
        let key = Self.localDayKey(for: draft.evidence)
        let descriptor = FetchDescriptor<DailyCase>(predicate: #Predicate { $0.localDayKey == key })

        let dailyCase: DailyCase
        if let existing = try modelContext.fetch(descriptor).first {
            dailyCase = existing
        } else {
            dailyCase = DailyCase(localDayKey: key)
            modelContext.insert(dailyCase)
        }

        let decisionData: Data
        let evidenceData: Data
        do {
            decisionData = try JSONEncoder().encode(draft.decision)
            evidenceData = try JSONEncoder().encode(draft.evidence)
        } catch {
            throw FoodgeError.saveFailed
        }

        let revision = VerdictRevision(
            sequence: dailyCase.revisions.count,
            createdAt: draft.evidence.evaluatedAt,
            decisionData: decisionData,
            evidenceData: evidenceData,
            catalogueVersion: draft.catalogueVersion,
            dishOutcome: draft.dishOutcome
        )
        revision.dailyCase = dailyCase
        dailyCase.revisions.append(revision)
        modelContext.insert(revision)

        do {
            try modelContext.save()
        } catch {
            throw FoodgeError.saveFailed
        }

        return try revision.asSavedRevision()
    }

    /// Attaches an appeal to one specific revision.
    ///
    /// - Throws: ``FoodgeError/revisionNotFound`` if no revision with that id exists;
    ///   ``FoodgeError/saveFailed`` if the write does not complete.
    func recordAppeal(_ draft: AppealDraft, to revisionID: UUID) throws {
        let descriptor = FetchDescriptor<VerdictRevision>(predicate: #Predicate { $0.id == revisionID })
        guard let revision = try modelContext.fetch(descriptor).first else {
            throw FoodgeError.revisionNotFound
        }

        let appeal = Appeal(createdAt: draft.createdAt, choice: draft.choice)
        appeal.revision = revision
        revision.appeals.append(appeal)
        modelContext.insert(appeal)

        do {
            try modelContext.save()
        } catch {
            throw FoodgeError.saveFailed
        }
    }

    /// Attaches validated narration to one specific revision, once.
    ///
    /// Write-once: a revision that already carries narration is returned unchanged rather than
    /// overwritten, so reopening a case is stable no matter how many times narration runs.
    ///
    /// - Throws: ``FoodgeError/revisionNotFound`` if no revision with that id exists;
    ///   ``FoodgeError/saveFailed`` if the write does not complete.
    @discardableResult
    func attachNarration(_ text: String, to revisionID: UUID) throws -> SavedRevision {
        let descriptor = FetchDescriptor<VerdictRevision>(predicate: #Predicate { $0.id == revisionID })
        guard let revision = try modelContext.fetch(descriptor).first else {
            throw FoodgeError.revisionNotFound
        }

        guard revision.narrationText == nil else {
            return try revision.asSavedRevision()
        }

        revision.narrationText = text

        do {
            try modelContext.save()
        } catch {
            throw FoodgeError.saveFailed
        }

        return try revision.asSavedRevision()
    }

    /// Every saved case, most recently recorded local day first.
    ///
    /// A day whose stored revisions fail to decode is skipped rather than failing the whole
    /// list — one corrupted day must never hide every other day's history. The outer `fetch`
    /// is not wrapped: a failure there is a genuine store problem, not a per-case decode issue,
    /// and propagates like every other method in this actor.
    func allCases() throws -> [SavedCase] {
        let descriptor = FetchDescriptor<DailyCase>(
            sortBy: [SortDescriptor(\.localDayKey, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).compactMap { dailyCase in
            do {
                let revisions = try dailyCase.revisions
                    .sorted { $0.sequence < $1.sequence }
                    .map { try $0.asSavedRevision() }
                return SavedCase(localDayKey: dailyCase.localDayKey, revisions: revisions)
            } catch {
                PersistenceLog.logger.error("PERSISTENCE case=corrupted")
                return nil
            }
        }
    }

    /// The single place the local-day key is derived, so "what day is this" has one source of
    /// truth rather than two that could disagree.
    ///
    /// Gregorian, in `evidence`'s own time zone — so a case reopened after travel still explains
    /// itself in the terms it was decided in. Falls back to `.gmt` only if the stored identifier
    /// is somehow unparseable — documented-unreachable, same idiom as `SyntheticScenarios.date`.
    private static func localDayKey(for evidence: EvidenceSnapshot) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: evidence.timeZoneIdentifier) ?? .gmt

        let components = calendar.dateComponents([.year, .month, .day], from: evidence.evaluatedAt)
        let year = zeroPadded(components.year ?? 0, width: 4)
        let month = zeroPadded(components.month ?? 0, width: 2)
        let day = zeroPadded(components.day ?? 0, width: 2)
        return "\(year)-\(month)-\(day)"
    }

    /// Zero-pads without a locale-sensitive formatter — this key is internal storage, not
    /// user-facing text, and must never vary with the device's locale. Assumes `value` is
    /// non-negative, true for every `year`/`month`/`day` component the Gregorian calendar
    /// produces for a date in this app's lifetime.
    private static func zeroPadded(_ value: Int, width: Int) -> String {
        let digits = String(value)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }
}
