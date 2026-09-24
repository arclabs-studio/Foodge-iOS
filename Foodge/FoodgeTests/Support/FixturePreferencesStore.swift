//
//  FixturePreferencesStore.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
@testable import Foodge

/// A store that records what it was asked to write, and can be told to fail.
///
/// The real `PersistenceActor` throws only when `modelContext.save()` does, which an in-memory
/// container never does — so without this the "a failed save is never reported as a save" rule
/// would have no reachable test (D34).
actor FixturePreferencesStore: PreferencesStore {
    private(set) var savedDrafts: [PreferencesDraft] = []
    private var failure: (any Error)?
    /// What was already on disk before the subject ran.
    ///
    /// Deliberately not folded into `savedDrafts`: that list means "what the subject wrote", and
    /// a seeded value in it would make "nothing was saved" unprovable.
    private let seeded: PreferencesDraft?

    init(failure: (any Error)? = nil, seeded: PreferencesDraft? = nil) {
        self.failure = failure
        self.seeded = seeded
    }

    /// Lets one scripted failure be cleared, so a retry can be exercised.
    func stopFailing() {
        failure = nil
    }

    func savePreferences(_ draft: PreferencesDraft) async throws {
        if let failure {
            throw failure
        }
        savedDrafts.append(draft)
    }

    func preferences() async throws -> PreferencesDraft? {
        savedDrafts.last ?? seeded
    }
}
