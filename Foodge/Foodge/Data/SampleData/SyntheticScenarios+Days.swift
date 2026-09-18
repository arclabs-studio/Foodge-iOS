//
//  SyntheticScenarios+Days.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

extension SyntheticScenarios {
    /// The 14 completed local days before the evaluation, oldest first: 4–17 September 2026.
    static let historyDays: [Date] = (4...17).map { day in
        date(year: 2026, month: 9, day: day)
    }

    /// Active energy accumulated by 19:30 on each of those days. Median 400 kcal.
    static let typicalEnergyAtCutoff: [Double] = [
        340, 360, 370, 380, 390, 395, 400, 400, 410, 420, 430, 440, 450, 460
    ]

    /// Steps accumulated by 19:30 on each of those days. Median 8200.
    static let typicalStepsAtCutoff: [Double] = [
        7600, 7800, 7900, 8000, 8050, 8100, 8200, 8200, 8300, 8350, 8400, 8500, 8600, 8700
    ]

    /// The 14 completed local days before the daylight-saving evaluation: 15–28 March 2026.
    static let springForwardHistoryDays: [Date] = (15...28).map { day in
        date(year: 2026, month: 3, day: day)
    }

    /// Almost nothing is recorded by 03:10, which is the point of the scenario.
    static let springForwardEnergyAtCutoff: [Double] = Array(repeating: 20, count: 14)

    /// Pairs recorded values with their days.
    ///
    /// Shorter value arrays simply leave the remaining days missing, which is how a partly
    /// tracked fortnight actually looks.
    static func observations(
        days: [Date],
        energy: [Double?],
        steps: [Double?]
    ) -> [DailyActivityObservation] {
        days.enumerated().map { index, day in
            DailyActivityObservation(
                day: day,
                activeEnergyAtCutoff: index < energy.count ? energy[index] : nil,
                stepsAtCutoff: index < steps.count ? steps[index] : nil
            )
        }
    }

    /// The fully tracked fortnight: energy and steps on every day.
    static var fullyTrackedHistory: [DailyActivityObservation] {
        observations(
            days: historyDays,
            energy: typicalEnergyAtCutoff,
            steps: typicalStepsAtCutoff
        )
    }
}
