//
//  VerdictRevealTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 10/10/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The reveal's own state machine — which phase is showing, whether the confetti is out, how often
/// the stamp has landed — separate from the question of whether a reveal plays at all, which is
/// `TodayViewModel.claimReveal()`'s and is pinned in `TodayRevealViewModelTests`.
///
/// Everything here runs the real `play(motion:)` with its real `Task.sleep` delays, so a full play
/// takes about a second. There is no injected clock to fake them: the delays are the choreography,
/// and a test that skipped them would not be exercising it.
///
/// What a test can observe is the state a play ends in, and that is deliberate. The phases in
/// between are visible for a few hundred milliseconds each, and asserting on one would be a race
/// against the clock rather than a statement about behaviour.
@Suite("Verdict reveal", .tags(.unit))
@MainActor
struct VerdictRevealTests {
    private func makeSUT() -> VerdictReveal {
        VerdictReveal()
    }

    @Test("A fresh reveal is settled, so a revisited verdict never renders a blank frame")
    func aFreshRevealIsSettled() {
        // Given a reveal nobody has played
        let sut = makeSUT()

        // Then it shows the verdict as it stands: settled, with no confetti and nothing landed
        #expect(sut.phase == .settled, "A reveal that has not played must show the verdict, not wait for it.")
        #expect(sut.stampLandings == 0, "No stamp has landed before a play.")
        #expect(sut.showsConfetti == false, "No confetti is out before a play.")
    }

    @Test("Without motion the reveal settles with the stamp landed and no confetti")
    func playingWithoutMotionNeverShowsConfetti() async {
        // Given Reduce Motion is on
        let sut = makeSUT()

        // When the reveal plays
        await sut.play(motion: false)

        // Then it ends settled, the stamp landed exactly once, and no confetti was ever shown —
        // the claim Reduce Motion rests on. `stampLandings == 1` is what separates a play that ran
        // from one that returned at once, since a fresh reveal is already settled.
        #expect(sut.phase == .settled)
        #expect(sut.stampLandings == 1, "The stamp should land once per play.")
        #expect(sut.showsConfetti == false, "Confetti must never show when motion is off.")
    }

    @Test("With motion the reveal settles with the stamp landed and the confetti out")
    func playingWithMotionShowsConfetti() async {
        // Given Reduce Motion is off
        let sut = makeSUT()

        // When the reveal plays
        await sut.play(motion: true)

        // Then it ends settled, the stamp landed exactly once, and the confetti came out at the dish
        #expect(sut.phase == .settled)
        #expect(sut.stampLandings == 1, "The stamp should land once per play.")
        #expect(sut.showsConfetti, "Confetti should show once the dish has popped, when motion is on.")
    }

    @Test("A reveal cancelled before it starts settles at once and shows nothing")
    func cancellingBeforeItStartsSettlesAtOnce() async {
        // Given a reveal whose task is cancelled before the first step runs — the screen went away
        let sut = makeSUT()
        let task = Task { await sut.play(motion: true) }
        task.cancel()

        // When the cancelled play is allowed to run
        await task.value

        // Then it left the verdict settled rather than stranded at the start of the reveal, and
        // neither the stamp nor the confetti happened
        #expect(sut.phase == .settled, "A cancelled reveal must settle so a return never finds it half-played.")
        #expect(sut.stampLandings == 0, "A reveal cancelled before it began must not land the stamp.")
        #expect(sut.showsConfetti == false, "A reveal cancelled before it began must not show confetti.")
    }
}
