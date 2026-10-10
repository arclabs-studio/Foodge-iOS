//
//  TodayRevealViewModelTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 10/10/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The verdict reveal — stamp slam, dish pop, confetti — plays once per saved revision.
///
/// `claimReveal()` is what the verdict screen asks each time it appears; `isRevealPending` reads the
/// same state without spending it. The oracle is the specified answer — `true` on the first ask for
/// a saved revision, `false` on every other ask — and revision ids are asserted only where a test
/// needs two distinct revisions, to prove the second one really is new.
///
/// This suite pins the view model's half of the contract. `claimReveal()` takes no navigation
/// input, so what can be shown here is that changing `path` does not reset it; that the screen asks
/// once per appearance and honours the answer is the view's half, owed to the simulator walk.
///
/// Fixtures are this suite's own, per the codebase's per-suite convention: `TodayViewModelTests`'
/// case store is private to that file, and this one has to hand back a narrated revision as well.
@Suite("Today reveal", .tags(.unit, .critical))
@MainActor
struct TodayRevealViewModelTests {
    /// How the verdict screen came to have a saved revision to show.
    enum Arrival: String, CaseIterable {
        /// The user asked for a verdict and the store recorded it.
        case requested
        /// A case already saved for today was reopened without reading Health.
        case reopened
    }

    private struct SUT {
        let viewModel: TodayViewModel
        let caseStore: RevealFixtureCaseStore
    }

    private func makeSUT(
        snapshot: EvidenceSnapshot = SyntheticScenarios.generousAllowance.snapshot,
        seededCase: SavedCase? = nil,
        recordFailure: (any Error)? = nil,
        narration: String? = nil
    ) -> SUT {
        let caseStore = RevealFixtureCaseStore(seeded: seededCase, recordFailure: recordFailure)

        return SUT(
            viewModel: TodayViewModel(
                evidence: FixtureEvidenceProvider(snapshot: snapshot),
                preferences: FixturePreferencesStore(),
                caseStore: caseStore,
                clock: SyntheticScenarios.clock,
                narrator: RevealFixtureNarrator(line: narration)
            ),
            caseStore: caseStore
        )
    }

    /// A case already saved for today, with one revision that carries no narration.
    private static func seededCase() -> SavedCase {
        let evidence = SyntheticScenarios.modestAllowance.snapshot
        let revision = SavedRevision(
            id: UUID(),
            sequence: 0,
            createdAt: evidence.evaluatedAt,
            decision: VerdictDecision(
                category: .balanced,
                basis: .provisional,
                reasonCodes: [.checkInSkipped],
                isProvisional: true,
                ruleVersion: CheatMealAllowanceRule.ruleVersion
            ),
            evidence: evidence,
            catalogueVersion: DishCatalogue.version,
            dishOutcome: PersistedDishOutcome(
                variantID: "dish.pasta.pesto",
                family: .pasta,
                alternativeVariantID: nil,
                alternativeFamily: nil
            ),
            narrationText: nil
        )
        return SavedCase(localDayKey: "2026-09-18", revisions: [revision])
    }

    /// Brings a view model to `.verdict` the way the given arrival does, and returns the revision it
    /// is showing. Failing here means the scenario did not happen, so no assertion after it can be
    /// trusted — which is why it throws rather than records.
    private func arrive(_ arrival: Arrival, in sut: SUT) async throws -> SavedRevision {
        switch arrival {
        case .requested:
            await sut.viewModel.requestVerdict()
        case .reopened:
            await sut.viewModel.onAppear()
        }
        return try #require(
            sut.viewModel.currentRevision,
            "Expected a saved revision after the view model arrived by \(arrival.rawValue)."
        )
    }

    // MARK: - Nothing to reveal

    @Test("With no saved revision there is nothing to reveal")
    func noRevisionMeansNoReveal() {
        // Given a view model that has not been asked for anything
        let sut = makeSUT()
        guard case .gathering = sut.viewModel.stage else {
            Issue.record("Expected .gathering, got \(sut.viewModel.stage.logLabel)")
            return
        }

        // When the verdict screen asks
        let claimed = sut.viewModel.claimReveal()

        // Then it is told not to play: a reveal with no revision would stamp a verdict that does
        // not exist
        #expect(claimed == false, "A view model with no saved revision must not play the reveal.")
    }

    @Test("A verdict that failed to save is shown settled, never revealed")
    func failedSaveMeansNoReveal() async {
        // Given a store that refuses the write, so the decision is computed and on screen but no
        // revision exists
        let sut = makeSUT(recordFailure: FoodgeError.saveFailed)
        await sut.viewModel.requestVerdict()
        guard case .saveFailed = sut.viewModel.stage else {
            Issue.record("Expected .saveFailed, got \(sut.viewModel.stage.logLabel)")
            return
        }
        #expect(sut.viewModel.path == [.verdict], "The verdict screen should be up, showing the failed save.")

        // When the verdict screen asks
        let claimed = sut.viewModel.claimReveal()

        // Then it settles: celebrating a verdict that was not saved would be the one thing worse
        // than not celebrating a saved one
        #expect(claimed == false, "An unsaved verdict has no revision, so it must not play the reveal.")
    }

    @Test("A failed save does not spend the reveal — the retry that succeeds still plays it")
    func failedSaveDoesNotSpendTheReveal() async throws {
        // Given a save that failed, with the screen having asked before and after the failure
        let sut = makeSUT(recordFailure: FoodgeError.saveFailed)
        let beforeAnyVerdict = sut.viewModel.claimReveal()
        await sut.viewModel.requestVerdict()
        let whileUnsaved = sut.viewModel.claimReveal()
        #expect(beforeAnyVerdict == false)
        #expect(whileUnsaved == false)

        // When the store recovers and the retry lands the one revision
        await sut.caseStore.stopFailing()
        await sut.viewModel.retrySave()
        let saved = try #require(sut.viewModel.currentRevision, "The retry should have saved a revision.")
        #expect(await sut.caseStore.recordedDrafts.count == 1)

        // Then the first ask for that revision plays the reveal, and the next one does not: the
        // asks that found nothing to reveal were not the reveal
        let first = sut.viewModel.claimReveal()
        let second = sut.viewModel.claimReveal()
        #expect(first, "Asks made before a revision exists must not use up the reveal for \(saved.id).")
        #expect(second == false, "The reveal for \(saved.id) must play only once.")
    }

    // MARK: - Once per revision

    @Test(
        "The first ask for a saved revision plays the reveal, and every later ask does not",
        arguments: Arrival.allCases
    )
    func firstAskPlaysThenSettles(arrival: Arrival) async throws {
        // Given a verdict reached by the given arrival
        let sut = makeSUT(seededCase: arrival == .reopened ? Self.seededCase() : nil)
        let revision = try await arrive(arrival, in: sut)

        // When the verdict screen asks three times
        let first = sut.viewModel.claimReveal()
        let second = sut.viewModel.claimReveal()
        let third = sut.viewModel.claimReveal()

        // Then only the first ask plays the reveal
        #expect(first, "The first ask for revision \(revision.id) (\(arrival.rawValue)) must play the reveal.")
        #expect(second == false, "The second ask for revision \(revision.id) must not replay it.")
        #expect(third == false, "The third ask for revision \(revision.id) must not replay it.")
    }

    @Test("A second revision in the same view model plays the reveal again, once")
    func newRevisionPlaysTheRevealAgain() async throws {
        // Given a verdict whose reveal has been played
        let sut = makeSUT()
        await sut.viewModel.requestVerdict()
        let firstRevision = try #require(sut.viewModel.currentRevision)
        let firstReveal = sut.viewModel.claimReveal()
        try #require(firstReveal, "The first revision's reveal should have played.")
        let settled = sut.viewModel.claimReveal()
        #expect(settled == false)

        // When a further verdict is requested and the store records it as a new revision. The
        // store's own answer is the oracle for "new": the ids must differ, or this proves nothing
        await sut.viewModel.requestVerdict()
        let secondRevision = try #require(sut.viewModel.currentRevision)
        try #require(
            firstRevision.id != secondRevision.id,
            "The store should have recorded a distinct revision, not handed back \(firstRevision.id) again."
        )
        #expect(await sut.caseStore.recordedDrafts.count == 2)

        // Then the new revision plays its own reveal on its first ask — and only its first
        let newFirst = sut.viewModel.claimReveal()
        let newSecond = sut.viewModel.claimReveal()
        #expect(newFirst, "Revision \(secondRevision.id) is new, so its first ask must play the reveal.")
        #expect(newSecond == false, "Revision \(secondRevision.id) must play its reveal only once.")
    }

    // MARK: - Pending

    @Test("The reveal is not pending without a saved revision, before a verdict and during a failed save")
    func revealIsNotPendingWithoutASavedRevision() async {
        // Given a view model with nothing asked of it, and a store that will refuse the write
        let sut = makeSUT(recordFailure: FoodgeError.saveFailed)

        // When it is read before any verdict
        let whileGathering = sut.viewModel.isRevealPending

        // Then there is nothing to reveal
        #expect(whileGathering == false, "Nothing is pending before a verdict exists.")

        // When the verdict is computed but the save fails
        await sut.viewModel.requestVerdict()
        guard case .saveFailed = sut.viewModel.stage else {
            Issue.record("Expected .saveFailed, got \(sut.viewModel.stage.logLabel)")
            return
        }
        let whileUnsaved = sut.viewModel.isRevealPending

        // Then there is still no saved revision, so still nothing to reveal
        #expect(whileUnsaved == false, "An unsaved verdict has no revision, so no reveal is pending.")
    }

    @Test("The reveal is pending from a saved revision until it is claimed, and reading that spends nothing")
    func revealIsPendingUntilClaimedAndReadingSpendsNothing() async throws {
        // Given a saved revision whose reveal nobody has claimed
        let sut = makeSUT()
        await sut.viewModel.requestVerdict()
        let firstRevision = try #require(sut.viewModel.currentRevision)

        // When the pending state is read twice
        let pending = sut.viewModel.isRevealPending
        let pendingAgain = sut.viewModel.isRevealPending

        // Then it is pending both times, and reading it has spent nothing: the claim still plays
        #expect(pending, "A saved revision nobody has claimed has its reveal pending.")
        #expect(pendingAgain, "Reading isRevealPending must not change it.")
        let claimed = sut.viewModel.claimReveal()
        #expect(claimed, "Reading isRevealPending must not spend the reveal for \(firstRevision.id).")

        // When the claim has been made
        let afterClaim = sut.viewModel.isRevealPending

        // Then nothing is pending
        #expect(afterClaim == false, "Once \(firstRevision.id) is claimed its reveal is no longer pending.")

        // When a further verdict is recorded as a new revision
        await sut.viewModel.requestVerdict()
        let secondRevision = try #require(sut.viewModel.currentRevision)
        try #require(
            firstRevision.id != secondRevision.id,
            "The store should have recorded a distinct revision, not handed back \(firstRevision.id) again."
        )
        let pendingForSecond = sut.viewModel.isRevealPending

        // Then its reveal is pending, and claiming it clears it again
        #expect(pendingForSecond, "Revision \(secondRevision.id) is new, so its reveal is pending.")
        let claimedSecond = sut.viewModel.claimReveal()
        let afterSecondClaim = sut.viewModel.isRevealPending
        #expect(claimedSecond, "Revision \(secondRevision.id) should play its reveal once.")
        #expect(afterSecondClaim == false, "Once \(secondRevision.id) is claimed nothing is pending.")
    }

    // MARK: - Navigation

    @Test("claimReveal ignores navigation: changing the path never makes a claimed reveal pending again")
    func claimRevealIgnoresNavigation() async throws {
        // Given a verdict whose reveal has played
        let sut = makeSUT()
        let revision = try await arrive(.requested, in: sut)
        let firstAsk = sut.viewModel.claimReveal()
        try #require(firstAsk, "The reveal should have played on the first ask for \(revision.id).")

        // When the path is pushed and popped, the way opening and closing Evidence details does,
        // and the verdict screen asks as it reappears
        sut.viewModel.path.append(.evidenceDetails)
        sut.viewModel.path.removeLast()
        let afterEvidence = sut.viewModel.claimReveal()

        // And the path is emptied and the verdict pushed again, the way going back to Today and
        // opening "Tonight's verdict" does, and the screen asks as it reappears
        sut.viewModel.path.removeAll()
        sut.viewModel.path.append(.verdict)
        let afterToday = sut.viewModel.claimReveal()

        // Then neither return replays the reveal: the revision is the one already claimed
        #expect(afterEvidence == false, "Returning from Evidence details must not replay the reveal for \(revision.id).")
        #expect(afterToday == false, "Returning from Today must not replay the reveal for \(revision.id).")
    }

    @Test("A narration line arriving on the same revision does not replay the reveal")
    func narrationArrivingDoesNotReplay() async throws {
        // Given a reopened verdict whose reveal has played
        let line = "The court finds the defence charming."
        let sut = makeSUT(seededCase: Self.seededCase(), narration: line)
        let revision = try await arrive(.reopened, in: sut)
        let firstAsk = sut.viewModel.claimReveal()
        try #require(firstAsk, "The reveal should have played on the first ask for \(revision.id).")

        // When the flourish lands: the store hands back the same revision with its narration
        // attached, so the view model now holds a different `SavedRevision` value with the same id
        await sut.viewModel.narrateIfNeeded()
        let narrated = try #require(sut.viewModel.currentRevision)
        let narratedText = try #require(narrated.narrationText, "The narration should have been attached.")
        try #require(narratedText == line, "The attached narration should be the scripted line.")
        try #require(narrated.id == revision.id, "Attaching narration must not mint a new revision.")
        try #require(narrated != revision, "The revision value should differ, or this proves nothing.")

        // Then the screen asking again is told to settle: a narration line is not a new verdict
        let afterNarration = sut.viewModel.claimReveal()
        #expect(afterNarration == false, "Narration arriving on \(revision.id) must not replay the reveal.")
    }
}

// MARK: - Fixtures

/// Answers with a scripted flourish, so a narration line can be attached to a revision on cue.
private struct RevealFixtureNarrator: VerdictNarrator {
    let line: String?

    func flourish(for _: VerdictDecision, dishName _: String) async -> String? {
        line
    }
}

/// A scripted `CaseStore`: one seeded case to reopen, a new revision with a fresh id for every
/// recorded draft, and the same revision handed back with its narration attached.
///
/// Mirrors what `PersistenceActor` does — it appends a revision per `recordRevision` call and
/// returns the updated revision from `attachNarration` — but can be told to refuse a write, which
/// an in-memory container never does.
private actor RevealFixtureCaseStore: CaseStore {
    private let seeded: SavedCase?
    private var recordFailure: (any Error)?
    private var revisions: [SavedRevision]
    private(set) var recordedDrafts: [NewRevisionDraft] = []

    init(seeded: SavedCase?, recordFailure: (any Error)?) {
        self.seeded = seeded
        self.recordFailure = recordFailure
        revisions = seeded?.revisions ?? []
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
        let saved = SavedRevision(
            id: UUID(),
            sequence: revisions.count,
            createdAt: draft.evidence.evaluatedAt,
            decision: draft.decision,
            evidence: draft.evidence,
            catalogueVersion: draft.catalogueVersion,
            dishOutcome: draft.dishOutcome,
            narrationText: nil
        )
        revisions.append(saved)
        return saved
    }

    @discardableResult
    func attachNarration(_ text: String, to revisionID: UUID) async throws -> SavedRevision {
        guard let index = revisions.firstIndex(where: { $0.id == revisionID }) else {
            throw FoodgeError.revisionNotFound
        }
        let updated = revisions[index].attachingNarration(text)
        revisions[index] = updated
        return updated
    }

    func allCases() async throws -> [SavedCase] {
        // Not exercised this suite — see `HistoryViewModelTests`.
        []
    }
}
