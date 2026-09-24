//
//  DemonstrationEvidenceProviderTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The merge rule that keeps the walkthrough's "add context" step alive (D101).
///
/// The oracle is the scenario's own declaration in `SyntheticScenarios` — `shortSleep` ships
/// `energyLevel: .low` and 410 kcal — against what the provider hands back when asked with
/// something different.
@Suite("Demonstration evidence provider", .tags(.unit))
struct DemonstrationEvidenceProviderTests {
    private func makeSUT(
        _ scenario: SyntheticScenario = SyntheticScenarios.shortSleep
    ) -> DemonstrationEvidenceProvider {
        DemonstrationEvidenceProvider(scenario: scenario)
    }

    @Test("What the user says wins over what the scenario assumed")
    func theCallersContextOverridesTheScenarios() async throws {
        // Given the short-sleep scenario, which ships `energyLevel: .low`
        let provider = makeSUT()
        let note = try #require(Note("Long meeting, short night."))

        // When it is asked with a different energy level and a note
        let snapshot = try await provider.snapshot(
            at: SyntheticScenarios.evaluationDate,
            calendar: SyntheticScenarios.calendar,
            context: DailyContext(energyLevel: .normal, note: note),
            constraints: .unrestricted
        )

        // Then both of the user's answers are what come back
        #expect(snapshot.context.energyLevel == .normal)
        #expect(snapshot.context.note == note)
        // And nothing Health-derived moved: the scenario's own reading and its label are intact
        #expect(snapshot.today.activeEnergy?.kilocalories == 410)
        #expect(snapshot.isSynthetic)
    }

    @Test("A field the user left alone keeps the scenario's own answer")
    func anUnansweredFieldFallsBackToTheScenario() async throws {
        // Given the same scenario
        let provider = makeSUT()

        // When it is asked with a craving only, leaving energy unanswered
        let snapshot = try await provider.snapshot(
            at: SyntheticScenarios.evaluationDate,
            calendar: SyntheticScenarios.calendar,
            context: DailyContext(craving: .tacos),
            constraints: .unrestricted
        )

        // Then the craving is the user's and the energy level is still the scenario's deliberate
        // `.low` — a replace rather than a merge would have erased what the scenario demonstrates
        #expect(snapshot.context.craving == .tacos)
        #expect(snapshot.context.energyLevel == .low)
    }

    @Test("The caller's constraints are the ones the snapshot carries")
    func theCallersConstraintsAreUsed() async throws {
        // Given a scenario that declares no constraints of its own
        let provider = makeSUT(SyntheticScenarios.typicalDay)
        let constraints = DietaryConstraints(profile: .vegetarian, excludedIngredientIDs: ["ingredient.olive"])

        // When it is asked on behalf of someone with a profile and an exclusion
        let snapshot = try await provider.snapshot(
            at: SyntheticScenarios.evaluationDate,
            calendar: SyntheticScenarios.calendar,
            context: .empty,
            constraints: constraints
        )

        // Then the stored preferences are what the evidence records, so the dish pick and the
        // saved case agree about what the user will eat
        #expect(snapshot.constraints == constraints)
    }
}
