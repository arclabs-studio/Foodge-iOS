//
//  EvidenceSnapshot.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Everything one evaluation is allowed to look at, frozen at a fixed instant.
///
/// The snapshot is the whole contract between the Health layer and the verdict engine: the engine
/// reads nothing else, which is what makes a verdict reproducible from a saved case.
struct EvidenceSnapshot: Hashable, Codable, Sendable {
    /// The instant the evaluation is for. Everything else is measured against it.
    let evaluatedAt: Date
    /// The time zone the local day boundaries were computed in, stored so a case reopened after
    /// travel still explains itself in the terms it was decided in.
    let timeZoneIdentifier: String
    /// Today's readings, accumulated up to ``evaluatedAt``.
    let today: HealthAggregates
    /// The previous completed days, each cut at the same local clock time as ``evaluatedAt``.
    let history: [DailyActivityObservation]
    let availability: EvidenceAvailability
    let context: DailyContext
    let constraints: DietaryConstraints
    /// Whether the user has confirmed the recorded days reflect their usual days.
    ///
    /// `nil` means they have not been asked yet, which is different from having said no.
    let trackingRepresentative: Bool?
    /// True when this snapshot is a labelled demonstration scenario rather than real data.
    let isSynthetic: Bool

    init(
        evaluatedAt: Date,
        timeZoneIdentifier: String,
        today: HealthAggregates,
        history: [DailyActivityObservation],
        availability: EvidenceAvailability,
        context: DailyContext = .empty,
        constraints: DietaryConstraints = .unrestricted,
        trackingRepresentative: Bool? = nil,
        isSynthetic: Bool = false
    ) {
        self.evaluatedAt = evaluatedAt
        self.timeZoneIdentifier = timeZoneIdentifier
        self.today = today
        self.history = history
        self.availability = availability
        self.context = context
        self.constraints = constraints
        self.trackingRepresentative = trackingRepresentative
        self.isSynthetic = isSynthetic
    }
}
