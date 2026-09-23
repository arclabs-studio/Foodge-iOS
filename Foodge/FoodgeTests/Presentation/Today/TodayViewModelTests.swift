//
//  TodayViewModelTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 21/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// Today is where a saved case must come back unregenerated, a low reading must pause for
/// confirmation rather than guess, and a failed save must never be reported as saved.
///
/// Fixtures here are deliberately duplicated rather than reaching into `OnboardingViewModelTests`'
/// private types — this suite owns its own `TodayFixtureEvidenceProvider`/`TodayFixturePreferencesStore`
/// pair, plus a `TodayFixtureCaseStore` neither other suite needs.
@Suite("Today view model", .tags(.unit, .critical))
@MainActor
struct TodayViewModelTests {
    private struct SUT {
        let viewModel: TodayViewModel
        let evidence: TodayFixtureEvidenceProvider
        let preferences: TodayFixturePreferencesStore
        let caseStore: TodayFixtureCaseStore
    }

    private func makeSUT(
        snapshot: EvidenceSnapshot = SyntheticScenarios.typicalDay.snapshot,
        evidenceFailure: (any Error)? = nil,
        preferencesDraft: PreferencesDraft = PreferencesDraft(),
        seededCase: SavedCase? = nil,
        recordFailure: (any Error)? = nil,
        clock: FixedClock = SyntheticScenarios.clock
    ) -> SUT {
        let evidence = evidenceFailure.map(TodayFixtureEvidenceProvider.init(failure:))
            ?? TodayFixtureEvidenceProvider(snapshot: snapshot)
        let preferences = TodayFixturePreferencesStore(draft: preferencesDraft)
        let caseStore = TodayFixtureCaseStore(seeded: seededCase, recordFailure: recordFailure)

        return SUT(
            viewModel: TodayViewModel(
                evidence: evidence,
                preferences: preferences,
                caseStore: caseStore,
                clock: clock
            ),
            evidence: evidence,
            preferences: preferences,
            caseStore: caseStore
        )
    }

    private func makeSavedRevision(
        category: DinnerCategory,
        evidence: EvidenceSnapshot = SyntheticScenarios.typicalDay.snapshot
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
                ruleVersion: DinnerCategoryRule.ruleVersion
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

    // MARK: - Reopening

    @Test("Reopening a saved case never reads Health")
    func reopeningNeverReadsHealth() async {
        // Given a case already saved for today
        let revision = makeSavedRevision(category: .treat)
        let saved = SavedCase(localDayKey: "2026-09-18", revisions: [revision])
        let sut = makeSUT(seededCase: saved)

        // When the screen appears
        await sut.viewModel.onAppear()

        // Then the saved verdict is shown directly — Health was never touched
        #expect(sut.viewModel.currentRevision == revision)
        #expect(await sut.evidence.callCount == 0)
    }

    @Test("With no saved case, requesting a verdict reads Health and records exactly once")
    func noSavedCaseEvaluatesAndRecordsOnce() async throws {
        // Given no saved case, and a day well above the recorded pattern
        let sut = makeSUT(snapshot: SyntheticScenarios.activeDay.snapshot)
        await sut.viewModel.onAppear()

        // When a verdict is requested
        await sut.viewModel.requestVerdict()

        // Then Health was read once and exactly one revision was recorded
        #expect(await sut.evidence.callCount == 1)
        let recorded = try #require(await sut.caseStore.recordedDrafts.first)
        #expect(await sut.caseStore.recordedDrafts.count == 1)
        #expect(recorded.evidence == SyntheticScenarios.activeDay.snapshot)
    }

    // MARK: - The recorded comparison

    @Test("A ratio above the treat threshold rules directly, with no check-in")
    func aboveTreatThresholdRulesDirectly() async {
        // Given a day well above the recorded pattern
        let sut = makeSUT(snapshot: SyntheticScenarios.activeDay.snapshot)

        // When a verdict is requested
        await sut.viewModel.requestVerdict()

        // Then it rules treat directly, never pausing for a check-in
        guard case .verdict = sut.viewModel.stage else {
            Issue.record("Expected .verdict, got \(sut.viewModel.stage.logLabel)")
            return
        }
        #expect(sut.viewModel.currentRevision?.decision.category == .treat)
    }

    @Test("A low ratio pauses for tracking confirmation before recording anything")
    func lowRatioPausesForTrackingConfirmation() async {
        // Given a day well below the recorded pattern, not yet asked about
        let sut = makeSUT(snapshot: SyntheticScenarios.quietDayUnconfirmed.snapshot)

        // When a verdict is requested
        await sut.viewModel.requestVerdict()

        // Then Foodge asks before ruling, and nothing has been recorded yet
        guard case .needsTrackingConfirmation = sut.viewModel.stage else {
            Issue.record("Expected .needsTrackingConfirmation, got \(sut.viewModel.stage.logLabel)")
            return
        }
        #expect(await sut.caseStore.recordedDrafts.isEmpty)
    }

    @Test("Confirming tracking reflects today records the recorded verdict, unchanged")
    func confirmingTrackingRecordsRecordedVerdict() async throws {
        // Given a paused tracking-confirmation check-in
        let sut = makeSUT(snapshot: SyntheticScenarios.quietDayUnconfirmed.snapshot)
        await sut.viewModel.requestVerdict()

        // When the user confirms the recorded activity reflects today
        await sut.viewModel.confirmTrackingReflectsToday(true)

        // Then the light verdict is recorded from the original evidence, unchanged
        guard case .verdict = sut.viewModel.stage else {
            Issue.record("Expected .verdict, got \(sut.viewModel.stage.logLabel)")
            return
        }
        let recorded = try #require(await sut.caseStore.recordedDrafts.first)
        #expect(recorded.decision.category == .light)
        #expect(recorded.evidence == SyntheticScenarios.quietDayUnconfirmed.snapshot)
    }

    @Test("Declining tracking confirmation moves to self-report, and never loops back")
    func decliningTrackingMovesToSelfReport() async {
        // Given a paused tracking-confirmation check-in
        let sut = makeSUT(snapshot: SyntheticScenarios.quietDayUnconfirmed.snapshot)
        await sut.viewModel.requestVerdict()

        // When the user says the recorded activity does not reflect today
        await sut.viewModel.confirmTrackingReflectsToday(false)

        // Then the flow moves on to the self-report check-in — the regression this pins is a
        // loop straight back to `.needsTrackingConfirmation` (D56)
        guard case .needsSelfReport = sut.viewModel.stage else {
            Issue.record("Expected .needsSelfReport, got \(sut.viewModel.stage.logLabel)")
            return
        }
        #expect(await sut.caseStore.recordedDrafts.isEmpty)
    }

    // MARK: - The self-report fallback

    @Test(
        "Each self-report choice maps to its own category, from the user's own account",
        arguments: [
            (SelfReportedActivity.more, DinnerCategory.treat),
            (SelfReportedActivity.usual, DinnerCategory.balanced),
            (SelfReportedActivity.less, DinnerCategory.light)
        ]
    )
    func selfReportMapsToCategory(report: SelfReportedActivity, expected: DinnerCategory) async throws {
        // Given no usable recorded comparison at all
        let sut = makeSUT(snapshot: SyntheticScenarios.noHealthData.snapshot)
        await sut.viewModel.requestVerdict()

        // When the user answers the self-report check-in
        await sut.viewModel.submitSelfReport(report)

        // Then the verdict is recorded from their own account
        let recorded = try #require(await sut.caseStore.recordedDrafts.first)
        #expect(recorded.decision.category == expected)
        #expect(recorded.decision.basis == .selfReported(report))
    }

    @Test("Skipping the self-report check-in produces a provisional balanced verdict")
    func skippingSelfReportIsProvisionalBalanced() async throws {
        // Given no usable recorded comparison at all
        let sut = makeSUT(snapshot: SyntheticScenarios.noHealthData.snapshot)
        await sut.viewModel.requestVerdict()

        // When the user skips the check-in
        await sut.viewModel.submitSelfReport(nil)

        // Then the verdict is a provisional balanced, not a guess dressed up as a real one
        let recorded = try #require(await sut.caseStore.recordedDrafts.first)
        #expect(recorded.decision.category == .balanced)
        #expect(recorded.decision.isProvisional)
        #expect(recorded.decision.basis == .provisional)
    }

    // MARK: - Reading failures

    @Test("A failed evidence read is reported honestly, and nothing is recorded")
    func evidenceReadFailureReportsHonestly() async {
        // Given a Health read that will not complete
        let sut = makeSUT(evidenceFailure: FixtureFailure("the read did not complete"))

        // When a verdict is requested
        await sut.viewModel.requestVerdict()

        // Then the failure is visible, and nothing was recorded
        guard case .evidenceUnavailable = sut.viewModel.stage else {
            Issue.record("Expected .evidenceUnavailable, got \(sut.viewModel.stage.logLabel)")
            return
        }
        #expect(await sut.caseStore.recordedDrafts.isEmpty)
    }

    @Test("A cancelled evidence read puts back gathering, not a failure the user did not cause")
    func cancelledEvidenceReadRevertsToGathering() async {
        // Given a Health read that is cancelled rather than failing
        let sut = makeSUT(evidenceFailure: CancellationError())

        // When a verdict is requested
        await sut.viewModel.requestVerdict()

        // Then the user is back where they started
        guard case .gathering = sut.viewModel.stage else {
            Issue.record("Expected .gathering, got \(sut.viewModel.stage.logLabel)")
            return
        }
    }

    // MARK: - Saving

    @Test("A failed save keeps the computed decision visible, with a retry")
    func failedSaveKeepsDecisionVisible() async {
        // Given a store that will refuse the write
        let sut = makeSUT(snapshot: SyntheticScenarios.activeDay.snapshot, recordFailure: FoodgeError.saveFailed)

        // When a verdict is requested
        await sut.viewModel.requestVerdict()

        // Then the computed decision stays visible with the failure, never reported as saved
        guard case let .saveFailed(draft, error) = sut.viewModel.stage else {
            Issue.record("Expected .saveFailed, got \(sut.viewModel.stage.logLabel)")
            return
        }
        #expect(error == .saveFailed)
        #expect(draft.decision.category == .treat)
    }

    @Test("Retrying a failed save with the same draft can complete it")
    func retryingFailedSaveCanSucceed() async {
        // Given a save that failed
        let sut = makeSUT(snapshot: SyntheticScenarios.activeDay.snapshot, recordFailure: FoodgeError.saveFailed)
        await sut.viewModel.requestVerdict()
        guard case let .saveFailed(originalDraft, _) = sut.viewModel.stage else {
            Issue.record("Expected the first save to fail")
            return
        }

        // When the store recovers and the user retries
        await sut.caseStore.stopFailing()
        await sut.viewModel.retrySave()

        // Then the same draft is recorded, once
        guard case .verdict = sut.viewModel.stage else {
            Issue.record("Expected .verdict after a successful retry")
            return
        }
        #expect(await sut.caseStore.recordedDrafts.count == 1)
        #expect(await sut.caseStore.recordedDrafts.first?.decision == originalDraft.decision)
    }

    // MARK: - The dish pick

    @Test("A no-match dish selection still reaches a verdict, honestly")
    func noMatchDishSelectionStillReachesVerdict() async throws {
        // Given constraints that leave no balanced-family variant compatible
        let draft = PreferencesDraft(
            dietProfile: .vegan,
            excludedIngredientIDs: [Ingredient.rice.id, Ingredient.pasta.id]
        )
        let sut = makeSUT(snapshot: SyntheticScenarios.typicalDay.snapshot, preferencesDraft: draft)

        // When a verdict is requested
        await sut.viewModel.requestVerdict()

        // Then the category still rules, but the dish outcome honestly reports no match —
        // nothing is invented to fill the gap
        guard case .verdict = sut.viewModel.stage else {
            Issue.record("Expected .verdict, got \(sut.viewModel.stage.logLabel)")
            return
        }
        let recorded = try #require(await sut.caseStore.recordedDrafts.first)
        guard case .noMatch = recorded.dishOutcome else {
            Issue.record("Expected a .noMatch dish outcome")
            return
        }
    }

    // MARK: - The note

    @Test("An oversized note is dropped safely, never force-unwrapped")
    func oversizedNoteIsDroppedSafely() async throws {
        // Given a note one character over the limit
        let sut = makeSUT(snapshot: SyntheticScenarios.typicalDay.snapshot)
        sut.viewModel.noteText = String(repeating: "a", count: Note.maximumLength + 1)

        // When a verdict is requested
        await sut.viewModel.requestVerdict()

        // Then the context carries no note — `Note(_:)`'s failable init was respected, not
        // bypassed with a force unwrap
        let context = try #require(await sut.evidence.receivedContexts.first)
        #expect(context.note == nil)
    }
}

// MARK: - Fixtures

/// Returns a scripted snapshot and remembers exactly what it was asked for — duplicated from
/// `OnboardingViewModelTests`' fixture of the same shape rather than shared, per this suite's own
/// scope.
private actor TodayFixtureEvidenceProvider: HealthEvidenceProvider {
    private let result: Result<EvidenceSnapshot, any Error>
    private(set) var callCount = 0
    private(set) var receivedContexts: [DailyContext] = []
    private(set) var receivedConstraints: [DietaryConstraints] = []

    init(snapshot: EvidenceSnapshot) {
        result = .success(snapshot)
    }

    init(failure: any Error) {
        result = .failure(failure)
    }

    func snapshot(
        at _: Date,
        calendar _: Calendar,
        context: DailyContext,
        constraints: DietaryConstraints
    ) async throws -> EvidenceSnapshot {
        callCount += 1
        receivedContexts.append(context)
        receivedConstraints.append(constraints)
        return try result.get()
    }
}

/// Holds one draft in memory, standing in for the saved preferences `TodayViewModel` reads.
private actor TodayFixturePreferencesStore: PreferencesStore {
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

/// A scripted `CaseStore`: one seeded case to reopen, and every recorded revision kept for
/// assertion — the seam that proves a failed save is never reported as saved.
private actor TodayFixtureCaseStore: CaseStore {
    private let seeded: SavedCase?
    private var recordFailure: (any Error)?
    private(set) var recordedDrafts: [NewRevisionDraft] = []

    init(seeded: SavedCase?, recordFailure: (any Error)?) {
        self.seeded = seeded
        self.recordFailure = recordFailure
    }

    /// Lets a scripted failure be cleared, so a retry can be exercised.
    func stopFailing() {
        recordFailure = nil
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

    func recordAppeal(_: AppealDraft, to _: UUID) async throws {
        // Not exercised this suite — see `TodayAppealViewModelTests`.
    }

    func allCases() async throws -> [SavedCase] {
        // Not exercised this suite — see `HistoryViewModelTests`.
        []
    }
}
