//
//  FoundationModelsNarratorTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 23/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The spec's "model unavailable" scenario.
///
/// Everything past the availability gate — a real generation, a real refusal, a real guardrail
/// violation, the whole `.available` branch — is **device-only**: the simulator has no Apple
/// Intelligence at all. This suite proves the gate itself, and passes identically on both.
@Suite("Foundation Models narrator", .tags(.unit, .critical))
struct FoundationModelsNarratorTests {

    private func makeDecision() -> VerdictDecision {
        VerdictDecision(
            category: .balanced,
            basis: .provisional,
            reasonCodes: [.checkInSkipped],
            isProvisional: true,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    }

    @Test(
        "Every unavailable reason produces no flourish, without ever reaching the model",
        arguments: [
            NarrationAvailability.deviceNotEligible,
            .appleIntelligenceNotEnabled,
            .modelNotReady,
            .unavailableForAnotherReason,
        ]
    )
    func unavailableReasonsProduceNothing(availability: NarrationAvailability) async {
        // Given a narrator told the model is unavailable for this reason
        let sut = FoundationModelsNarrator(availability: { availability })

        // When a flourish is requested, timed on a clock the SUT has no access to
        let clock = ContinuousClock()
        let start = clock.now
        let text = await sut.flourish(for: makeDecision(), dishName: "Pesto pasta", note: nil)
        let elapsed = clock.now - start

        // Then nothing came back, and it came back at once. The elapsed-time assertion is what
        // distinguishes "gated out before any model work" from "ran, waited, and failed" — and it
        // holds on a device where a real generation would take seconds.
        #expect(text == nil)
        #expect(elapsed < .milliseconds(50), "Took \(elapsed), which is too long to be a gate")
    }
}
