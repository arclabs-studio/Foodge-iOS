//
//  DemonstrationEvidenceProvider.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// Serves one labelled demonstration scenario instead of reading Health.
///
/// Unlike `PreviewEvidence`, which returns its scripted snapshot verbatim, this **carries the
/// caller's ``DailyContext`` through** (D101). What the user answers on stage has to reach the
/// recorded evidence, and a verbatim return would silently delete the check-in from the
/// walkthrough while still looking like it worked.
///
/// It used to merge the caller's context over the scenario's. With D138 a context is one field —
/// the self-report — no scenario declares one, and a merge over an always-empty base is a
/// no-op dressed as a rule.
///
/// Everything Health-derived comes from the scenario untouched, `isSynthetic` included — that flag
/// is what makes every screen print "Demonstration data" instead of "From Health".
struct DemonstrationEvidenceProvider: HealthEvidenceProvider {
    let scenario: SyntheticScenario

    /// `date` and `calendar` are deliberately ignored: the session's clock is the scenario's own
    /// ``FixedClock``, so they already carry the scenario's instant, and re-dating the snapshot
    /// would break every hand-computed window the scenario's doc comment promises.
    func snapshot(
        at _: Date,
        calendar _: Calendar,
        context: DailyContext,
        constraints: DietaryConstraints
    ) async throws -> EvidenceSnapshot {
        let scripted = scenario.snapshot
        return EvidenceSnapshot(
            evaluatedAt: scripted.evaluatedAt,
            timeZoneIdentifier: scripted.timeZoneIdentifier,
            today: scripted.today,
            availability: scripted.availability,
            context: context,
            constraints: constraints,
            // The scenario's own questionnaire and body basics are carried through: they are the
            // only way `estimatedIntake` and `estimatedResting` can demonstrate an estimated
            // component, and a live snapshot leaves both `nil`.
            intake: scripted.intake,
            body: scripted.body,
            isSynthetic: scripted.isSynthetic
        )
    }
}
