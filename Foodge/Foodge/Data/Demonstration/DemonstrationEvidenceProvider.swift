//
//  DemonstrationEvidenceProvider.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// Serves one labelled demonstration scenario instead of reading Health.
///
/// Unlike `PreviewEvidence`, which returns its scripted snapshot verbatim, this **merges the
/// caller's ``DailyContext`` over the scenario's** (D101). `TodayViewModel.finish()` feeds
/// `snapshot.context` — not the caller's — into `DishSelection`, and `NarrationPrompt` reads the
/// note from the same place, so a verbatim return would silently delete the "add context" step
/// from the walkthrough while still looking like it worked.
///
/// Merge rather than replace, because a scenario's own context is part of what it demonstrates:
/// `shortSleep` ships `energyLevel: .low` deliberately, and a replace would erase it the moment
/// the user set any other field.
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
            context: context.merged(over: scripted.context),
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

private extension DailyContext {
    /// This context laid over `base`: each field this one answers wins, and `base` fills the rest.
    func merged(over base: DailyContext) -> DailyContext {
        DailyContext(
            dinnerTime: dinnerTime ?? base.dinnerTime,
            energyLevel: energyLevel ?? base.energyLevel,
            craving: craving ?? base.craving,
            selfReportedActivity: selfReportedActivity ?? base.selfReportedActivity,
            note: note ?? base.note
        )
    }
}
