//
//  ValidatingNarratorTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 23/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// Four of the spec's required narration scenarios — malformed output, invented numbers, a note
/// echoed back, and a refusal — are exercised here against **production code**: the real
/// `ValidatingNarrator` over the real `NarrationValidator`, with only the model itself scripted.
/// The simulator has no Apple Intelligence at all, so this decorator split is what makes them
/// testable off-device.
@Suite("Validating narrator", .tags(.unit, .critical))
struct ValidatingNarratorTests {

    // MARK: - Fixtures

    private func makeDecision(category: DinnerCategory = .balanced) -> VerdictDecision {
        VerdictDecision(
            category: category,
            basis: .provisional,
            reasonCodes: [.checkInSkipped],
            isProvisional: true,
            ruleVersion: DinnerCategoryRule.ruleVersion
        )
    }

    private func flourish(
        from scripted: String?,
        note: Note? = nil
    ) async -> (text: String?, narrator: ScriptedNarrator) {
        let narrator = ScriptedNarrator(scripted: scripted)
        let sut = ValidatingNarrator(wrapped: narrator)
        let text = await sut.flourish(for: makeDecision(), dishName: "Pesto pasta", note: note)
        return (text, narrator)
    }

    // MARK: - Acceptance

    @Test("A clean line passes through untouched")
    func aCleanLinePassesThrough() async {
        // Given a model that answers with a clean, in-voice line
        let result = await flourish(from: "The court finds the defence charming.")

        // Then it reaches the caller exactly as written
        #expect(result.text == "The court finds the defence charming.")
    }

    // MARK: - The four scripted failures

    @Test("Malformed output never reaches the caller")
    func malformedOutputIsRefused() async {
        // Given a model that answers with a preamble and a line break
        let result = await flourish(from: "Sure! Here's a flourish:\nThe court approves.")

        // Then nothing reaches the caller — the template will show instead
        #expect(result.text == nil)
    }

    @Test("An invented number never reaches the caller")
    func inventedNumbersAreRefused() async {
        // Given a model that invents a measurement the prompt never contained
        let result = await flourish(from: "You moved 8,000 steps, so the court is generous.")

        // Then nothing reaches the caller
        #expect(result.text == nil)
    }

    @Test("A note quoted back never reaches the caller")
    func echoedNotesAreRefused() async throws {
        // Given a note, and a model that quotes a long stretch of it back
        let note = try #require(Note("I had a rough meeting with the whole leadership team today"))
        let result = await flourish(
            from: "The court notes: a rough meeting with the whole leadership team.",
            note: note
        )

        // Then nothing reaches the caller — the output half of the injection defence
        #expect(result.text == nil)
    }

    @Test("A refusal is passed through as no flourish at all")
    func aRefusalProducesNoFlourish() async {
        // Given a model that produced nothing — a refusal, an unavailable model, a guardrail
        let result = await flourish(from: nil)

        // Then the caller gets nothing, and the validator was never asked to invent a substitute
        #expect(result.text == nil)
    }

    // MARK: - What the decorator must never do

    @Test("A scripted nil is never replaced with invented text")
    func nilIsNeverSubstituted() async {
        // Given a model that produced nothing
        let result = await flourish(from: nil)

        // Then the result is nil and the model was still asked exactly once — this fails if
        // anyone ever "helpfully" substitutes a template here, which decision 2 forbids: the
        // template renders at display time and is never persisted as model output
        #expect(result.text == nil)
        #expect(await result.narrator.callCount == 1)
    }

    @Test("A rejected line is not retried")
    func rejectionDoesNotRetry() async {
        // Given a model whose answer will be rejected
        let result = await flourish(from: "You earned this one.")

        // Then the model was asked exactly once — a retry loop would double the latency budget
        // for a decoration, and would show up here as a second call
        #expect(result.text == nil)
        #expect(await result.narrator.callCount == 1)
    }
}

// MARK: - Fixtures

/// Answers with one scripted result and counts how many times it was asked — the seam that makes
/// the model's side of the contract testable without a model. Duplicated per suite, per this
/// codebase's own convention.
private actor ScriptedNarrator: VerdictNarrator {
    private let scripted: String?
    private(set) var callCount = 0

    init(scripted: String?) {
        self.scripted = scripted
    }

    func flourish(for _: VerdictDecision, dishName _: String, note _: Note?) async -> String? {
        callCount += 1
        return scripted
    }
}
