//
//  DeadlineNarrator.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import Foundation
import OSLog

/// Gives the wrapped narrator a hard time budget, and cancels it when the budget expires.
///
/// A flourish is decoration: the verdict is already on screen and the template is already showing,
/// so a slow generation must never keep the user waiting, and a timed-out one must not keep
/// running in the background either.
///
/// Structured throughout — two children in a task group, no stored `Task`, no GCD, no timer.
///
/// The budget is measured on a **continuous** clock, which keeps running while the system sleeps.
/// That is the conservative choice: a suspending clock would stop counting there and hand a
/// generation more wall-clock time than the budget names. It does not make the deadline fire while
/// the process itself is suspended — nothing runs then, whatever the clock.
struct DeadlineNarrator: VerdictNarrator {
    let budget: Duration
    let wrapped: any VerdictNarrator

    /// Why the race finished.
    ///
    /// Two children both returning `String?` would make a timeout and a genuine `nil`
    /// indistinguishable, costing both the log signal and any test that can tell them apart.
    private enum Outcome: Sendable {
        case produced(String?)
        case expired
    }

    func flourish(
        for decision: VerdictDecision,
        dishName: String,
        note: Note?
    ) async -> String? {
        await withTaskGroup(of: Outcome.self) { group in
            group.addTask {
                .produced(await wrapped.flourish(for: decision, dishName: dishName, note: note))
            }
            group.addTask {
                // A cancelled sleep throws; the value it would have returned is then discarded
                // along with the rest of the group, so swallowing the error here changes nothing.
                try? await Task.sleep(for: budget, clock: .continuous)
                return .expired
            }

            // Awaited *before* cancelling, so the wrapped narrator gets the whole budget to race
            // in rather than being cancelled the moment it starts.
            let first = await group.next()
            // Flags whichever child is still running — including the model call. Swift
            // cancellation is cooperative, so this stops a timed-out generation only insofar as
            // the wrapped narrator observes cancellation at its own suspension points; every
            // conformer in this chain does, and one that did not would hold the caller past the
            // budget while the group waits for it.
            group.cancelAll()

            switch first {
            case let .produced(text):
                return text
            case .expired:
                NarrationLog.logger.info("NARRATION outcome=expired")
                return nil
            case nil:
                // Unreachable: the group always has two children, so the first `next()` has
                // something to return. Never force-unwrapped regardless.
                return nil
            }
        }
    }
}
