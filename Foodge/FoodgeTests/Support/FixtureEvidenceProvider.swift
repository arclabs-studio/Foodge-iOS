//
//  FixtureEvidenceProvider.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
@testable import Foodge

/// Returns a scripted snapshot, and remembers exactly what it was asked for.
///
/// Recording the `date` and `calendar` is the point: it is the only way to prove the ViewModel
/// passed the injected clock through rather than reaching for `Date()` or `Calendar.current`,
/// neither of which would fail a test that only checked the resulting state.
actor FixtureEvidenceProvider: HealthEvidenceProvider {
    private let result: Result<EvidenceSnapshot, any Error>
    private(set) var callCount = 0
    private(set) var receivedDates: [Date] = []
    private(set) var receivedCalendars: [Calendar] = []
    private(set) var receivedConstraints: [DietaryConstraints] = []

    init(snapshot: EvidenceSnapshot) {
        result = .success(snapshot)
    }

    init(failure: any Error) {
        result = .failure(failure)
    }

    func snapshot(
        at date: Date,
        calendar: Calendar,
        context: DailyContext,
        constraints: DietaryConstraints
    ) async throws -> EvidenceSnapshot {
        callCount += 1
        receivedDates.append(date)
        receivedCalendars.append(calendar)
        receivedConstraints.append(constraints)
        return try result.get()
    }
}
