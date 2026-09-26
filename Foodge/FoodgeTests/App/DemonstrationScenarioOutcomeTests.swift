//
//  DemonstrationScenarioOutcomeTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// What each demonstration scenario actually produces when the real Today flow is driven over it.
///
/// This is the suite that proves a scenario demonstrates *itself*. It builds a real
/// `TodayViewModel` from `DemonstrationSessionFactory`'s own dependencies — the same seeded store,
/// the same evidence provider, the same fixed clock the app would use — and drives it end to end.
///
/// **The oracle is arithmetic done here, never a call into the rule.** Each expectation is written
/// from the scenario's own figures: maintenance is resting + active, the share is
/// `(maintenance − intake) / maintenance`, and the bands are 0.35 and 0.20 inclusive at their lower
/// edge (D112). Where a figure is estimated, the expected value comes from the published
/// Mifflin–St Jeor equation and the real length of the local day, not from `BasalMetabolicRate`.
///
/// Two cases fail specifically when the seeding rule (D100) is dropped — `.estimatedResting`, whose
/// body basics are read from stored preferences, and `.noCompatibleDish`, whose constraints are.
@Suite("Demonstration scenario outcomes", .tags(.integration, .critical))
@MainActor
struct DemonstrationScenarioOutcomeTests {
    /// A Today view model over a real demonstration session for `id`.
    private func makeSUT(_ id: DemonstrationScenarioID) async throws -> TodayViewModel {
        let session = try await DemonstrationSessionFactory.make(id)
        return session.dependencies.makeTodayViewModel()
    }

    private func decision(_ viewModel: TodayViewModel) throws -> VerdictDecision {
        let display = try #require(viewModel.currentDisplay, "Expected a verdict, stage is \(viewModel.stage.logLabel)")
        return display.decision
    }

    private func allowance(_ viewModel: TodayViewModel) throws -> EnergyAllowance {
        guard case let .energyBalance(allowance) = try decision(viewModel).basis else {
            throw FixtureFailure("Expected an energy-balance basis.")
        }
        return allowance
    }

    // MARK: - The four bands

    @Test("A big active day and a light lunch is a treat")
    func generousAllowanceReachesTreat() async throws {
        // Given the demonstration session for resting 1200, active 600, 990 eaten
        let viewModel = try await makeSUT(.generousAllowance)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then 810 of 1800 is a share of 0.45, above the 0.35 treat edge
        let allowance = try allowance(viewModel)
        #expect(allowance.maintenanceKilocalories == 1800)
        #expect(allowance.allowanceKilocalories == 810)
        #expect(allowance.share.isApproximately(810.0 / 1800.0))
        #expect(try decision(viewModel).category == .treat)

        // And the recorded workout is remarked on without moving the arithmetic
        #expect(try decision(viewModel).reasonCodes.contains(.strongActivityToday))
        #expect(allowance.restingIsEstimated == false)
        #expect(allowance.intakeIsEstimated == false)
    }

    @Test("An ordinary day is balanced")
    func modestAllowanceReachesBalanced() async throws {
        // Given resting 1600, active 400, 1460 eaten
        let viewModel = try await makeSUT(.modestAllowance)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then 540 of 2000 is a share of 0.27, inside the balanced band
        let allowance = try allowance(viewModel)
        #expect(allowance.allowanceKilocalories == 540)
        #expect(allowance.share.isApproximately(540.0 / 2000.0))
        #expect(try decision(viewModel).category == .balanced)
        #expect(try decision(viewModel).reasonCodes.contains(.moderateAllowance))
    }

    @Test("A quiet day and a heavy lunch is light")
    func slimAllowanceReachesLight() async throws {
        // Given resting 1350, active 150, 1320 eaten
        let viewModel = try await makeSUT(.slimAllowance)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then 180 of 1500 is a share of 0.12, below the 0.20 balanced edge
        let allowance = try allowance(viewModel)
        #expect(allowance.allowanceKilocalories == 180)
        #expect(allowance.share.isApproximately(180.0 / 1500.0))
        #expect(try decision(viewModel).category == .light)
    }

    @Test("Eating past the day's total is light, negative, and still gets a dish")
    func aSpentAllowanceStillRecommendsDinner() async throws {
        // Given resting 1400, active 200 and 2100 already eaten
        let viewModel = try await makeSUT(.allowanceSpent)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then the allowance is negative rather than floored at zero
        let allowance = try allowance(viewModel)
        #expect(allowance.allowanceKilocalories == -500)
        #expect(allowance.share.isApproximately(-500.0 / 1600.0))
        #expect(try decision(viewModel).category == .light)
        #expect(try decision(viewModel).reasonCodes.contains(.allowanceSpent))

        // And a dish is still recommended: a negative result never suppresses dinner
        let display = try #require(viewModel.currentDisplay)
        guard case .selected = display.dishOutcome else {
            throw FixtureFailure("Expected a dish even on a spent allowance, got \(display.dishOutcome).")
        }
    }

    // MARK: - Estimated components

    @Test("No basal samples: the body basics carry resting energy")
    func estimatedRestingUsesTheStoredBodyBasics() async throws {
        // Given no `basalEnergyBurned`, 400 active, 1250 eaten, and a 35-year-old man of 175 cm and
        // 70 kg whose daily figure is 10·70 + 6.25·175 − 5·35 + 5 = 1623.75
        let viewModel = try await makeSUT(.estimatedResting)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then resting is that figure prorated across 19.5 of the day's 24 hours
        let expectedResting = 1623.75 * (19.5 / 24.0)
        let allowance = try allowance(viewModel)
        #expect(allowance.restingKilocalories.isApproximately(expectedResting))
        #expect(allowance.restingIsEstimated)
        #expect(allowance.intakeIsEstimated == false)

        // And the verdict follows the share that produces — balanced, and labelled an estimate.
        // This is the case that fails if the demonstration stops seeding body basics (D100/D117):
        // `TodayViewModel` reads them from stored preferences, never from the snapshot.
        let expectedShare = (expectedResting + 400 - 1250) / (expectedResting + 400)
        #expect(allowance.share.isApproximately(expectedShare))
        #expect(try decision(viewModel).category == .balanced)
        #expect(try decision(viewModel).reasonCodes.contains(.restingEnergyEstimated))
    }

    @Test("No food logged: the questionnaire carries intake")
    func estimatedIntakeUsesTheQuestionnaire() async throws {
        // Given resting 1200, active 600, no `dietaryEnergy`, and a light breakfast plus a normal
        // lunch — 200 + 650 by the plan's bucket table
        let viewModel = try await makeSUT(.estimatedIntake)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then 850 is the intake, leaving 950 of 1800 — a share of 0.53, a treat
        let allowance = try allowance(viewModel)
        #expect(allowance.intakeKilocalories == 850)
        #expect(allowance.allowanceKilocalories == 950)
        #expect(allowance.intakeIsEstimated)
        #expect(try decision(viewModel).category == .treat)
        #expect(try decision(viewModel).reasonCodes.contains(.intakeEstimated))
    }

    // MARK: - The fallback

    @Test("A day with no readable Health data falls through to the self-report")
    func noHealthDataReachesSelfReport() async throws {
        // Given the demonstration session with nothing readable at all
        let viewModel = try await makeSUT(.noHealthData)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then there is no number to give, so the user is asked instead of guessed at
        guard case .needsSelfReport = viewModel.stage else {
            throw FixtureFailure("Expected the self-report check-in, got \(viewModel.stage.logLabel).")
        }

        // And answering it produces a verdict that says it was self-reported, with the answer
        // recorded in the evidence beside it
        await viewModel.submitSelfReport(.less)
        #expect(try decision(viewModel).basis == .selfReported(.less))
        let display = try #require(viewModel.currentDisplay)
        #expect(display.evidence.context.selfReportedActivity == .less)
    }

    // MARK: - Explanation, not arithmetic

    @Test("Four hours of sleep changes the explanation and not the band")
    func shortSleepDoesNotMoveTheBand() async throws {
        // Given `modestAllowance`'s exact figures on four hours of sleep, with low reported energy
        let viewModel = try await makeSUT(.shortSleep)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then the band is the one those figures produce, unchanged by sleep
        let allowance = try allowance(viewModel)
        #expect(allowance.allowanceKilocalories == 540)
        #expect(try decision(viewModel).category == .balanced)

        // And both observations appear as reasons instead
        let reasonCodes = try decision(viewModel).reasonCodes
        #expect(reasonCodes.contains(.shortSleep))
        #expect(reasonCodes.contains(.lowReportedEnergy))
    }

    // MARK: - Daylight saving

    @Test("On the 23-hour day the resting estimate divides by 23 hours")
    func springForwardProratesAgainstTheRealDay() async throws {
        // Given 03:10 on 29 March 2026 — 3 h 10 min by the clock, on a local day of 23 hours
        let viewModel = try await makeSUT(.dstSpringForward)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then resting is 1623.75 × (3 h 10 min / 23 h), not the 24-hour answer
        let elapsedSeconds = 3.0 * 3600 + 10 * 60
        let expectedResting = 1623.75 * (elapsedSeconds / (23 * 3600))
        let naiveResting = 1623.75 * (elapsedSeconds / 86_400)

        let allowance = try allowance(viewModel)
        #expect(allowance.restingKilocalories.isApproximately(expectedResting))
        #expect(!allowance.restingKilocalories.isApproximately(naiveResting))
        #expect(allowance.restingIsEstimated)

        // And a questionnaire of skipped meals is an answered zero, so the whole of maintenance is
        // still available — not a missing basis
        #expect(allowance.intakeKilocalories == 0)
        #expect(allowance.intakeIsEstimated)
    }

    // MARK: - No match

    @Test("A scenario whose exclusions block every dish reports an honest no-match")
    func noCompatibleDishReachesNoMatch() async throws {
        // Given the demonstration session for the vegan day with rice and pasta excluded
        let viewModel = try await makeSUT(.noCompatibleDish)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then the category is still reached, and the dish pick says no match rather than
        // relaxing an exclusion (D58). This is the case that fails if the seed stops deriving
        // constraints from the snapshot (D100): `DishSelection` is built from stored preferences.
        let display = try #require(viewModel.currentDisplay)
        #expect(display.decision.category == .balanced)
        guard case let .noMatch(blockingIngredientIDs) = display.dishOutcome else {
            throw FixtureFailure("Expected a no-match, got \(display.dishOutcome).")
        }
        #expect(blockingIngredientIDs == [Ingredient.rice.id, Ingredient.pasta.id])

        // And the allowance is still there to show: a no-match night now carries a figure
        #expect(try allowance(viewModel).allowanceKilocalories == 540)
    }

    // MARK: - Context

    @Test("Context the user adds during a demonstration reaches the recorded evidence")
    func contextAddedOnStageSurvivesIntoTheVerdict() async throws {
        // Given a demonstration session where the presenter adds a craving before asking
        let viewModel = try await makeSUT(.modestAllowance)
        viewModel.craving = .pasta

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then the evidence behind the verdict carries it — a provider that returned its scenario
        // snapshot verbatim would silently drop this, taking the walkthrough's context step with
        // it (D101)
        let display = try #require(viewModel.currentDisplay)
        #expect(display.evidence.context.craving == .pasta)
        #expect(display.evidence.isSynthetic)
    }
}
