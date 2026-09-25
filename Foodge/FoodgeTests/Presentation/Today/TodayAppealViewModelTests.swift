//
//  TodayAppealViewModelTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 22/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// Appeals negotiate a preference against an already-saved verdict without ever rewriting it:
/// a compatible craving can come from a different category, an excluded ingredient leads to a
/// known compatible variant, no compatible variant is an honest no-match, and a free-text dish
/// gets no invented nutritional analysis (`foodge-plan.md` §3).
///
/// Fixtures here are deliberately duplicated from `TodayViewModelTests`' own fixture pair rather
/// than shared, per that suite's own stated scope — this suite additionally scripts an appeal
/// failure separately from a revision-save failure, which the other suite's `CaseStore` fixture
/// has no reason to support.
@Suite("Today appeals", .tags(.unit, .critical))
@MainActor
struct TodayAppealViewModelTests {
    private struct SUT {
        let viewModel: TodayViewModel
        let preferences: TodayAppealFixturePreferencesStore
        let caseStore: TodayAppealFixtureCaseStore
    }

    private func makeSUT(
        preferencesDraft: PreferencesDraft = PreferencesDraft(),
        seededCase: SavedCase? = nil,
        recordFailure: (any Error)? = nil,
        appealFailure: (any Error)? = nil,
        clock: FixedClock = SyntheticScenarios.clock
    ) -> SUT {
        let evidence = TodayAppealFixtureEvidenceProvider(snapshot: SyntheticScenarios.generousAllowance.snapshot)
        let preferences = TodayAppealFixturePreferencesStore(draft: preferencesDraft)
        let caseStore = TodayAppealFixtureCaseStore(
            seeded: seededCase,
            recordFailure: recordFailure,
            appealFailure: appealFailure
        )

        return SUT(
            viewModel: TodayViewModel(
                evidence: evidence,
                preferences: preferences,
                caseStore: caseStore,
                clock: clock,
                narrator: AppealSilentNarrator()
            ),
            preferences: preferences,
            caseStore: caseStore
        )
    }

    private func makeSavedRevision(
        category: DinnerCategory,
        evidence: EvidenceSnapshot = SyntheticScenarios.modestAllowance.snapshot
    ) -> SavedRevision {
        SavedRevision(
            id: UUID(),
            sequence: 0,
            createdAt: evidence.evaluatedAt,
            decision: VerdictDecision(
                category: category,
                basis: .provisional,
                reasonCodes: [.checkInSkipped],
                isProvisional: true,
                ruleVersion: CheatMealAllowanceRule.ruleVersion
            ),
            evidence: evidence,
            catalogueVersion: DishCatalogue.version,
            dishOutcome: .selected(
                variantID: "dish.pasta.pesto",
                family: .pasta,
                alternativeVariantID: nil,
                alternativeFamily: nil
            ),
            narrationText: nil,
            appeals: []
        )
    }

    @Test("A compatible craving can be accepted from a different category than the ruled one")
    func compatibleCravingAcceptedAcrossCategories() async throws {
        // Given a case already ruled light, and unrestricted constraints
        let revision = makeSavedRevision(category: .light)
        let saved = SavedCase(localDayKey: "2026-09-18", revisions: [revision])
        let sut = makeSUT(seededCase: saved)
        await sut.viewModel.onAppear()

        // When the user proposes a craving from a different category (burgers is a Treat family)
        await sut.viewModel.proposeCraving(.burgers)

        // Then a compatible burgers variant is found
        guard case let .compatibleFound(family, entry) = sut.viewModel.appealStage else {
            Issue.record("Expected .compatibleFound, got \(sut.viewModel.appealStage)")
            return
        }
        #expect(family == .burgers)
        #expect(entry.family == .burgers)

        // When the user accepts it
        await sut.viewModel.acceptCompatible(entry: entry)

        // Then the appeal is recorded against the existing revision, and the verdict is untouched
        guard case .recorded = sut.viewModel.appealStage else {
            Issue.record("Expected .recorded, got \(sut.viewModel.appealStage)")
            return
        }
        let recorded = try #require(await sut.caseStore.recordedAppeals.first)
        #expect(recorded.revisionID == revision.id)
        guard case let .catalogue(variantID, family) = recorded.draft.choice else {
            Issue.record("Expected a .catalogue appeal choice")
            return
        }
        #expect(variantID == entry.id)
        #expect(family == .burgers)
        #expect(sut.viewModel.currentRevision == revision)
    }

    @Test("An excluded ingredient leads to a known compatible variant, not just any survivor")
    func excludedIngredientYieldsKnownCompatibleVariant() async {
        // Given a vegetarian profile that excludes halloumi
        let revision = makeSavedRevision(category: .light)
        let saved = SavedCase(localDayKey: "2026-09-18", revisions: [revision])
        let draft = PreferencesDraft(dietProfile: .vegetarian, excludedIngredientIDs: [Ingredient.halloumi.id])
        let sut = makeSUT(preferencesDraft: draft, seededCase: saved)
        await sut.viewModel.onAppear()

        // When the user craves burgers
        await sut.viewModel.proposeCraving(.burgers)

        // Then the black-bean variant is offered — not the halloumi burger (excluded) or the beef
        // burger (fails the vegetarian diet)
        guard case let .compatibleFound(_, entry) = sut.viewModel.appealStage else {
            Issue.record("Expected .compatibleFound, got \(sut.viewModel.appealStage)")
            return
        }
        #expect(entry.id == "dish.burgers.blackBean")
    }

    @Test("No compatible variant produces an honest no-match result")
    func noCompatibleVariantIsHonest() async {
        // Given a vegan profile that excludes the one vegan-compatible tacos ingredient
        let revision = makeSavedRevision(category: .light)
        let saved = SavedCase(localDayKey: "2026-09-18", revisions: [revision])
        let draft = PreferencesDraft(dietProfile: .vegan, excludedIngredientIDs: [Ingredient.blackBeans.id])
        let sut = makeSUT(preferencesDraft: draft, seededCase: saved)
        await sut.viewModel.onAppear()

        // When the user craves tacos
        await sut.viewModel.proposeCraving(.tacos)

        // Then the result is an honest no-match, naming the sole blocking ingredient
        guard case let .noMatchFound(family, blockingIngredientIDs) = sut.viewModel.appealStage else {
            Issue.record("Expected .noMatchFound, got \(sut.viewModel.appealStage)")
            return
        }
        #expect(family == .tacos)
        #expect(blockingIngredientIDs == [Ingredient.blackBeans.id])
    }

    @Test("A free-text appeal needs no catalogue lookup, and leaves the day's facts unchanged")
    func freeTextAppealNeedsNoCatalogueLookup() async {
        // Given a case already ruled on
        let revision = makeSavedRevision(category: .balanced)
        let saved = SavedCase(localDayKey: "2026-09-18", revisions: [revision])
        let sut = makeSUT(seededCase: saved)
        await sut.viewModel.onAppear()
        let displayBefore = sut.viewModel.currentDisplay

        // When the user submits a free-text dish
        sut.viewModel.beginFreeText()
        await sut.viewModel.submitFreeText("something wild")

        // Then the appeal is recorded as free text, with no invented nutritional analysis
        guard case let .recorded(choice) = sut.viewModel.appealStage else {
            Issue.record("Expected .recorded, got \(sut.viewModel.appealStage)")
            return
        }
        guard case let .freeText(text) = choice else {
            Issue.record("Expected a .freeText appeal choice")
            return
        }
        #expect(text == "something wild")

        // And the day's displayed category and evidence are exactly as they were — nothing about
        // the day's facts was rewritten
        #expect(sut.viewModel.currentDisplay?.decision == displayBefore?.decision)
        #expect(sut.viewModel.currentDisplay?.dishOutcome == displayBefore?.dishOutcome)
        #expect(sut.viewModel.currentDisplay?.evidence == displayBefore?.evidence)
    }

    @Test("A failed appeal save keeps the choice visible, with a retry")
    func failedAppealSaveKeepsChoiceVisibleWithRetry() async {
        // Given a case already ruled on, and a store that will refuse the appeal write
        let revision = makeSavedRevision(category: .balanced)
        let saved = SavedCase(localDayKey: "2026-09-18", revisions: [revision])
        let sut = makeSUT(seededCase: saved, appealFailure: FoodgeError.saveFailed)
        await sut.viewModel.onAppear()

        // When the user submits a free-text appeal
        sut.viewModel.beginFreeText()
        await sut.viewModel.submitFreeText("something wild")

        // Then the choice stays visible with the failure, never reported as recorded
        guard case let .appealFailed(draft, revisionID, error) = sut.viewModel.appealStage else {
            Issue.record("Expected .appealFailed, got \(sut.viewModel.appealStage)")
            return
        }
        #expect(error == .saveFailed)
        #expect(revisionID == revision.id)
        guard case let .freeText(text) = draft.choice else {
            Issue.record("Expected the original .freeText draft to survive the failure")
            return
        }
        #expect(text == "something wild")

        // When the store recovers and the user retries
        await sut.caseStore.stopFailingAppeals()
        await sut.viewModel.retryAppeal()

        // Then the same appeal is recorded, once
        guard case .recorded = sut.viewModel.appealStage else {
            Issue.record("Expected .recorded after a successful retry")
            return
        }
        #expect(await sut.caseStore.recordedAppeals.count == 1)
    }

    @Test("An appeal cannot start without a saved revision to attach to")
    func appealCannotStartWithoutASavedRevision() async {
        // Given a save that failed — a computed decision with no revision id yet
        let sut = makeSUT(recordFailure: FoodgeError.saveFailed)
        await sut.viewModel.requestVerdict()
        guard case .saveFailed = sut.viewModel.stage else {
            Issue.record("Expected the initial save to fail")
            return
        }

        // When appeal methods are called anyway
        await sut.viewModel.proposeCraving(.burgers)
        await sut.viewModel.submitFreeText("something wild")

        // Then nothing happens — there is no revision id to attach an appeal to
        guard case .choosingCraving = sut.viewModel.appealStage else {
            Issue.record("Expected .choosingCraving to be untouched, got \(sut.viewModel.appealStage)")
            return
        }
        #expect(await sut.caseStore.recordedAppeals.isEmpty)
    }
}

// MARK: - Fixtures

/// Hands back one fixed snapshot, whatever it is asked for — this suite never needs to script a
/// read failure, only the appeal negotiation and save that follow a successful one.
private actor TodayAppealFixtureEvidenceProvider: HealthEvidenceProvider {
    private let snapshot: EvidenceSnapshot

    init(snapshot: EvidenceSnapshot) {
        self.snapshot = snapshot
    }

    func snapshot(
        at _: Date,
        calendar _: Calendar,
        context _: DailyContext,
        constraints _: DietaryConstraints
    ) async throws -> EvidenceSnapshot {
        snapshot
    }
}

/// Holds one draft in memory, standing in for the saved preferences an appeal re-fetches fresh.
private actor TodayAppealFixturePreferencesStore: PreferencesStore {
    private var draft: PreferencesDraft?

    init(draft: PreferencesDraft?) {
        self.draft = draft
    }

    func savePreferences(_ draft: PreferencesDraft) async throws {
        self.draft = draft
    }

    func preferences() async throws -> PreferencesDraft? {
        draft
    }
}

/// Produces nothing at all — narration is not this suite's subject. See
/// `TodayNarrationViewModelTests` for the narration contract.
private struct AppealSilentNarrator: VerdictNarrator {
    func flourish(for _: VerdictDecision, dishName _: String, note _: Note?) async -> String? {
        nil
    }
}

/// A scripted `CaseStore` that separates an appeal failure from a revision-save failure — an
/// appeal preview or test reopens a case that already saved successfully, then fails only the
/// appeal itself.
private actor TodayAppealFixtureCaseStore: CaseStore {
    private let seeded: SavedCase?
    private var recordFailure: (any Error)?
    private var appealFailure: (any Error)?
    private(set) var recordedDrafts: [NewRevisionDraft] = []
    private(set) var recordedAppeals: [(draft: AppealDraft, revisionID: UUID)] = []

    init(seeded: SavedCase?, recordFailure: (any Error)?, appealFailure: (any Error)?) {
        self.seeded = seeded
        self.recordFailure = recordFailure
        self.appealFailure = appealFailure
    }

    /// Lets a scripted appeal failure be cleared, so a retry can be exercised.
    func stopFailingAppeals() {
        appealFailure = nil
    }

    func savedCase(matching _: EvidenceSnapshot) async throws -> SavedCase? {
        seeded
    }

    @discardableResult
    func recordRevision(_ draft: NewRevisionDraft) async throws -> SavedRevision {
        if let recordFailure {
            throw recordFailure
        }
        recordedDrafts.append(draft)
        return SavedRevision(
            id: UUID(),
            sequence: recordedDrafts.count - 1,
            createdAt: draft.evidence.evaluatedAt,
            decision: draft.decision,
            evidence: draft.evidence,
            catalogueVersion: draft.catalogueVersion,
            dishOutcome: draft.dishOutcome,
            narrationText: nil,
            appeals: []
        )
    }

    func recordAppeal(_ draft: AppealDraft, to revisionID: UUID) async throws {
        if let appealFailure {
            throw appealFailure
        }
        recordedAppeals.append((draft, revisionID))
    }

    @discardableResult
    func attachNarration(_ text: String, to revisionID: UUID) async throws -> SavedRevision {
        // Not exercised this suite — see `TodayNarrationViewModelTests`.
        throw FoodgeError.revisionNotFound
    }

    func allCases() async throws -> [SavedCase] {
        // Not exercised this suite — see `HistoryViewModelTests`.
        []
    }
}
