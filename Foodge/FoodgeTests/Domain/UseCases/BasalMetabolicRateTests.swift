//
//  BasalMetabolicRateTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// Mifflin–St Jeor and its proration, against literals worked out from the published equation
/// rather than from the implementation.
///
/// A 35-year-old, 70 kg, 175 cm man: `10·70 + 6.25·175 − 5·35 + 5` = `700 + 1093.75 − 175 + 5`
/// = **1623.75** kcal/day. The same body as a woman ends `− 161` instead of `+ 5` = **1457.75**.
///
/// The proration tests exist because `86_400` is the obvious wrong denominator and passes almost
/// every test that does not cross a clock change. Each daylight-saving case therefore also asserts
/// that the answer is **not** the 86,400-second answer, so an implementation that divides by a
/// fixed day fails here rather than passing quietly.
@Suite("Basal metabolic rate", .tags(.unit, .domain, .critical))
struct BasalMetabolicRateTests {

    // MARK: - Fixtures

    private static let dailyKilocaloriesForTheManInTheFixture = 1623.75
    private static let dailyKilocaloriesForTheWomanInTheFixture = 1457.75

    private let calendar = TestCalendar.madrid

    private func makeBody(sex: BiologicalSex = .male) throws -> BodyBasics {
        try #require(
            BodyBasics(sex: sex, ageYears: 35, heightCentimetres: 175, weightKilograms: 70)
        )
    }

    private func window(from start: Date, to end: Date) -> DateInterval {
        DateInterval(start: start, end: end)
    }

    // MARK: - The equation

    @Test("A 35-year-old 70 kg 175 cm man has a 1623.75 kcal daily resting estimate")
    func theMaleFormulaMatchesThePublishedEquation() throws {
        // Given the body in the fixture
        let body = try makeBody(sex: .male)

        // When the daily figure is computed
        let daily = BasalMetabolicRate.dailyKilocalories(for: body)

        // Then it is the hand-worked value, and the male form is the one that adds 5
        #expect(daily == Self.dailyKilocaloriesForTheManInTheFixture)
        #expect(daily == 10 * 70.0 + 6.25 * 175.0 - 5 * 35.0 + 5)
    }

    @Test("The same body as a woman ends in −161 rather than +5")
    func theFemaleFormulaMatchesThePublishedEquation() throws {
        // Given the same figures with the female form of the equation
        let body = try makeBody(sex: .female)

        // When the daily figure is computed
        let daily = BasalMetabolicRate.dailyKilocalories(for: body)

        // Then it is 166 kcal below the male figure — the difference between −161 and +5
        #expect(daily == Self.dailyKilocaloriesForTheWomanInTheFixture)
        #expect(Self.dailyKilocaloriesForTheManInTheFixture - daily == 166)
    }

    // MARK: - Proration on an ordinary day

    @Test("19:30 on an ordinary 24-hour day is 19.5/24 of the daily figure")
    func anOrdinaryDayProratesAgainstTwentyFourHours() throws {
        // Given an ordinary September day, which really is 86,400 seconds long
        let body = try makeBody()
        let midnight = TestCalendar.date(2026, 9, 15)
        let evaluation = TestCalendar.date(2026, 9, 15, 19, 30)
        #expect(calendar.dateInterval(of: .day, for: evaluation)?.duration == 24 * 3600)

        // When the estimate is prorated up to 19:30
        let prorated = try #require(
            BasalMetabolicRate.kilocalories(
                for: body,
                upTo: window(from: midnight, to: evaluation),
                calendar: calendar
            )
        )

        // Then it is the daily figure scaled by 19.5 of 24 hours
        let expected = Self.dailyKilocaloriesForTheManInTheFixture * (19.5 / 24.0)
        #expect(prorated.isApproximately(expected))
    }

    @Test("Local midnight has spent none of the day")
    func midnightProratesToZero() throws {
        // Given an evaluation at local midnight exactly
        let body = try makeBody()
        let midnight = TestCalendar.date(2026, 9, 15)

        // When the estimate is prorated up to that instant
        let prorated = BasalMetabolicRate.kilocalories(
            for: body,
            upTo: window(from: midnight, to: midnight),
            calendar: calendar
        )

        // Then nothing of the day has elapsed
        #expect(prorated == 0)
    }

    // MARK: - Daylight saving

    @Test("03:10 on the 23-hour spring-forward day divides by 23 hours, not 24")
    func springForwardProratesAgainstAShorterDay() throws {
        // Given 29 March 2026, the day Spain skips 02:00–03:00, so the local day is 23 hours long
        let body = try makeBody()
        let midnight = TestCalendar.date(2026, 3, 29)
        let evaluation = TestCalendar.date(2026, 3, 29, 3, 10)
        #expect(calendar.dateInterval(of: .day, for: evaluation)?.duration == 23 * 3600)

        // When the estimate is prorated up to 03:10
        let prorated = try #require(
            BasalMetabolicRate.kilocalories(
                for: body,
                upTo: window(from: midnight, to: evaluation),
                calendar: calendar
            )
        )

        // Then the clock's 3h10m is measured against a 23-hour day
        let elapsedSeconds = 3.0 * 3600 + 10 * 60
        let expected = Self.dailyKilocaloriesForTheManInTheFixture * (elapsedSeconds / (23 * 3600))
        #expect(prorated.isApproximately(expected))

        // And it is not the 86,400-second answer, which is what makes this test discriminate
        let naive = Self.dailyKilocaloriesForTheManInTheFixture * (elapsedSeconds / 86_400)
        #expect(!prorated.isApproximately(naive))
        #expect(prorated > naive)
    }

    @Test("19:30 on the 25-hour autumn day divides by 25 hours, not 24")
    func fallBackProratesAgainstALongerDay() throws {
        // Given 25 October 2026, the day Spain repeats 02:00–03:00, so the local day is 25 hours
        let body = try makeBody()
        let midnight = TestCalendar.date(2026, 10, 25)
        let evaluation = TestCalendar.date(2026, 10, 25, 19, 30)
        #expect(calendar.dateInterval(of: .day, for: evaluation)?.duration == 25 * 3600)

        // When the estimate is prorated up to 19:30
        let prorated = try #require(
            BasalMetabolicRate.kilocalories(
                for: body,
                upTo: window(from: midnight, to: evaluation),
                calendar: calendar
            )
        )

        // Then a longer day has spent a smaller share of its maintenance by the same clock time
        let elapsedSeconds = 19.5 * 3600
        let expected = Self.dailyKilocaloriesForTheManInTheFixture * (elapsedSeconds / (25 * 3600))
        #expect(prorated.isApproximately(expected))

        let naive = Self.dailyKilocaloriesForTheManInTheFixture * (elapsedSeconds / 86_400)
        #expect(!prorated.isApproximately(naive))
        #expect(prorated < naive)
    }
}
