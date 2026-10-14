//
//  JudgeReaction.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import Observation

/// What the tappable judge is doing: which quip it is showing, and how many times it has been
/// tapped (D146).
///
/// A component model rather than a screen's view model, because it belongs to the judge wherever
/// the judge appears. It reaches nothing — no rule, no dish, no store — so tapping the judge can
/// never change a verdict. The deck plays in declared order and wraps, so the same quip never
/// shows twice in a row, and every judge a screen creates starts from the first line.
@Observable
@MainActor
final class JudgeReaction {
    /// The line in the speech bubble; `nil` until the judge is first tapped.
    private(set) var quip: JudgeQuip?

    /// Every tap, counted. The judge's hop and haptic are triggered by this changing, so it moves
    /// on every tap — including the one that wraps the deck back to its first line.
    private(set) var taps = 0

    private let deck = JudgeQuip.allCases

    /// Shows the next quip and counts the tap. Returns the quip now showing, for the announcement.
    @discardableResult
    func tap() -> JudgeQuip {
        let next = deck[taps % deck.count]
        quip = next
        taps += 1
        return next
    }
}
