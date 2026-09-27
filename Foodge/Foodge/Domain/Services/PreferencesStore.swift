//
//  PreferencesStore.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// Reads and writes the user's preferences as values.
///
/// Nothing above this protocol knows SwiftData exists, and no live model object crosses it.
///
/// The seam exists so the failure path can be reached in a test: the real implementation throws
/// only when `modelContext.save()` throws, which an in-memory container never does — leaving the
/// one rule that must never break (a failed save is never reported as a save) unprovable (D34).
protocol PreferencesStore: Sendable {
    /// - Throws: ``FoodgeError/saveFailed`` if the write does not complete.
    func savePreferences(_ draft: PreferencesDraft) async throws

    /// The stored preferences, or `nil` when nothing has been saved yet.
    func preferences() async throws -> PreferencesDraft?
}
