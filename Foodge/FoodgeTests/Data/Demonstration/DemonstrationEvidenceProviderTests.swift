//
//  DemonstrationEvidenceProviderTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The rule that keeps the walkthrough's check-in step alive (D101).
///
/// The oracle is the scenario's own declaration in `SyntheticScenarios` — `shortSleep` ships 400
/// kcal active and no context of its own — against what the provider hands back when asked with
/// an answer of the caller's.
@Suite("Demonstration evidence provider", .tags(.unit))
struct DemonstrationEvidenceProviderTests {
    private func makeSUT(
        _ scenario: SyntheticScenario = SyntheticScenarios.shortSleep
    ) -> DemonstrationEvidenceProvider {
        DemonstrationEvidenceProvider(scenario: scenario)
    }

    @Test("What the user answers is what the recorded evidence carries")
    func theCallersContextReachesTheSnapshot() async throws {
        // Given the short-sleep scenario, which declares no context of its own
        let provider = makeSUT()

        // When it is asked on behalf of someone who reported a quieter day than usual
        let snapshot = try await provider.snapshot(
            at: SyntheticScenarios.evaluationDate,
            calendar: SyntheticScenarios.calendar,
            context: DailyContext(selfReportedActivity: .less),
            constraints: .unrestricted
        )

        // Then the answer is what comes back — a provider returning `scenario.snapshot` verbatim
        // would drop it, which is the defect this test exists for
        #expect(snapshot.context.selfReportedActivity == .less)
        // And nothing Health-derived moved: the scenario's own reading and its label are intact
        #expect(snapshot.today.activeEnergy?.kilocalories == 400)
        #expect(snapshot.isSynthetic)
    }

    @Test("The caller's constraints are the ones the snapshot carries")
    func theCallersConstraintsAreUsed() async throws {
        // Given a scenario that declares no constraints of its own
        let provider = makeSUT(SyntheticScenarios.modestAllowance)
        let constraints = DietaryConstraints(profile: .vegetarian)

        // When it is asked on behalf of someone with a diet profile
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
