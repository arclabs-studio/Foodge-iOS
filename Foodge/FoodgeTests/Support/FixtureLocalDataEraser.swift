//
//  FixtureLocalDataEraser.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation

/// A deletion seam that counts what it was asked to do, and can refuse.
///
/// The real `PersistenceActor.eraseLocalData()` throws only when `modelContext.save()` does,
/// which an in-memory container never does — the same reason `PreferencesStore` has a fixture
/// (D34). Without this, "a failed deletion is never reported as a deletion" is unreachable.
actor FixtureLocalDataEraser: LocalDataErasing {
    private(set) var eraseCount = 0

    private let failure: (any Error)?

    init(failure: (any Error)? = nil) {
        self.failure = failure
    }

    func eraseLocalData() async throws {
        if let failure {
            throw failure
        }
        eraseCount += 1
    }
}
