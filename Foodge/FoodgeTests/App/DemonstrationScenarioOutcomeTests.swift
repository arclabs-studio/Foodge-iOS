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
/// The oracle is `CLAUDE.md`'s category decision table and D58, both written long before this
/// code: above 125% is a treat, 75–125% inclusive is balanced, below 75% asks first, no usable
/// measurement asks for a self-report, and an exclusion is never silently relaxed.
///
/// Two cases here fail specifically when the seeding rule (D100) is dropped —
/// `.partialTracking` and `.noCompatibleDish` — because both of the values they turn on are read
/// by `TodayViewModel` from stored preferences, not from the snapshot it was handed.
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

    @Test("An active day is judged a treat")
    func activeDayReachesTreat() async throws {
        // Given the demonstration session for an above-pattern day
        let viewModel = try await makeSUT(.activeDay)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then 520 kcal against a 400 kcal pattern is above 125%
        #expect(try decision(viewModel).category == .treat)
    }

    @Test("A typical day is judged balanced")
    func typicalDayReachesBalanced() async throws {
        // Given the demonstration session for an inside-the-band day
        let viewModel = try await makeSUT(.typicalDay)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then 410 kcal against 400 kcal sits inside 75–125%
        #expect(try decision(viewModel).category == .balanced)
    }

    @Test("A quiet day asks before ruling, then rules light once confirmed")
    func quietDayUnconfirmedAsksThenRulesLight() async throws {
        // Given the demonstration session for a low day the user has not been asked about
        let viewModel = try await makeSUT(.quietDayUnconfirmed)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then the flow pauses rather than ruling — a forgotten watch looks exactly like a quiet day
        guard case .needsTrackingConfirmation = viewModel.stage else {
            Issue.record("Expected the tracking check-in, got \(viewModel.stage.logLabel)")
            return
        }

        // And confirming the day was really that quiet produces the light verdict
        await viewModel.confirmTrackingReflectsToday(true)
        #expect(try decision(viewModel).category == .light)
    }

    @Test("A day with no readable Health data falls through to the self-report")
    func noHealthDataReachesSelfReport() async throws {
        // Given the demonstration session with nothing readable at all
        let viewModel = try await makeSUT(.noHealthData)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then there is no comparison to make, so the user is asked instead of guessed at
        guard case .needsSelfReport = viewModel.stage else {
            Issue.record("Expected the self-report check-in, got \(viewModel.stage.logLabel)")
            return
        }
    }

    @Test("Tracking the user called unrepresentative is not used as a pattern")
    func partialTrackingReachesSelfReport() async throws {
        // Given the demonstration session whose scenario is marked "this does not reflect my days"
        let viewModel = try await makeSUT(.partialTracking)

        // When a verdict is requested
        await viewModel.requestVerdict()

        // Then the recorded fortnight is refused as a baseline and the self-report is asked for.
        // This is the case that fails if the seed stops carrying `trackingRepresentative` across
        // from the snapshot (D100): the baseline calculator reads the *stored* flag, and the
        // snapshot's own field drives nothing.
        guard case .needsSelfReport = viewModel.stage else {
            Issue.record("Expected the self-report check-in, got \(viewModel.stage.logLabel)")
            return
        }
    }

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
            Issue.record("Expected a no-match, got \(display.dishOutcome)")
            return
        }
        #expect(blockingIngredientIDs == [Ingredient.rice.id, Ingredient.pasta.id])
    }

    @Test("Context the user adds during a demonstration reaches the recorded evidence")
    func contextAddedOnStageSurvivesIntoTheVerdict() async throws {
        // Given a demonstration session where the presenter adds a craving before asking
        let viewModel = try await makeSUT(.typicalDay)
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
