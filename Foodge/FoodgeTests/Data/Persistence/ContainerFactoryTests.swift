//
//  ContainerFactoryTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Foodge

/// Reopening the store is the one thing a first schema has to get right, because getting it
/// wrong is only discovered by users losing their settings.
@Suite("Container factory", .tags(.integration, .critical))
struct ContainerFactoryTests {

    /// A fresh store location per test, so nothing leaks between them.
    private func makeStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "FoodgeTests-\(UUID().uuidString)")
            .appendingPathExtension("store")
    }

    @Test("Preferences written to a real store are still there when it is reopened")
    func preferencesSurviveContainerReopen() async throws {
        // Given preferences saved through the persistence actor into an on-disk store
        let url = makeStoreURL()
        let completedAt = TestCalendar.date(2026, 9, 18, 20, 15)
        let draft = PreferencesDraft(
            dietProfile: .vegetarian,
            excludedIngredientIDs: ["ingredient.mushroom", "ingredient.olive"],
            favouriteFamilies: [.tacos, .riceBowls],
            dinnerRoutine: .quick,
            trackingRepresentative: false,
            onboardingCompletedAt: completedAt,
            narrationEnabled: false,
            reminderHour: 20,
            reminderMinute: 30
        )

        let first = try ContainerFactory.make(at: url)
        try await PersistenceActor(modelContainer: first).savePreferences(draft)

        // When a completely separate container is opened on the same file
        let second = try ContainerFactory.make(at: url)
        let reloaded = try await PersistenceActor(modelContainer: second).preferences()

        // Then everything the user chose is still there, unchanged
        let stored = try #require(reloaded)
        #expect(stored.dietProfile == .vegetarian)
        #expect(stored.excludedIngredientIDs == ["ingredient.mushroom", "ingredient.olive"])
        #expect(stored.favouriteFamilies == [.tacos, .riceBowls])
        #expect(stored.dinnerRoutine == .quick)
        // The mark that says "do not use my recorded fortnight" is the one thing here that
        // silently re-enables itself if it is not persisted: the field defaults to true.
        #expect(stored.trackingRepresentative == false)
        #expect(stored.onboardingCompletedAt == completedAt)
        #expect(stored.narrationEnabled == false)
        #expect(stored.reminderHour == 20)
        #expect(stored.reminderMinute == 30)
    }

    @Test("A second save updates the one record instead of adding another")
    func savingTwiceKeepsASingleRecord() async throws {
        // Given preferences already saved once
        let url = makeStoreURL()
        let container = try ContainerFactory.make(at: url)
        let actor = PersistenceActor(modelContainer: container)
        try await actor.savePreferences(PreferencesDraft(dietProfile: .omnivore))

        // When the user changes their diet later
        try await actor.savePreferences(PreferencesDraft(dietProfile: .vegan))

        // Then there is still exactly one record, carrying the new choice — a duplicate would
        // leave the app reading whichever it happened to fetch first
        let reopened = try ContainerFactory.make(at: url)
        let context = ModelContext(reopened)
        let all = try context.fetch(FetchDescriptor<UserPreferences>())
        #expect(all.count == 1)
        #expect(all.first?.dietProfile == .vegan)
    }

    @Test("An in-memory container starts empty and keeps nothing")
    func inMemoryContainersDoNotPersist() async throws {
        // Given a scenario saved into an in-memory store, as demonstration mode does
        let demo = try ContainerFactory.makeInMemory()
        try await PersistenceActor(modelContainer: demo).savePreferences(
            PreferencesDraft(dietProfile: .pescatarian)
        )

        // When a second in-memory container is created
        let fresh = try ContainerFactory.makeInMemory()
        let reloaded = try await PersistenceActor(modelContainer: fresh).preferences()

        // Then it knows nothing of the first: demonstration data can never reach real history
        #expect(reloaded == nil)
    }
}
