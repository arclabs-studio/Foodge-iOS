//
//  PersistenceActor.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
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
