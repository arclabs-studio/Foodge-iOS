//
//  EvidenceSnapshot.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Everything one evaluation is allowed to look at, frozen at a fixed instant.
///
/// The snapshot is the whole contract between the Health layer and the verdict rule: the rule reads
/// nothing else, which is what makes a verdict reproducible from a saved case.
///
/// It carries no history since D111: the verdict compares nothing against previous days. What it
/// gained instead is the two things the allowance needs when Health cannot supply them — the body
/// basics behind an estimated resting figure, and the questionnaire behind an estimated intake.
struct EvidenceSnapshot: Hashable, Codable, Sendable {
    /// The instant the evaluation is for. Everything else is measured against it.
    let evaluatedAt: Date
    /// The time zone the local day boundaries were computed in, stored so a case reopened after
    /// travel still explains itself in the terms it was decided in.
    let timeZoneIdentifier: String
    /// Today's readings, accumulated up to ``evaluatedAt``.
    let today: HealthAggregates
    let availability: EvidenceAvailability
    let context: DailyContext
    let constraints: DietaryConstraints
    /// What the user said they have eaten so far, or `nil` when they were not asked.
    ///
    /// Only ever consulted when Health has no `dietaryEnergy` — a recorded total replaces an
    /// estimate, never adds to it.
    let intake: IntakeQuestionnaire?
    /// The body basics behind an estimated resting figure, or `nil` when none are stored.
    let body: BodyBasics?
    /// True when this snapshot is a labelled demonstration scenario rather than real data.
    let isSynthetic: Bool

    init(
        evaluatedAt: Date,
        timeZoneIdentifier: String,
        today: HealthAggregates,
        availability: EvidenceAvailability,
        context: DailyContext = .empty,
        constraints: DietaryConstraints = .unrestricted,
        intake: IntakeQuestionnaire? = nil,
        body: BodyBasics? = nil,
        isSynthetic: Bool = false
    ) {
        self.evaluatedAt = evaluatedAt
        self.timeZoneIdentifier = timeZoneIdentifier
        self.today = today
        self.availability = availability
        self.context = context
        self.constraints = constraints
        self.intake = intake
        self.body = body
        self.isSynthetic = isSynthetic
    }
}

extension EvidenceSnapshot {
    /// The same snapshot with the estimate inputs the rule actually used recorded on it.
    ///
    /// The Health layer cannot supply either one — body basics are a stored preference (D117) and
    /// the questionnaire is per-day user input — so the view model attaches them before anything is
    /// saved. Recording them is what lets a reopened case explain an estimated figure instead of
    /// showing a number with no stated origin.
    func attaching(intake: IntakeQuestionnaire?, body: BodyBasics?) -> EvidenceSnapshot {
        EvidenceSnapshot(
            evaluatedAt: evaluatedAt,
            timeZoneIdentifier: timeZoneIdentifier,
            today: today,
            availability: availability,
            context: context,
            constraints: constraints,
            intake: intake,
            body: body,
            isSynthetic: isSynthetic
        )
    }

    /// The same snapshot with the user's own account of the day recorded in its context.
    ///
    /// `DailyContext.selfReportedActivity` existed from the start and nothing ever wrote it: a
    /// self-reported verdict saved the report in `CategoryBasis` but not in the evidence beside it,
    /// so a reopened case could not say what had been asked. Found during the rebuild's
    /// exploration and fixed here.
    func recordingSelfReport(_ report: SelfReportedActivity?) -> EvidenceSnapshot {
        EvidenceSnapshot(
            evaluatedAt: evaluatedAt,
            timeZoneIdentifier: timeZoneIdentifier,
            today: today,
            availability: availability,
            context: DailyContext(
                dinnerTime: context.dinnerTime,
                energyLevel: context.energyLevel,
                craving: context.craving,
                selfReportedActivity: report,
                note: context.note
            ),
            constraints: constraints,
            intake: intake,
            body: body,
            isSynthetic: isSynthetic
        )
    }
}
