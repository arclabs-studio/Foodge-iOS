//
//  ValidatingNarrator.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import Foundation
import OSLog

/// Puts ``NarrationValidator`` between the model and everything else.
///
/// Lives in Data because it adapts an untrusted external source and logs; the rules themselves are
/// a product fact and stay in Domain. The specific ``NarrationRejection`` is collapsed to `nil`
/// here, at the layer boundary, so the reviewed `VerdictNarrator` contract is unchanged and no
/// caller can learn — or show — that a line was refused.
///
/// The wrapped narrator is asked **exactly once**. There is deliberately no retry: a second
/// generation would double the latency budget for a decoration, and a model that invented a number
/// once is not more trustworthy on the next attempt.
struct ValidatingNarrator: VerdictNarrator {
    let wrapped: any VerdictNarrator

    func flourish(
        for decision: VerdictDecision,
        dishName: String,
        note: Note?
    ) async -> String? {
        guard let candidate = await wrapped.flourish(for: decision, dishName: dishName, note: note) else {
            return nil
        }

        switch NarrationValidator.validate(candidate, note: note) {
        case let .accepted(text):
            return text
        case let .rejected(rejection):
            // The rule that fired, never the candidate — device tuning needs to know which rule is
            // eating real generations, and nothing more than that.
            NarrationLog.logger.info("NARRATION rejected=\(rejection.logLabel, privacy: .public)")
            return nil
        }
    }
}
