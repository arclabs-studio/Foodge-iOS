//
//  JudgeReactionTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 10/10/2026.
//

@testable import Foodge
import Foundation
import Testing

/// What the judge says when tapped (D146, WU-29-B), proven through the component model the hero
/// view reads: which quip is showing, and how many taps there have been.
///
/// `taps` is not a statistic. It is the trigger the view hands to `keyframeAnimator(trigger:)` and
/// `sensoryFeedback(_:trigger:)`, so a tap that does not move it plays no hop and no haptic — which
/// is why it has a test of its own rather than riding along inside the quip tests.
///
/// The oracle is the **declared case order of `JudgeQuip`**, read from `JudgeQuip.allCases`, and the
/// test's own arithmetic over the tap index. Nothing here calls a production helper to compute what
/// "next" means, so a rotation that was random, shuffled, offset by one or clamped at the end of the
/// deck cannot agree with it. Reordering the cases themselves is deliberately not a failure: the
/// declared order *is* the intended order.
@Suite("Judge reaction", .tags(.unit))
@MainActor
struct JudgeReactionTests {
    private func makeSUT() -> JudgeReaction {
        JudgeReaction()
    }

    @Test("A judge nobody has tapped has said nothing")
    func untouchedJudgeHasSaidNothing() {
        // Given a judge nobody has tapped
        let sut = makeSUT()

        // Then no quip is showing — the bubble must not open on a line the person never asked
        // for — and the animation and haptic trigger has not moved
        #expect(sut.quip == nil, "an untouched judge is already showing \(String(describing: sut.quip))")
        #expect(sut.taps == 0)
    }

    @Test("Taps walk the deck in declared order and wrap")
    func tapsWalkTheDeckInDeclaredOrderAndWrap() throws {
        // Given a fresh judge and the deck exactly as `JudgeQuip` declares it
        let sut = makeSUT()
        let deck = JudgeQuip.allCases
        try #require(!deck.isEmpty, "JudgeQuip declares no quips")

        // When the judge is tapped through two full decks and one tap beyond
        for tap in 1 ... (2 * deck.count + 1) {
            sut.tap()

            // Then the nth tap shows the quip declared at position (n - 1) modulo the deck size:
            // the first tap shows the first quip, and the tap after the last quip shows the first
            // again. Random choice, a shuffle, a first tap that skips quip 0 and a deck that
            // stops at its end each disagree with this somewhere along the walk.
            let shown = try #require(sut.quip, "tap \(tap) showed no quip")
            let expected = deck[(tap - 1) % deck.count]
            #expect(shown == expected, "tap \(tap) showed \(shown), but the declared order calls for \(expected)")
        }
    }

    @Test("A quip is never shown twice in a row")
    func aQuipIsNeverShownTwiceInARow() throws {
        // Given a fresh judge and a deck large enough for the property to mean anything — a deck
        // of one quip would have to repeat it
        let sut = makeSUT()
        let deckSize = JudgeQuip.allCases.count
        try #require(deckSize >= 2, "the deck holds \(deckSize) quip(s); no-repeat needs at least two")

        // When the judge is tapped through three full decks, crossing the wrap twice
        var previous: JudgeQuip?
        for tap in 1 ... (3 * deckSize) {
            sut.tap()

            // Then no tap shows the quip the previous tap showed — including the tap that wraps
            // from the last quip back to the first
            let shown = try #require(sut.quip, "tap \(tap) showed no quip")
            #expect(shown != previous, "tap \(tap) showed \(shown) again; the previous tap showed it too")
            previous = shown
        }
    }

    @Test("Every tap moves the trigger by exactly one, including the tap that wraps")
    func everyTapMovesTheTriggerByExactlyOne() {
        // Given a fresh judge
        let sut = makeSUT()
        let deckSize = JudgeQuip.allCases.count

        // When the judge is tapped through two full decks and one tap beyond
        for tap in 1 ... (2 * deckSize + 1) {
            sut.tap()

            // Then the trigger equals the number of taps so far. The taps that return to the first
            // quip are named, because a counter derived from the deck position would reset there
            // and the hop and haptic would silently stop playing.
            let isWrappingTap = tap > deckSize && (tap - 1) % deckSize == 0
            #expect(
                sut.taps == tap,
                "after tap \(tap)\(isWrappingTap ? " (the tap that wraps the deck)" : "") taps was \(sut.taps)"
            )
        }
    }
}
