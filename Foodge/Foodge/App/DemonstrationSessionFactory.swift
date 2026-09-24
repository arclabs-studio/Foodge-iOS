//
//  DemonstrationSessionFactory.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation
import SwiftData

/// Builds a complete demonstration session: a throwaway in-memory store, seeded preferences, and
/// dependencies that cannot reach Health, the notification centre or the real store.
///
/// This lives in the App layer because it names concrete Data types, which Presentation may not
/// (D34/D94). The narrator is the **real** chain — a demonstration exists partly to prove genuine
/// on-device narration — shared through ``AppDependencies/liveNarrator()`` rather than copied.
enum DemonstrationSessionFactory {
    /// - Throws: ``FoodgeError/storeUnavailable`` if the throwaway container cannot be opened, or
    ///   ``FoodgeError/saveFailed`` if the seed cannot be written. A caller that catches either
    ///   must stay on the live session: a broken demonstration must never look like a broken store.
    static func make(_ id: DemonstrationScenarioID) async throws -> AppSession {
        let scenario = SyntheticScenarios.scenario(for: id)

        let container: ModelContainer
        do {
            container = try ContainerFactory.makeInMemory()
        } catch {
            throw FoodgeError.storeUnavailable
        }

        let persistence = PersistenceActor(modelContainer: container)
        do {
            try await persistence.savePreferences(seededPreferences(for: scenario))
        } catch {
            throw FoodgeError.saveFailed
        }

        return AppSession(
            container: container,
            dependencies: AppDependencies(
                authorization: DemonstrationHealthAuthorization(),
                evidence: DemonstrationEvidenceProvider(scenario: scenario),
                store: persistence,
                caseStore: persistence,
                // The scenario's own fixed clock, so History, rotation and "avoid the last three
                // days" all agree with the evidence they are shown beside.
                clock: scenario.clock,
                narrator: AppDependencies.liveNarrator(),
                reminders: DemonstrationReminderService(),
                localData: persistence
            ),
            demonstration: id
        )
    }

    /// The preferences the demonstration store starts with, **derived from the scenario's own
    /// snapshot** (D100).
    ///
    /// This is the line the unit turns on. `TodayViewModel` reads stored preferences, not the
    /// snapshot, for both of the things a scenario needs in order to demonstrate itself:
    ///
    /// - `requestVerdict()` passes `draft.constraints` into the evidence call, and `finish()`
    ///   builds the `DishSelectionRequest` from `draft.constraints` — never `snapshot.constraints`.
    ///   Without seeding, `noCompatibleDish` would recommend an ordinary pasta dish instead of the
    ///   honest no-match its whole existence is about (D58).
    /// - The baseline calculator reads `draft.trackingRepresentative`. The snapshot's field of the
    ///   same name asks the same *standing* question ("do the recorded days reflect my usual
    ///   days?") but is read by nothing in production — the per-day check-in is asked fresh on
    ///   every low-ratio evaluation and stored nowhere (D32). Without seeding, `partialTracking`
    ///   would be inert.
    ///
    /// `onboardingCompletedAt` is set from the scenario clock so the demonstration opens on Today
    /// rather than onboarding — through D9's single source of truth, not a second flag.
    /// `favouriteFamilies` stays empty so nothing biases the dish pick beyond the scenario itself.
    static func seededPreferences(for scenario: SyntheticScenario) -> PreferencesDraft {
        let snapshot = scenario.snapshot
        return PreferencesDraft(
            dietProfile: snapshot.constraints.profile,
            excludedIngredientIDs: snapshot.constraints.excludedIngredientIDs,
            favouriteFamilies: [],
            dinnerRoutine: nil,
            trackingRepresentative: snapshot.trackingRepresentative ?? true,
            onboardingCompletedAt: scenario.clock.now,
            narrationEnabled: true,
            reminderHour: nil,
            reminderMinute: nil
        )
    }
}
