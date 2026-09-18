//
//  DinnerCategoryRuleTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// The category decision table from the product brief, pinned at and around both thresholds.
///
/// Every expectation here is computed by hand against a recorded pattern of 400 kcal:
/// 1.25 × 400 = 500 and 0.75 × 400 = 300, both of which stay balanced because the brief makes
/// the band inclusive at each end.
@Suite("Dinner category rule", .tags(.unit, .domain, .critical))
struct DinnerCategoryRuleTests {

    // MARK: - Fixtures

    private static let median = 400.0

    private func makeBaseline(
        median: Double = DinnerCategoryRuleTests.median,
        metric: ActivityMetric = .activeEnergy,
        observationCount: Int = 14
    ) -> ActivityBaseline {
        ActivityBaseline(
            metric: metric,
            median: median,
            observationCount: observationCount,
            window: TestCalendar.fortnight
        )
    }

    // MARK: - Recorded comparison

    @Test("501 kcal against a 400 kcal pattern is a treat")
    func aDayAboveTheUpperThresholdIsATreat() throws {
        // Given a fully tracked fortnight with a 400 kcal median
        let baseline = makeBaseline()

        // When today reaches 501 kcal, a ratio of 1.2525
        let outcome = DinnerCategoryRule.decide(
            today: 501,
            baseline: baseline,
            trackingRepresentative: true,
            selfReport: nil
        )

        // Then the judge rules a treat, on the recorded evidence
        let decision = try #require(outcome.decision)
        #expect(decision.category == .treat)
        #expect(decision.isProvisional == false)
        #expect(decision.reasonCodes.contains(.aboveRecordedPattern))
    }

    @Test("Exactly 125% of the pattern is still balanced")
    func theUpperThresholdIsInclusive() throws {
        // Given the same 400 kcal pattern
        let baseline = makeBaseline()

        // When today reaches exactly 500 kcal, a ratio of 1.25
        let outcome = DinnerCategoryRule.decide(
            today: 500,
            baseline: baseline,
            trackingRepresentative: true,
            selfReport: nil
        )

        // Then the boundary belongs to balanced, not to treat
        let decision = try #require(outcome.decision)
        #expect(decision.category == .balanced)
        #expect(decision.reasonCodes.contains(.withinRecordedPattern))
    }

    @Test("Exactly 75% of the pattern is still balanced")
    func theLowerThresholdIsInclusive() throws {
        // Given the same 400 kcal pattern
        let baseline = makeBaseline()

        // When today reaches exactly 300 kcal, a ratio of 0.75
        let outcome = DinnerCategoryRule.decide(
            today: 300,
            baseline: baseline,
            trackingRepresentative: true,
            selfReport: nil
        )

        // Then the boundary belongs to balanced, not to light
        let decision = try #require(outcome.decision)
        #expect(decision.category == .balanced)
        #expect(decision.reasonCodes.contains(.withinRecordedPattern))
    }

    @Test("299 kcal is light once the user confirms the tracking reflects the day")
    func aConfirmedQuietDayIsLight() throws {
        // Given the same 400 kcal pattern, and a user who confirmed their tracking
        let baseline = makeBaseline()

        // When today reaches 299 kcal, a ratio of 0.7475
        let outcome = DinnerCategoryRule.decide(
            today: 299,
            baseline: baseline,
            trackingRepresentative: true,
            selfReport: nil
        )

        // Then the judge rules light
        let decision = try #require(outcome.decision)
        #expect(decision.category == .light)
        #expect(decision.reasonCodes.contains(.belowRecordedPattern))
    }

    @Test("A quiet day with unconfirmed tracking asks before ruling")
    func anUnconfirmedQuietDayAsksFirst() {
        // Given a 400 kcal pattern and a user who has not been asked about their tracking
        let baseline = makeBaseline()

        // When today reaches the same 299 kcal
        let outcome = DinnerCategoryRule.decide(
            today: 299,
            baseline: baseline,
            trackingRepresentative: nil,
            selfReport: nil
        )

        // Then no verdict is issued yet: the brief requires asking first
        #expect(outcome == .needsTrackingConfirmation)
    }

    // MARK: - Fallbacks

    @Test(
        "Without a usable comparison the user's own account decides",
        arguments: zip(
            [SelfReportedActivity.more, .usual, .less],
            [
                (DinnerCategory.treat, ReasonCode.selfReportedMore),
                (.balanced, .selfReportedUsual),
                (.light, .selfReportedLess)
            ]
        )
    )
    func selfReportedActivityDecidesTheCategory(
        report: SelfReportedActivity,
        expected: (category: DinnerCategory, reason: ReasonCode)
    ) throws {
        // Given no baseline at all
        // When the user reports how their day went
        let outcome = DinnerCategoryRule.decide(
            today: nil,
            baseline: nil,
            trackingRepresentative: nil,
            selfReport: report
        )

        // Then the category follows their account, and the explanation says it came from them
        let decision = try #require(outcome.decision)
        #expect(decision.category == expected.category)
        #expect(decision.basis == .selfReported(report))
        #expect(decision.reasonCodes.contains(expected.reason))
    }

    @Test("With no evidence and no check-in the verdict is a provisional balanced")
    func nothingAtAllIsProvisionallyBalanced() throws {
        // Given neither recorded evidence nor a self-report
        // When a verdict is requested anyway
        let outcome = DinnerCategoryRule.decide(
            today: nil,
            baseline: nil,
            trackingRepresentative: nil,
            selfReport: nil
        )

        // Then the judge rules balanced but marks the ruling provisional
        let decision = try #require(outcome.decision)
        #expect(decision.category == .balanced)
        #expect(decision.isProvisional)
        #expect(decision.basis == .provisional)
        #expect(decision.reasonCodes.contains(.checkInSkipped))
    }

    @Test("A baseline with nothing recorded today never produces a light verdict")
    func aMissingTodayIsNotTreatedAsZero() throws {
        // Given a usable pattern but no reading at all for today
        let baseline = makeBaseline()

        // When the rule runs with today missing and the tracking confirmed
        let outcome = DinnerCategoryRule.decide(
            today: nil,
            baseline: baseline,
            trackingRepresentative: true,
            selfReport: nil
        )

        // Then a missing reading is not read as zero activity: no recorded comparison is
        // claimed, and the decision falls to the provisional balanced row of the brief's table
        let decision = try #require(outcome.decision)
        #expect(decision.category == .balanced)
        #expect(decision.isProvisional)
        #expect(decision.basis == .provisional)
    }

    @Test("A usable recorded comparison outranks what the user reports")
    func recordedEvidenceBeatsASelfReport() throws {
        // Given a quiet but confirmed day against the 400 kcal pattern
        let baseline = makeBaseline()

        // When the user also claims they moved more than usual
        let outcome = DinnerCategoryRule.decide(
            today: 299,
            baseline: baseline,
            trackingRepresentative: true,
            selfReport: .more
        )

        // Then the recording decides, because the brief only falls back to the user's account
        // when usable measurements are unavailable
        let decision = try #require(outcome.decision)
        #expect(decision.category == .light)
        #expect(decision.basis == .recorded(ratio: 299 / 400, baseline: baseline))
    }
}
