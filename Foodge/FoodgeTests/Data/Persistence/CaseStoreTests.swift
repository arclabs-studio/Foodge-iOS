//
//  CaseStoreTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Foodge

/// Reopening a case without regenerating it, an honest new revision on every explicit save, and
/// an appeal that never drifts onto the wrong revision are the whole contract `CaseStore` exists
/// to keep.
@Suite("Case store", .tags(.integration, .critical))
struct CaseStoreTests {

    // MARK: - Fixtures

    private func makeSUT() throws -> PersistenceActor {
        PersistenceActor(modelContainer: try ContainerFactory.makeInMemory())
    }

    private func makeStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "FoodgeTests-\(UUID().uuidString)")
            .appendingPathExtension("store")
    }

    private func makeEvidence(day: Int, hour: Int = 19, minute: Int = 30) -> EvidenceSnapshot {
        EvidenceSnapshot(
            evaluatedAt: TestCalendar.date(2026, 9, day, hour, minute),
            timeZoneIdentifier: "Europe/Madrid",
            today: .empty,
            history: [],
            availability: .readable(missing: [])
        )
    }

    private func makeDecision(category: DinnerCategory = .balanced) -> VerdictDecision {
        VerdictDecision(
            category: category,
            basis: .provisional,
            reasonCodes: [.checkInSkipped],
            isProvisional: true,
            ruleVersion: "1.0.0"
        )
    }

    private func makeDishOutcome(variantID: String = "burger.classic") -> PersistedDishOutcome {
        .selected(variantID: variantID, family: .burgers, alternativeVariantID: nil, alternativeFamily: nil)
    }

    private func makeDraft(
        evidence: EvidenceSnapshot,
        decision: VerdictDecision? = nil,
        catalogueVersion: String = "1.0.0",
        dishOutcome: PersistedDishOutcome? = nil
    ) -> NewRevisionDraft {
        NewRevisionDraft(
            decision: decision ?? makeDecision(),
            evidence: evidence,
            catalogueVersion: catalogueVersion,
            dishOutcome: dishOutcome ?? makeDishOutcome()
        )
    }

    // MARK: - Reopening

    @Test("Reopening returns the saved decision without regenerating")
    func reopeningReturnsTheSavedDecision() async throws {
        // Given a revision recorded for one day's evidence
        let sut = try makeSUT()
        let evidence = makeEvidence(day: 5)
        let draft = makeDraft(evidence: evidence, decision: makeDecision(category: .treat))

        try await sut.recordRevision(draft)

        // When that same evidence is used to reopen the case
        let saved = try await sut.savedCase(matching: evidence)

        // Then it returns exactly the recorded decision, catalogue version and dish outcome —
        // never a freshly regenerated one
        let stored = try #require(saved)
        #expect(stored.revisions.count == 1)
        let revision = try #require(stored.latestRevision)
        #expect(revision.decision == draft.decision)
        #expect(revision.evidence == draft.evidence)
        #expect(revision.catalogueVersion == draft.catalogueVersion)
        #expect(revision.dishOutcome == draft.dishOutcome)
        #expect(revision.sequence == 0)
    }

    @Test("An unrecorded day returns no saved case")
    func anUnrecordedDayReturnsNoSavedCase() async throws {
        // Given a store with nothing recorded
        let sut = try makeSUT()

        // When a day that was never saved is looked up
        let saved = try await sut.savedCase(matching: makeEvidence(day: 9))

        // Then there is nothing to reopen
        #expect(saved == nil)
    }

    // MARK: - Revisions

    @Test("An explicit second save creates a new revision, the first preserved")
    func aSecondSaveCreatesANewRevision() async throws {
        // Given a case already recorded for one day
        let sut = try makeSUT()
        let evidence = makeEvidence(day: 5)
        let first = makeDraft(evidence: evidence, decision: makeDecision(category: .treat))
        try await sut.recordRevision(first)

        // When an explicit second save records different evidence for the same local day
        let secondEvidence = makeEvidence(day: 5, hour: 20, minute: 0)
        let second = makeDraft(evidence: secondEvidence, decision: makeDecision(category: .light))
        try await sut.recordRevision(second)

        // Then both revisions exist in order, and the first is unchanged
        let saved = try #require(try await sut.savedCase(matching: evidence))
        #expect(saved.revisions.count == 2)

        let ordered = saved.revisions.sorted { $0.sequence < $1.sequence }
        #expect(ordered[0].sequence == 0)
        #expect(ordered[0].decision == first.decision)
        #expect(ordered[0].evidence == first.evidence)
        #expect(ordered[1].sequence == 1)
        #expect(ordered[1].decision == second.decision)
    }

    @Test("Two different local days never collide")
    func twoDifferentLocalDaysNeverCollide() async throws {
        // Given revisions recorded for two consecutive days
        let sut = try makeSUT()
        let dayFive = makeEvidence(day: 5)
        let daySix = makeEvidence(day: 6)
        try await sut.recordRevision(makeDraft(evidence: dayFive, decision: makeDecision(category: .treat)))
        try await sut.recordRevision(makeDraft(evidence: daySix, decision: makeDecision(category: .light)))

        // When each day is looked up on its own
        let savedFive = try #require(try await sut.savedCase(matching: dayFive))
        let savedSix = try #require(try await sut.savedCase(matching: daySix))

        // Then each surfaces only its own revision
        #expect(savedFive.revisions.count == 1)
        #expect(savedFive.latestRevision?.decision.category == .treat)
        #expect(savedSix.revisions.count == 1)
        #expect(savedSix.latestRevision?.decision.category == .light)
    }

    // MARK: - Appeals

    @Test("An appeal attaches to one specific revision")
    func anAppealAttachesToOneSpecificRevision() async throws {
        // Given two revisions recorded for one day
        let sut = try makeSUT()
        let evidence = makeEvidence(day: 5)
        let firstRevision = try await sut.recordRevision(makeDraft(evidence: evidence, decision: makeDecision(category: .treat)))
        let secondEvidence = makeEvidence(day: 5, hour: 20, minute: 0)
        let secondRevision = try await sut.recordRevision(makeDraft(evidence: secondEvidence, decision: makeDecision(category: .light)))

        // When an appeal is recorded against the first revision only
        let appeal = AppealDraft(createdAt: evidence.evaluatedAt, choice: .catalogue(variantID: "tacos.classic", family: .tacos))
        try await sut.recordAppeal(appeal, to: firstRevision.id)

        // Then only that revision shows the appeal
        let saved = try #require(try await sut.savedCase(matching: evidence))
        let reloadedFirst = try #require(saved.revisions.first { $0.id == firstRevision.id })
        let reloadedSecond = try #require(saved.revisions.first { $0.id == secondRevision.id })
        #expect(reloadedFirst.appeals.count == 1)
        #expect(reloadedFirst.appeals.first?.choice == appeal.choice)
        #expect(reloadedSecond.appeals.isEmpty)
    }

    @Test("An unknown revision id fails honestly")
    func anUnknownRevisionIDFailsHonestly() async throws {
        // Given a case with one recorded revision
        let sut = try makeSUT()
        let evidence = makeEvidence(day: 5)
        let revision = try await sut.recordRevision(makeDraft(evidence: evidence))

        // When an appeal is addressed to a revision id that does not exist
        let appeal = AppealDraft(createdAt: evidence.evaluatedAt, choice: .freeText("Grandma's paella"))
        await #expect(throws: FoodgeError.revisionNotFound) {
            try await sut.recordAppeal(appeal, to: UUID())
        }

        // Then nothing was recorded against the real revision either
        let saved = try #require(try await sut.savedCase(matching: evidence))
        let reloaded = try #require(saved.revisions.first { $0.id == revision.id })
        #expect(reloaded.appeals.isEmpty)
    }

    // MARK: - Real store reopening

    @Test("A revision written to a real store is still there when it is reopened")
    func revisionsSurviveContainerReopen() async throws {
        // Given a revision recorded through one container at an on-disk location
        let url = makeStoreURL()
        let evidence = makeEvidence(day: 5)
        let draft = makeDraft(evidence: evidence, decision: makeDecision(category: .treat))

        let first = try ContainerFactory.make(at: url)
        try await PersistenceActor(modelContainer: first).recordRevision(draft)

        // When a completely separate container is opened on the same file
        let second = try ContainerFactory.make(at: url)
        let reloaded = try await PersistenceActor(modelContainer: second).savedCase(matching: evidence)

        // Then the revision is still there, intact
        let stored = try #require(reloaded)
        #expect(stored.revisions.count == 1)
        #expect(stored.latestRevision?.decision == draft.decision)
        #expect(stored.latestRevision?.evidence == draft.evidence)
        #expect(stored.latestRevision?.dishOutcome == draft.dishOutcome)
    }

    // MARK: - Failure honesty

    @Test("A failed save is reported as a thrown error, never a false success")
    func aFailedSaveIsNeverReportedAsASuccess() async throws {
        // Given a case already recorded in a real, on-disk store, then closed
        let url = makeStoreURL()
        try await PersistenceActor(modelContainer: try ContainerFactory.make(at: url))
            .recordRevision(makeDraft(evidence: makeEvidence(day: 5)))

        // When the store file is made read-only before a fresh connection opens it — an already
        // open connection keeps a permission check made at open time, so the write has to come
        // from a new one to genuinely fail. Assumes the test runs as a normal user, not root:
        // root bypasses 0o444, which would fail this test loudly rather than falsely pass it.
        let storePath = url.path(percentEncoded: false)
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: storePath)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: storePath) }

        // Then the failure is reported as ``FoodgeError/saveFailed`` — never silently as a save
        await #expect(throws: FoodgeError.saveFailed) {
            let sut = PersistenceActor(modelContainer: try ContainerFactory.make(at: url))
            try await sut.recordRevision(makeDraft(evidence: makeEvidence(day: 6)))
        }
    }
}
