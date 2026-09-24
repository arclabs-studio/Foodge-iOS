//
//  DemonstrationSessionTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation
import SwiftData
import Testing

/// The safety properties of demonstration mode, stated as things that can be observed from
/// outside it: nothing it writes reaches the real store, leaving it changes nothing, and nothing
/// it holds can reach Health, the notification centre or the disk.
///
/// The live store here is a real on-disk container at a temporary URL, opened through
/// `AppLaunch`'s injected opener (D104) — the point is that the oracle is the bytes an entirely
/// separate container reads back, not this code's own opinion of what it wrote.
@Suite("Demonstration session", .tags(.integration, .critical))
@MainActor
struct DemonstrationSessionTests {
    /// Lets one test flip the injected factory from refusing to succeeding between two calls.
    ///
    /// `AppLaunch` is a `@MainActor` class, so the closure it stores is `Sendable`, and a local
    /// `var` captured by it and then mutated is rejected: *"'shouldFail' mutated after capture by
    /// sendable closure"*. A `@MainActor` reference type holds the flag instead — every read and
    /// write is on the main actor, with no `@unchecked Sendable` anywhere near it.
    @MainActor
    private final class FailureGate {
        var shouldFail = true
    }

    /// A launch whose "live" store is a throwaway file, plus the URL so a second container can be
    /// opened on it independently.
    private func makeSUT() -> (launch: AppLaunch, liveURL: URL) {
        let url = TemporaryStore.makeURL()
        return (AppLaunch(openLive: { try ContainerFactory.make(at: url) }), url)
    }

    private func readyDependencies(_ launch: AppLaunch) throws -> AppDependencies {
        guard case let .ready(session) = launch.state else {
            Issue.record("Expected a ready session, got \(launch.state)")
            throw FixtureFailure("not ready")
        }
        return session.dependencies
    }

    private func readySession(_ launch: AppLaunch) throws -> AppSession {
        guard case let .ready(session) = launch.state else {
            Issue.record("Expected a ready session, got \(launch.state)")
            throw FixtureFailure("not ready")
        }
        return session
    }

    /// A revision that can be recorded into any store, dated by the scenario it came from.
    private func revisionDraft(for scenario: SyntheticScenario) -> NewRevisionDraft {
        NewRevisionDraft(
            decision: VerdictDecision(
                category: .balanced,
                basis: .selfReported(.usual),
                reasonCodes: [.selfReportedUsual],
                isProvisional: false,
                ruleVersion: DinnerCategoryRule.ruleVersion
            ),
            evidence: scenario.snapshot,
            catalogueVersion: DishCatalogue.version,
            dishOutcome: .selected(
                variantID: "dish.pasta.pesto",
                family: .pasta,
                alternativeVariantID: nil,
                alternativeFamily: nil
            )
        )
    }

    @Test("Everything a demonstration writes stays out of the live store")
    func demonstrationWritesNeverReachTheLiveStore() async throws {
        // Given a live session over a real store, and a demonstration running on top of it
        let (launch, liveURL) = makeSUT()
        await launch.load()
        await launch.startDemonstration(.typicalDay)
        let demo = try readySession(launch)
        #expect(demo.isDemonstration)

        // When the demonstration writes both a preference change and a recorded verdict
        try await demo.dependencies.store.savePreferences(
            PreferencesDraft(dietProfile: .vegan, onboardingCompletedAt: SyntheticScenarios.evaluationDate)
        )
        _ = try await demo.dependencies.caseStore.recordRevision(
            revisionDraft(for: SyntheticScenarios.typicalDay)
        )

        // Then a completely separate container opened on the live file finds nothing at all
        let independent = ModelContext(try ContainerFactory.make(at: liveURL))
        #expect(try independent.fetch(FetchDescriptor<DailyCase>()).isEmpty)
        #expect(try independent.fetch(FetchDescriptor<UserPreferences>()).isEmpty)
    }

    @Test("Leaving a demonstration returns the same live session, with the real data untouched")
    func exitingADemonstrationDiscardsEverythingWrittenDuringIt() async throws {
        // Given a live session that already holds one real case
        let (launch, _) = makeSUT()
        await launch.load()
        let live = try readySession(launch)
        _ = try await live.dependencies.caseStore.recordRevision(
            revisionDraft(for: SyntheticScenarios.activeDay)
        )
        let liveCasesBefore = try await live.dependencies.caseStore.allCases()

        // When a demonstration runs, records its own verdict, and is exited
        await launch.startDemonstration(.restDay)
        let demo = try readySession(launch)
        _ = try await demo.dependencies.caseStore.recordRevision(
            revisionDraft(for: SyntheticScenarios.restDay)
        )
        launch.exitDemonstration()

        // Then the session that comes back is the *same* container, not a reopened one — which is
        // what makes exiting incapable of failing (D98) — and its cases are exactly as they were
        let restored = try readySession(launch)
        #expect(restored.isDemonstration == false)
        #expect(restored.container === live.container)
        #expect(restored.id == live.id)
        let liveCasesAfter = try await restored.dependencies.caseStore.allCases()
        #expect(liveCasesAfter == liveCasesBefore)
        #expect(liveCasesAfter.count == 1)
    }

    @Test("The demonstration store is seeded from the scenario, so it opens past onboarding")
    func theDemonstrationContainerIsSeededSoOnboardingIsSkipped() async throws {
        // Given a demonstration of the one scenario whose constraints are the point of it
        let (launch, _) = makeSUT()
        await launch.load()
        await launch.startDemonstration(.noCompatibleDish)
        let demo = try readySession(launch)

        // When the seeded preferences are read back through a fresh context on that container
        let context = ModelContext(demo.container)
        let stored = try #require(try context.fetch(FetchDescriptor<UserPreferences>()).first)

        // Then onboarding is already complete, and the scenario's own constraints are what the
        // dish pick will read — the oracle is `SyntheticScenarios.noCompatibleDish`'s declaration
        #expect(stored.hasCompletedOnboarding)
        #expect(stored.dietProfile == .vegan)
        #expect(Set(stored.excludedIngredientIDs) == [Ingredient.rice.id, Ingredient.pasta.id])
    }

    @Test("A demonstration session holds nothing that can reach the device")
    func aDemonstrationSessionCannotReachTheDevice() async throws {
        // Given a running demonstration
        let (launch, _) = makeSUT()
        await launch.load()
        await launch.startDemonstration(.activeDay)
        let dependencies = try readyDependencies(launch)

        // Then every seam that could touch Health or the notification centre is the stubbed one.
        // Type identity is normally a weak assertion; here the safety property *is* the wiring,
        // and this is the only place it can be checked.
        #expect(dependencies.evidence is DemonstrationEvidenceProvider)
        #expect(dependencies.reminders is DemonstrationReminderService)
        #expect(dependencies.authorization is DemonstrationHealthAuthorization)
        // And the narrator is deliberately the real chain, not a stub: proving genuine on-device
        // narration is part of what a demonstration is for (D102).
        #expect(dependencies.narrator is DeadlineNarrator)
    }

    @Test("A demonstration that fails to start leaves the live session running")
    func aFailedDemonstrationStartLeavesTheLiveSessionRunning() async throws {
        // Given a launch whose demonstration factory refuses
        let url = TemporaryStore.makeURL()
        let launch = AppLaunch(
            openLive: { try ContainerFactory.make(at: url) },
            openDemonstration: { _ in throw FoodgeError.saveFailed }
        )
        await launch.load()
        let live = try readySession(launch)

        // When a scenario is started
        await launch.startDemonstration(.typicalDay)

        // Then the live session is still the one running, and the failure is reported as a failed
        // demonstration rather than as a broken store
        let after = try readySession(launch)
        #expect(after.id == live.id)
        #expect(after.isDemonstration == false)
        #expect(launch.demonstrationFailure == .saveFailed)
    }

    @Test("Exiting clears a previous start failure")
    func exitingClearsAPreviousFailure() async throws {
        // Given a live session that has already seen a demonstration refuse to start
        let url = TemporaryStore.makeURL()
        let gate = FailureGate()
        let launch = AppLaunch(
            openLive: { try ContainerFactory.make(at: url) },
            openDemonstration: { id in
                if gate.shouldFail { throw FoodgeError.storeUnavailable }
                return try await DemonstrationSessionFactory.make(id)
            }
        )
        await launch.load()
        await launch.startDemonstration(.typicalDay)
        #expect(launch.demonstrationFailure == .storeUnavailable)

        // When a second attempt succeeds and is then exited
        gate.shouldFail = false
        await launch.startDemonstration(.typicalDay)
        #expect(launch.demonstrationFailure == nil)
        launch.exitDemonstration()

        // Then no stale failure is left behind to be shown beside a working live session
        #expect(launch.demonstrationFailure == nil)
    }
}
