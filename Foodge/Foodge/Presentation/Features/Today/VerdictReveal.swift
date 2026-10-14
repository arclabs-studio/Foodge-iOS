//
//  VerdictReveal.swift
//  Foodge
//
//  Created by ARC Labs Studio on 10/10/2026.
//

import Observation
import SwiftUI

/// The verdict screen's reveal, step by step (D147): which phase is showing, whether the confetti is
/// out, and how many reveals have reached the stamp — the haptic's trigger: heavy as the slammed
/// stamp touches down, light as the faded verdict appears under Reduce Motion.
///
/// A component model, like `JudgeReaction`: it knows nothing of the verdict itself. Whether a reveal
/// plays at all is `TodayViewModel.claimReveal()`'s call. It starts settled, so a verdict revisited
/// in a fresh screen shows at once rather than a blank frame first.
@Observable
@MainActor
final class VerdictReveal {
    private(set) var phase: RevealPhase = .settled
    private(set) var showsConfetti = false
    private(set) var stampLandings = 0

    /// Shows the verdict as it stands, with nothing animated.
    func settle() {
        phase = .settled
    }

    /// Plays stamp → dish (with confetti) → cards, then settles. The stamp's haptic plays when the
    /// stamp touches down, not when it starts to fall.
    ///
    /// With motion off there is nothing to wait for: the verdict settles at once, each view fading
    /// itself in, with one landing for the haptic and no confetti — the HIG's "don't make people
    /// wait" for a sequence whose point was the movement.
    ///
    /// Cancelled — the screen went away — it settles at once, so a return never finds a
    /// half-revealed verdict.
    func play(motion: Bool) async {
        showsConfetti = false
        guard motion else {
            stampLandings += 1
            settle()
            return
        }
        phase = .waiting
        do {
            for step in RevealPhase.steps {
                try await Task.sleep(for: step.delay)
                withAnimation(step.springAnimation) {
                    phase = step
                }
                if step == .stamp {
                    try await Task.sleep(for: RevealPhase.stampTouchdown)
                    stampLandings += 1
                }
                if step == .dish {
                    showsConfetti = true
                }
            }
        } catch {
            settle()
            return
        }
        settle()
    }
}
