//
//  EnergyAllowanceGaugeTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 13/10/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The Evidence screen draws today's allowance share as a `Gauge`, whose value must sit inside its
/// 0...1 track. The share itself does not: eating past maintenance is a real day, and its negative
/// share is a valid, returned value (D112) that the figure beside the bar must keep showing.
///
/// So `gaugeShare` is the bar's number only. Every expected value below is a literal written from
/// the arithmetic in each Given — none is read back from `gaugeShare` or from the clamp it applies.
@Suite("Energy allowance gauge", .tags(.unit))
struct EnergyAllowanceGaugeTests {
    /// A day with 1600 resting and 400 active energy (maintenance 2000) and the given intake,
    /// built the way the rule builds one: allowance is maintenance minus intake, share is allowance
    /// over maintenance, neither floored.
    private func makeSUT(intakeKilocalories: Double) -> EnergyAllowance {
        let resting = 1600.0
        let active = 400.0
        let maintenance = resting + active
        let allowance = maintenance - intakeKilocalories

        return EnergyAllowance(
            activeKilocalories: active,
            restingKilocalories: resting,
            intakeKilocalories: intakeKilocalories,
            maintenanceKilocalories: maintenance,
            allowanceKilocalories: allowance,
            share: allowance / maintenance,
            restingIsEstimated: false,
            intakeIsEstimated: false,
            window: SyntheticScenarios.windowSinceMidnight(endingAt: SyntheticScenarios.evaluationDate)
        )
    }

    @Test("A day eaten past maintenance draws an empty bar")
    func negativeShareDrawsAnEmptyBar() {
        // Given 2500 kcal eaten against 2000 of maintenance: 500 over, a share of -0.25
        let allowance = makeSUT(intakeKilocalories: 2500)

        // When the gauge value is read
        let gauge = allowance.gaugeShare

        // Then the bar is empty, not negative and not the absolute value
        #expect(gauge == 0)
    }

    @Test("A share inside the track is drawn as it is", arguments: [
        (1460.0, 0.27),
        (700.0, 0.65),
        (1760.0, 0.12),
    ])
    func shareInsideTheTrackIsUnchanged(intakeKilocalories: Double, expectedShare: Double) {
        // Given a day whose share (maintenance minus intake, over maintenance) is the expected one
        let allowance = makeSUT(intakeKilocalories: intakeKilocalories)
        #expect(allowance.share == expectedShare, "The scenario itself is mis-stated: its share is not \(expectedShare).")

        // When the gauge value is read
        let gauge = allowance.gaugeShare

        // Then the bar fills exactly that share — not a constant, not a rescaled or rounded one
        #expect(gauge == expectedShare)
    }

    @Test("Nothing eaten fills the bar to its end")
    func nothingEatenFillsTheBar() {
        // Given nothing eaten: the whole 2000 kcal of maintenance is left, a share of exactly 1
        let allowance = makeSUT(intakeKilocalories: 0)

        // When the gauge value is read
        let gauge = allowance.gaugeShare

        // Then the bar is full — the edge of the track is reachable, not wrapped back to empty
        #expect(gauge == 1)
    }

    @Test("A share beyond the track draws a full bar")
    func shareAboveOneDrawsAFullBar() {
        // Given a negative intake of -800 kcal, which no Health read produces but the entity does not
        // forbid: 2800 left against 2000 of maintenance, a share of 1.4
        let allowance = makeSUT(intakeKilocalories: -800)

        // When the gauge value is read
        let gauge = allowance.gaugeShare

        // Then the bar stops at the end of its track
        #expect(gauge == 1)
    }
}
