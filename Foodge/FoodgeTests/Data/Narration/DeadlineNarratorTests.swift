//
//  DeadlineNarratorTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 23/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The spec's timeout scenario, against production code. The budget here is milliseconds rather
/// than the shipped eight seconds — the rule under test is "the budget is enforced and the loser
/// is cancelled", which is independent of its value.
@Suite("Deadline narrator", .tags(.unit, .critical))
struct DeadlineNarratorTests {

    private static let budget = Duration.milliseconds(100)

    private func makeDecision() -> VerdictDecision {
        VerdictDecision(
            category: .balanced,
            basis: .provisional,
            reasonCodes: [.checkInSkipped],
            isProvisional: true,
            ruleVersion: CheatMealAllowanceRule.ruleVersion
        )
    }

    @Test("A narrator that answers inside the budget is passed straight through")
    func fastNarratorPassesThrough() async {
        // Given a narrator that answers immediately
        let sut = DeadlineNarrator(budget: Self.budget, wrapped: ImmediateNarrator(scripted: "The court approves."))

        // When a flourish is requested
        let text = await sut.flourish(for: makeDecision(), dishName: "Pesto pasta", note: nil)

        // Then the budget changed nothing about the answer
        #expect(text == "The court approves.")
    }

    @Test("A narrator that suspends but finishes inside the budget still gets to answer")
    func aSuspendingNarratorInsideTheBudgetStillAnswers() async {
        // Given a narrator that genuinely suspends — a fifth of the budget, with a real
        // cancellation point, exactly where a model call would have one
        let slow = SlowNarrator(delay: Self.budget / 5, scripted: "The court deliberated briefly.")
        let sut = DeadlineNarrator(budget: Self.budget, wrapped: slow)

        // When a flourish is requested
        let text = await sut.flourish(for: makeDecision(), dishName: "Pesto pasta", note: nil)

        // Then it answers, and it was never cancelled. This is what pins `cancelAll()` to *after*
        // `group.next()`: an implementation that cancelled as soon as the children were added
        // would still return nil here, and would still look correct to the timeout test.
        #expect(text == "The court deliberated briefly.")
        #expect(await slow.observedCancellation == false)
    }

    @Test("A narrator that overruns the budget produces nothing, and does not hold the caller")
    func slowNarratorTimesOut() async {
        // Given a narrator that would take far longer than the budget allows
        let slow = SlowNarrator(delay: .seconds(10))
        let sut = DeadlineNarrator(budget: Self.budget, wrapped: slow)

        // When a flourish is requested, timed on a clock the SUT has no access to
        let clock = ContinuousClock()
        let start = clock.now
        let text = await sut.flourish(for: makeDecision(), dishName: "Pesto pasta", note: nil)
        let elapsed = clock.now - start

        // Then nothing came back, and the caller waited about the budget rather than the delay
        #expect(text == nil)
        #expect(elapsed < .seconds(2), "Waited \(elapsed), which is the narrator's delay, not the budget")
    }

    @Test("The overrunning narrator is actually cancelled, not abandoned still running")
    func slowNarratorIsCancelled() async {
        // Given the same overrunning narrator
        let slow = SlowNarrator(delay: .seconds(10))
        let sut = DeadlineNarrator(budget: Self.budget, wrapped: slow)

        // When the budget expires
        _ = await sut.flourish(for: makeDecision(), dishName: "Pesto pasta", note: nil)

        // Then the narrator observed the cancellation. Without this, the timeout test alone would
        // pass against an implementation that leaks a running generation on every timeout.
        #expect(await slow.observedCancellation)
    }
}

// MARK: - Fixtures

/// Answers at once. Duplicated per suite, per this codebase's own convention.
private struct ImmediateNarrator: VerdictNarrator {
    let scripted: String?

    func flourish(for _: VerdictDecision, dishName _: String, note _: Note?) async -> String? {
        scripted
    }
}

/// Suspends for a given delay before answering, and records whether it was cancelled while
/// waiting — the seam both the timeout and the "it got its budget" assertions read.
private actor SlowNarrator: VerdictNarrator {
    private let delay: Duration
    private let scripted: String
    private(set) var observedCancellation = false

    init(delay: Duration, scripted: String = "Too late to matter.") {
        self.delay = delay
        self.scripted = scripted
    }

    func flourish(for _: VerdictDecision, dishName _: String, note _: Note?) async -> String? {
        do {
            try await Task.sleep(for: delay, clock: .continuous)
        } catch {
            observedCancellation = true
            return nil
        }
        return scripted
    }
}
