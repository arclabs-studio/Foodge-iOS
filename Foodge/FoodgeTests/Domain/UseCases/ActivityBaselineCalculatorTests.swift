//
//  ActivityBaselineCalculatorTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// "Your recorded pattern": at least seven usable observations, a strictly positive median,
/// energy preferred over steps, and nothing at all when the user says the fortnight is not
/// representative.
///
/// Every median below is computed by hand from the sorted values, using the mean of the middle
/// pair when the count is even.
@Suite("Activity baseline calculator", .tags(.unit, .domain, .critical))
struct ActivityBaselineCalculatorTests {

    // MARK: - Fixtures

    private func makeObservations(
        energy: [Double?],
        steps: [Double?] = []
    ) -> [DailyActivityObservation] {
        let count = max(energy.count, steps.count)
        return (0..<count).map { index in
            DailyActivityObservation(
                day: TestCalendar.date(2026, 9, 4 + index),
                activeEnergyAtCutoff: index < energy.count ? energy[index] : nil,
                stepsAtCutoff: index < steps.count ? steps[index] : nil
            )
        }
    }

    // MARK: - Median

    @Test("A full fortnight of energy gives the mean of the middle pair")
    func aFullFortnightUsesTheMedian() throws {
        // Given 14 recorded days whose sorted middle pair is 390 and 400
        let observations = makeObservations(
            energy: [310, 420, 380, 510, 290, 450, 400, 360, 470, 330, 390, 440, 350, 410]
        )

        // When the baseline is calculated
        let result = ActivityBaselineCalculator.baseline(
            from: observations,
            trackingRepresentative: true
        )

        // Then the median is 395 over all 14 observations, from energy, and the pattern reports
        // the span of days it was actually built from — 4 to 17 September
        let baseline = try result.get()
        #expect(baseline.median == 395)
        #expect(baseline.observationCount == 14)
        #expect(baseline.metric == .activeEnergy)
        #expect(baseline.window.start == TestCalendar.date(2026, 9, 4))
        #expect(baseline.window.end == TestCalendar.date(2026, 9, 17))
    }

    @Test("Seven recorded days and seven blank ones still qualify")
    func theMinimumNumberOfObservationsIsSeven() throws {
        // Given exactly seven recorded days, 300 to 420 in steps of 20, and seven with nothing
        let recorded: [Double?] = [300, 320, 340, 360, 380, 400, 420]
        let observations = makeObservations(energy: recorded + Array(repeating: nil, count: 7))

        // When the baseline is calculated
        let result = ActivityBaselineCalculator.baseline(
            from: observations,
            trackingRepresentative: true
        )

        // Then the missing days are ignored rather than counted as zero, and the median is the
        // middle of the seven that exist
        let baseline = try result.get()
        #expect(baseline.median == 360)
        #expect(baseline.observationCount == 7)
    }

    @Test("Nine recorded days out of fourteen count as nine")
    func onlyRecordedDaysAreCounted() throws {
        // Given nine recorded days and five blank ones
        let recorded: [Double?] = [300, 320, 340, 360, 380, 400, 420, 440, 460]
        let observations = makeObservations(energy: recorded + Array(repeating: nil, count: 5))

        // When the baseline is calculated
        let result = ActivityBaselineCalculator.baseline(
            from: observations,
            trackingRepresentative: true
        )

        // Then the count reports the nine real observations
        let baseline = try result.get()
        #expect(baseline.observationCount == 9)
        #expect(baseline.median == 380)
    }

    // MARK: - Refusals

    @Test("Six recorded days are not enough to compare against")
    func tooFewObservationsProduceNoBaseline() {
        // Given six recorded days
        let observations = makeObservations(energy: [300, 320, 340, 360, 380, 400])

        // When the baseline is calculated
        let result = ActivityBaselineCalculator.baseline(
            from: observations,
            trackingRepresentative: true
        )

        // Then it refuses, and says how many it found
        #expect(result == .failure(.insufficientHistory(found: 6)))
    }

    @Test("A zero median is refused rather than used as a divisor")
    func aZeroMedianProducesNoBaseline() {
        // Given eight days, seven of them recorded as zero
        let observations = makeObservations(energy: Array(repeating: 0, count: 7) + [10])

        // When the baseline is calculated
        let result = ActivityBaselineCalculator.baseline(
            from: observations,
            trackingRepresentative: true
        )

        // Then it refuses: a ratio against zero would be meaningless
        #expect(result == .failure(.zeroMedian))
    }

    @Test("A fortnight the user called unrepresentative is not used at all")
    func unrepresentativeTrackingProducesNoBaseline() {
        // Given a complete, perfectly usable fortnight
        let observations = makeObservations(
            energy: [310, 420, 380, 510, 290, 450, 400, 360, 470, 330, 390, 440, 350, 410]
        )

        // When the user has said those days do not represent their usual days
        let result = ActivityBaselineCalculator.baseline(
            from: observations,
            trackingRepresentative: false
        )

        // Then the comparison is abandoned, however good the data looks
        #expect(result == .failure(.markedUnrepresentative))
    }

    // MARK: - Hygiene and fallback

    @Test("Values that are not finite, or are negative, are discarded")
    func invalidValuesAreDiscarded() throws {
        // Given a not-a-number, a negative day, an infinity and seven honest 100s. A recorded
        // zero is NOT invalid: the brief filters on nonnegative, and zeros have to survive this
        // filter for `aZeroMedianProducesNoBaseline` to be able to reach the zero-median branch.
        let observations = makeObservations(
            energy: [.nan, -5, .infinity] + Array(repeating: 100, count: 7)
        )

        // When the baseline is calculated
        let result = ActivityBaselineCalculator.baseline(
            from: observations,
            trackingRepresentative: true
        )

        // Then only the seven usable values survive
        let baseline = try result.get()
        #expect(baseline.observationCount == 7)
        #expect(baseline.median == 100)
    }

    @Test("A zero energy median hands the comparison to steps rather than refusing")
    func aZeroEnergyMedianFallsBackToSteps() throws {
        // Given eight recorded energy days whose median is zero, but seven usable step days
        let observations = makeObservations(
            energy: Array(repeating: 0, count: 7) + [10],
            steps: [8000, 8200, 7900, 8500, 8100, 8300, 8400]
        )

        // When the baseline is calculated
        let result = ActivityBaselineCalculator.baseline(
            from: observations,
            trackingRepresentative: true
        )

        // Then energy "cannot supply a usable comparison" in the brief's sense, so steps take
        // over instead of the whole pattern being abandoned
        let baseline = try result.get()
        #expect(baseline.metric == .steps)
        #expect(baseline.median == 8200)
    }

    @Test("Steps take over when energy cannot supply a comparison")
    func stepsAreTheFallbackMetric() throws {
        // Given energy on only three days, but steps on seven
        let observations = makeObservations(
            energy: [410, 430, 390],
            steps: [8000, 8200, 7900, 8500, 8100, 8300, 8400]
        )

        // When the baseline is calculated
        let result = ActivityBaselineCalculator.baseline(
            from: observations,
            trackingRepresentative: true
        )

        // Then the pattern is built from steps, whose middle value is 8200
        let baseline = try result.get()
        #expect(baseline.metric == .steps)
        #expect(baseline.median == 8200)
        #expect(baseline.observationCount == 7)
    }
}
