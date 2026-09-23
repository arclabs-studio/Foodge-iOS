//
//  TodayNarrationViewModelTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 23/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// Narration must never perturb the verdict, never speak when the user turned it off, never
/// attach a line to the wrong revision, and never surface a failure to the user.
///
/// Fixtures are this suite's own, per the codebase's per-suite convention — the narrator and case
/// store here both record more than the other Today suites need.
@Suite("Today narration", .tags(.unit, .critical))
@MainActor
struct TodayNarrationViewModelTests {
    private struct SUT {
        let viewModel: TodayViewModel
        let narrator: NarrationFixtureNarrator
        let caseStore: NarrationFixtureCaseStore
    }

    private func makeSUT(
        scripted: String? = "The court finds the defence charming.",
        narrationEnabled: Bool = true,
        dishOutcome: PersistedDishOutcome = .selected(
            variantID: "dish.pasta.pesto",
            family: .pasta,
            alternativeVariantID: nil,
            alternativeFamily: nil
        ),
        note: Note? = nil,
        attachFailure: (any Error)? = nil,
        beforeNarratorReturns: (@Sendable () async -> Void)? = nil
    ) -> SUT {
        let evidence = Self.evidence(note: note)
        let revision = Self.revision(evidence: evidence, dishOutcome: dishOutcome)
        let caseStore = NarrationFixtureCaseStore(
            seeded: SavedCase(localDayKey: "2026-09-18", revisions: [revision]),
            attachFailure: attachFailure
        )
        let narrator = NarrationFixtureNarrator(scripted: scripted, beforeReturn: beforeNarratorReturns)

        return SUT(
            viewModel: TodayViewModel(
                evidence: NarrationFixtureEvidenceProvider(snapshot: evidence),
                preferences: NarrationFixturePreferencesStore(
                    draft: PreferencesDraft(narrationEnabled: narrationEnabled)
                ),
                caseStore: caseStore,
                clock: SyntheticScenarios.clock,
                narrator: narrator
            ),
            narrator: narrator,
            caseStore: caseStore
        )
    }

    private static func evidence(note: Note?) -> EvidenceSnapshot {
        let base = SyntheticScenarios.typicalDay.snapshot
        return EvidenceSnapshot(
            evaluatedAt: base.evaluatedAt,
            timeZoneIdentifier: base.timeZoneIdentifier,
            today: base.today,
            history: base.history,
            availability: base.availability,
            context: DailyContext(note: note),
            constraints: base.constraints,
            trackingRepresentative: base.trackingRepresentative,
            isSynthetic: base.isSynthetic
        )
    }

    private static func revision(
        evidence: EvidenceSnapshot,
        dishOutcome: PersistedDishOutcome
    ) -> SavedRevision {
        SavedRevision(
            id: UUID(),
            sequence: 0,
            createdAt: evidence.evaluatedAt,
            decision: VerdictDecision(
                category: .balanced,
                basis: .provisional,
                reasonCodes: [.checkInSkipped],
                isProvisional: true,
                ruleVersion: DinnerCategoryRule.ruleVersion
            ),
            evidence: evidence,
            catalogueVersion: DishCatalogue.version,
            dishOutcome: dishOutcome,
            narrationText: nil,
            appeals: []
        )
    }

    // MARK: - The happy path

    @Test("A validated line is shown and attached to the revision it belongs to")
    func aValidatedLineIsShownAndAttached() async throws {
        // Given a reopened verdict and a narrator that answers cleanly
        let sut = makeSUT()
        await sut.viewModel.onAppear()
        let revisionID = try #require(sut.viewModel.currentRevision?.id)

        // When narration runs
        await sut.viewModel.narrateIfNeeded()

        // Then the line is on screen, and it was attached to that exact revision
        #expect(sut.viewModel.narrationStage == .narrated("The court finds the defence charming."))
        #expect(sut.viewModel.narrationStage.text == "The court finds the defence charming.")
        let attached = try #require(await sut.caseStore.attached.first)
        #expect(await sut.caseStore.attached.count == 1)
        #expect(attached.revisionID == revisionID)
        #expect(attached.text == "The court finds the defence charming.")
        #expect(sut.viewModel.currentRevision?.narrationText == "The court finds the defence charming.")
    }

    @Test("Narration never perturbs the verdict")
    func narrationNeverPerturbsTheVerdict() async throws {
        // Given a reopened verdict
        let sut = makeSUT()
        await sut.viewModel.onAppear()
        let before = try #require(sut.viewModel.currentDisplay)

        // When narration runs
        await sut.viewModel.narrateIfNeeded()

        // Then the category, dish and evidence on screen are untouched, and the flow is still at
        // a verdict — the reason narration has its own stage rather than a `Stage` case
        let after = try #require(sut.viewModel.currentDisplay)
        #expect(after.decision == before.decision)
        #expect(after.dishOutcome == before.dishOutcome)
        #expect(after.evidence == before.evidence)
        guard case .verdict = sut.viewModel.stage else {
            Issue.record("Expected .verdict, got \(sut.viewModel.stage.logLabel)")
            return
        }
    }

    @Test("A second run asks the narrator nothing")
    func narrationRunsOncePerVerdict() async {
        // Given narration that already ran — `.task` re-fires on every tab revisit (D69)
        let sut = makeSUT()
        await sut.viewModel.onAppear()
        await sut.viewModel.narrateIfNeeded()

        // When the screen reappears and narration is asked for again
        await sut.viewModel.narrateIfNeeded()

        // Then the model was asked exactly once, and the shown line did not change
        #expect(await sut.narrator.callCount == 1)
        #expect(sut.viewModel.narrationStage == .narrated("The court finds the defence charming."))
    }

    // MARK: - When narration must not run at all

    @Test("Narration turned off never reaches the narrator")
    func narrationDisabledNeverReachesTheNarrator() async {
        // Given a user whose preferences have narration switched off
        let sut = makeSUT(narrationEnabled: false)
        await sut.viewModel.onAppear()

        // When narration is asked for
        await sut.viewModel.narrateIfNeeded()

        // Then the model was never asked, and the template shows
        #expect(await sut.narrator.callCount == 0)
        #expect(sut.viewModel.narrationStage == .template)
        #expect(sut.viewModel.narrationStage.text == nil)
    }

    @Test("A no-match night never reaches the narrator")
    func noMatchNeverReachesTheNarrator() async {
        // Given a night where no catalogue dish matched
        let sut = makeSUT(dishOutcome: .noMatch(blockingIngredientIDs: [Ingredient.rice.id]))
        await sut.viewModel.onAppear()

        // When narration is asked for
        await sut.viewModel.narrateIfNeeded()

        // Then there was no dish to be playful about, so nothing was generated — inventing one
        // would contradict the honest no-match the product rule requires
        #expect(await sut.narrator.callCount == 0)
        #expect(sut.viewModel.narrationStage == .template)
    }

    // MARK: - What the narrator is given

    @Test("The narrator receives the dish name, never the stored variant id")
    func narratorReceivesTheResolvedDishName() async throws {
        // Given a verdict for a catalogue dish
        let sut = makeSUT()
        await sut.viewModel.onAppear()

        // When narration runs
        await sut.viewModel.narrateIfNeeded()

        // Then the name handed over is the catalogue's own display name for that variant — a raw
        // id must never reach prose
        let entry = try #require(DishCatalogue.entries.first { $0.id == "dish.pasta.pesto" })
        let received = try #require(await sut.narrator.receivedDishNames.first)
        #expect(received == String(localized: entry.variant.displayName))
        #expect(received != "dish.pasta.pesto")
    }

    @Test("The narrator receives the note the verdict was decided with")
    func narratorReceivesTheNote() async throws {
        // Given a verdict recorded with a note
        let note = try #require(Note("Rough meeting, I need something comforting"))
        let sut = makeSUT(note: note)
        await sut.viewModel.onAppear()

        // When narration runs
        await sut.viewModel.narrateIfNeeded()

        // Then the note travels with it — the validator needs it to detect an echo
        #expect(await sut.narrator.receivedNotes.first == note)
    }

    // MARK: - Failure is always silent

    @Test("A narrator that produces nothing leaves the template showing")
    func nothingProducedLeavesTheTemplate() async {
        // Given a narrator that produced nothing — refused, unavailable, too slow, rejected
        let sut = makeSUT(scripted: nil)
        await sut.viewModel.onAppear()

        // When narration runs
        await sut.viewModel.narrateIfNeeded()

        // Then the template shows, with no error state anywhere
        #expect(sut.viewModel.narrationStage == .template)
        #expect(await sut.caseStore.attached.isEmpty)
        guard case .verdict = sut.viewModel.stage else {
            Issue.record("Expected .verdict, got \(sut.viewModel.stage.logLabel)")
            return
        }
    }

    @Test("A failed attach keeps the line on screen and never reports a failed save")
    func aFailedAttachIsSilent() async {
        // Given a store that refuses to attach narration
        let sut = makeSUT(attachFailure: FoodgeError.saveFailed)
        await sut.viewModel.onAppear()

        // When narration runs
        await sut.viewModel.narrateIfNeeded()

        // Then the validated line stays on screen this session, the revision keeps no narration,
        // and `stage` never becomes `.saveFailed` — which would offer the user a retry for a
        // decoration they never asked for
        #expect(sut.viewModel.narrationStage == .narrated("The court finds the defence charming."))
        #expect(sut.viewModel.currentRevision?.narrationText == nil)
        guard case .verdict = sut.viewModel.stage else {
            Issue.record("Expected .verdict, got \(sut.viewModel.stage.logLabel)")
            return
        }
    }

    // MARK: - Staleness

    @Test("A line that arrives after the verdict changed is discarded")
    func staleNarrationIsDiscarded() async {
        // Given a narrator that, while generating, sees the user request a fresh verdict —
        // the revision on screen changes underneath it
        let box = ViewModelBox()
        let sut = makeSUT(beforeNarratorReturns: { [box] in
            await box.requestVerdict()
        })
        box.set(sut.viewModel)
        await sut.viewModel.onAppear()

        // When narration runs and its answer arrives late
        await sut.viewModel.narrateIfNeeded()

        // Then the answer is dropped: it belongs to a revision that is no longer on screen, so it
        // is neither shown nor attached
        #expect(await sut.caseStore.attached.isEmpty)
        #expect(sut.viewModel.narrationStage == .narrating)
        #expect(sut.viewModel.narrationStage.text == nil)
    }

    // MARK: - Logging

    @Test("The log label never carries the narration itself")
    func logLabelNeverCarriesTheText() {
        // Given a narrated stage holding a line
        let stage = TodayViewModel.NarrationStage.narrated("The court finds the defence charming.")

        // Then what is logged is the case name alone — the rule this project's logging invariant
        // depends on, and the one a future `case` addition could silently break
        #expect(stage.logLabel == "narrated")
        #expect(!stage.logLabel.contains("court"))
    }
}

// MARK: - Fixtures

/// Holds the view model so a narrator fixture can act on it mid-generation, which is the only way
/// to make "the verdict changed while the model was answering" deterministic.
@MainActor
private final class ViewModelBox {
    private var viewModel: TodayViewModel?

    func set(_ viewModel: TodayViewModel) {
        self.viewModel = viewModel
    }

    func requestVerdict() async {
        await viewModel?.requestVerdict()
    }
}

/// Answers with one scripted line, records what it was asked, and can run a hook before answering.
private actor NarrationFixtureNarrator: VerdictNarrator {
    private let scripted: String?
    private let beforeReturn: (@Sendable () async -> Void)?
    private(set) var callCount = 0
    private(set) var receivedDishNames: [String] = []
    private(set) var receivedNotes: [Note?] = []

    init(scripted: String?, beforeReturn: (@Sendable () async -> Void)? = nil) {
        self.scripted = scripted
        self.beforeReturn = beforeReturn
    }

    func flourish(for _: VerdictDecision, dishName: String, note: Note?) async -> String? {
        callCount += 1
        receivedDishNames.append(dishName)
        receivedNotes.append(note)
        await beforeReturn?()
        return scripted
    }
}

/// Reopens one seeded case, records every narration attach, and can refuse them all.
private actor NarrationFixtureCaseStore: CaseStore {
    private var seeded: SavedCase?
    private let attachFailure: (any Error)?
    private(set) var attached: [(text: String, revisionID: UUID)] = []

    init(seeded: SavedCase?, attachFailure: (any Error)?) {
        self.seeded = seeded
        self.attachFailure = attachFailure
    }

    func savedCase(matching _: EvidenceSnapshot) async throws -> SavedCase? {
        seeded
    }

    @discardableResult
    func recordRevision(_ draft: NewRevisionDraft) async throws -> SavedRevision {
        let revisions = seeded?.revisions ?? []
        let revision = SavedRevision(
            id: UUID(),
            sequence: revisions.count,
            createdAt: draft.evidence.evaluatedAt,
            decision: draft.decision,
            evidence: draft.evidence,
            catalogueVersion: draft.catalogueVersion,
            dishOutcome: draft.dishOutcome,
            narrationText: nil,
            appeals: []
        )
        seeded = SavedCase(localDayKey: seeded?.localDayKey ?? "2026-09-18", revisions: revisions + [revision])
        return revision
    }

    func recordAppeal(_: AppealDraft, to _: UUID) async throws {
        // Not exercised this suite — see `TodayAppealViewModelTests`.
    }

    @discardableResult
    func attachNarration(_ text: String, to revisionID: UUID) async throws -> SavedRevision {
        if let attachFailure {
            throw attachFailure
        }
        guard
            let seeded,
            let existing = seeded.revisions.first(where: { $0.id == revisionID })
        else {
            throw FoodgeError.revisionNotFound
        }
        attached.append((text, revisionID))
        let updated = existing.attachingNarration(text)
        self.seeded = SavedCase(
            localDayKey: seeded.localDayKey,
            revisions: seeded.revisions.map { $0.id == revisionID ? updated : $0 }
        )
        return updated
    }

    func allCases() async throws -> [SavedCase] {
        // Not exercised this suite — see `HistoryViewModelTests`.
        []
    }
}

/// Hands back one fixed snapshot.
private actor NarrationFixtureEvidenceProvider: HealthEvidenceProvider {
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

/// Holds one draft in memory — the narration flag is what this suite reads from it.
private actor NarrationFixturePreferencesStore: PreferencesStore {
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
