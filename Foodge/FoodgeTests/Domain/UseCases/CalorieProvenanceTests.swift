//
//  CalorieProvenanceTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// Every expected number here is computed by hand in the test, never by calling
/// ``CalorieProvenance`` and comparing it to itself — a version of `compare(_:)` that summed
/// manual and Health intake, or that skipped the confirmation guard, would fail these.
@Suite("Calorie provenance", .tags(.unit, .domain, .critical))
struct CalorieProvenanceTests {
    private static let windowStart = Date(timeIntervalSinceReferenceDate: 0)
    private static let windowEnd = windowStart.addingTimeInterval(86_400)
    private static let window = DateInterval(start: windowStart, end: windowEnd)
    private static let offsetWindow = DateInterval(
        start: windowStart.addingTimeInterval(3_600),
        end: windowEnd.addingTimeInterval(3_600)
    )

    private static func provenance(window: DateInterval = window) -> Provenance {
        Provenance(sourceNames: ["synthetic"], readAt: window.end, window: window)
    }

    private static func energy(_ kilocalories: Double, window: DateInterval = window) -> EnergyAggregate {
        EnergyAggregate(kilocalories: kilocalories, provenance: provenance(window: window))
    }

    // MARK: - Availability

    @Test("Missing active energy refuses the comparison")
    func missingActiveEnergyRefusesTheComparison() {
        // Given resting and a confirmed intake, but no active energy reading
        let request = CalorieComparisonRequest(
            activeEnergy: nil,
            restingEnergy: Self.energy(1_500),
            intake: .recordedFromHealth(Self.energy(1_800)),
            intakeConfirmedComplete: true
        )

        // When comparing
        let outcome = CalorieProvenance.compare(request)

        // Then it refuses, naming the missing component
        #expect(outcome == .unavailable(.missingActiveEnergy))
    }

    @Test("Missing resting energy refuses the comparison")
    func missingRestingEnergyRefusesTheComparison() {
        // Given active and a confirmed intake, but no resting energy reading
        let request = CalorieComparisonRequest(
            activeEnergy: Self.energy(500),
            restingEnergy: nil,
            intake: .recordedFromHealth(Self.energy(1_800)),
            intakeConfirmedComplete: true
        )

        // When comparing
        let outcome = CalorieProvenance.compare(request)

        // Then it refuses, naming the missing component
        #expect(outcome == .unavailable(.missingRestingEnergy))
    }

    @Test("Missing intake refuses the comparison")
    func missingIntakeRefusesTheComparison() {
        // Given both expenditure components but no intake at all
        let request = CalorieComparisonRequest(
            activeEnergy: Self.energy(500),
            restingEnergy: Self.energy(1_500),
            intake: nil,
            intakeConfirmedComplete: true
        )

        // When comparing
        let outcome = CalorieProvenance.compare(request)

        // Then it refuses, naming the missing component
        #expect(outcome == .unavailable(.missingIntake))
    }

    @Test("Unconfirmed intake refuses the comparison")
    func unconfirmedIntakeRefusesTheComparison() {
        // Given every value present and aligned, but intake not confirmed complete
        let request = CalorieComparisonRequest(
            activeEnergy: Self.energy(500),
            restingEnergy: Self.energy(1_500),
            intake: .recordedFromHealth(Self.energy(1_800)),
            intakeConfirmedComplete: false
        )

        // When comparing
        let outcome = CalorieProvenance.compare(request)

        // Then it refuses even though every number is present
        #expect(outcome == .unavailable(.intakeNotConfirmedComplete))
    }

    @Test("Mismatched cutoffs refuse the comparison")
    func mismatchedCutoffsRefuseTheComparison() {
        // Given active and resting sharing one window, but intake read over a different one
        precondition(Self.window != Self.offsetWindow, "fixture windows must actually differ")
        let request = CalorieComparisonRequest(
            activeEnergy: Self.energy(500),
            restingEnergy: Self.energy(1_500),
            intake: .recordedFromHealth(Self.energy(1_800, window: Self.offsetWindow)),
            intakeConfirmedComplete: true
        )

        // When comparing
        let outcome = CalorieProvenance.compare(request)

        // Then it refuses rather than subtracting across two different periods
        #expect(outcome == .unavailable(.cutoffMismatch))
    }

    // MARK: - Manual replacement

    @Test("Manual intake replaces the Health total rather than adding to it")
    func manualIntakeReplacesTheHealthTotalRatherThanAddingToIt() {
        // Given active 500 + resting 1500, and a manual entry of 650 kcal
        // A version that summed a Health total in here too would not equal this hand-computed net
        let request = CalorieComparisonRequest(
            activeEnergy: Self.energy(500),
            restingEnergy: Self.energy(1_500),
            intake: .manual(kilocalories: 650, window: Self.window),
            intakeConfirmedComplete: true
        )

        // When comparing
        let outcome = CalorieProvenance.compare(request)

        // Then the net uses only the manual figure: 500 + 1500 - 650 = 1350
        guard case .comparison(let comparison) = outcome else {
            Issue.record("expected a comparison, got \(outcome)")
            return
        }
        #expect(comparison.intakeKilocalories == 650)
        #expect(comparison.intakeSource == .manual)
        #expect(comparison.netKilocalories == 1_350)
    }

    @Test("A Health-recorded intake is used when no manual entry is supplied")
    func healthRecordedIntakeIsUsedWhenNoManualEntryIsSupplied() {
        // Given a Health dietary-energy reading and no manual override
        let request = CalorieComparisonRequest(
            activeEnergy: Self.energy(500),
            restingEnergy: Self.energy(1_500),
            intake: .recordedFromHealth(Self.energy(1_800)),
            intakeConfirmedComplete: true
        )

        // When comparing
        let outcome = CalorieProvenance.compare(request)

        // Then the comparison is attributed to Health
        guard case .comparison(let comparison) = outcome else {
            Issue.record("expected a comparison, got \(outcome)")
            return
        }
        #expect(comparison.intakeSource == .health)
    }

    // MARK: - Arithmetic and sign

    @Test("The net is active plus resting minus intake")
    func theNetIsActivePlusRestingMinusIntake() {
        // Given hand-picked values with no coincidental symmetry
        let request = CalorieComparisonRequest(
            activeEnergy: Self.energy(437),
            restingEnergy: Self.energy(1_612),
            intake: .recordedFromHealth(Self.energy(1_204)),
            intakeConfirmedComplete: true
        )

        // When comparing
        let outcome = CalorieProvenance.compare(request)

        // Then the net is exactly 437 + 1612 - 1204 = 845
        guard case .comparison(let comparison) = outcome else {
            Issue.record("expected a comparison, got \(outcome)")
            return
        }
        #expect(comparison.activeKilocalories == 437)
        #expect(comparison.restingKilocalories == 1_612)
        #expect(comparison.netKilocalories == 845)
    }

    @Test("A negative net is returned, never suppressed")
    func negativeNetIsReturnedNotSuppressed() {
        // Given intake that exceeds active plus resting: 400 + 1500 - 2200 = -300
        let request = CalorieComparisonRequest(
            activeEnergy: Self.energy(400),
            restingEnergy: Self.energy(1_500),
            intake: .recordedFromHealth(Self.energy(2_200)),
            intakeConfirmedComplete: true
        )

        // When comparing
        let outcome = CalorieProvenance.compare(request)

        // Then a real comparison comes back carrying the negative value, not .unavailable
        guard case .comparison(let comparison) = outcome else {
            Issue.record("expected a comparison, got \(outcome)")
            return
        }
        #expect(comparison.netKilocalories == -300)
    }

    // MARK: - Dish calorie display

    @Test("A variant with no reference id shows no calorie value")
    func aVariantWithNoReferenceIDShowsNoCalorieValue() {
        // Given a generic dish variant with no calorieReferenceID
        let variant = DishVariant(
            id: "variant.test.generic",
            nameKey: "Generic dish",
            ingredients: [],
            diets: [.omnivore],
            convenience: [],
            calorieReferenceID: nil
        )

        // When resolving its calorie display against a non-empty reference set
        let outcome = CalorieProvenance.calories(for: variant, references: CalorieReferenceCatalogue.all)

        // Then it is unknown — a generic dish has no automatic calorie value
        #expect(outcome == .unknown)
    }

    @Test("A variant with a dangling reference id shows no calorie value")
    func aVariantWithADanglingReferenceIDShowsNoCalorieValue() {
        // Given a variant naming a reference id that does not exist in the supplied set
        let variant = DishVariant(
            id: "variant.test.dangling",
            nameKey: "Dangling dish",
            ingredients: [],
            diets: [.omnivore],
            convenience: [],
            calorieReferenceID: "calorieReference.does.not.exist"
        )

        // When resolving its calorie display
        let outcome = CalorieProvenance.calories(for: variant, references: CalorieReferenceCatalogue.all)

        // Then it is unknown rather than crashing on the orphaned id
        #expect(outcome == .unknown)
    }

    @Test("A variant with a matching reference id shows the verified figure")
    func aVariantWithAMatchingReferenceIDShowsTheVerifiedFigure() {
        // Given a synthetic reference and a variant naming its id
        let reference = CalorieReference(
            id: "calorieReference.test.fixture",
            regionCode: "ES",
            productName: "Test product",
            portionDescription: "One unit",
            kilocalories: 123,
            source: URL(string: "https://example.com/test") ?? URL(fileURLWithPath: "/"),
            verifiedOn: Date(timeIntervalSinceReferenceDate: 0)
        )
        let variant = DishVariant(
            id: "variant.test.matching",
            nameKey: "Matching dish",
            ingredients: [],
            diets: [.omnivore],
            convenience: [],
            calorieReferenceID: reference.id
        )

        // When resolving its calorie display
        let outcome = CalorieProvenance.calories(for: variant, references: [reference])

        // Then the exact fixture comes back untouched
        #expect(outcome == .verified(reference))
    }
}
