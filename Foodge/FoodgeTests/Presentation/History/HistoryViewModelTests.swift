//
//  HistoryViewModelTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 23/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// History exists purely to reflect whatever Today most recently saved, so `load()` must never
/// guard on the current stage — a reload after the fixture's scripted result changes has to show
/// the new result, not the first one.
@Suite("History view model", .tags(.unit, .critical))
@MainActor
struct HistoryViewModelTests {
    private func makeSUT(result: Result<[SavedCase], any Error> = .success([])) -> (HistoryViewModel, HistoryFixtureCaseStore) {
        let caseStore = HistoryFixtureCaseStore(result: result)
        return (HistoryViewModel(caseStore: caseStore), caseStore)
    }

    private func makeSavedCase(localDayKey: String, category: DinnerCategory) -> SavedCase {
        SavedCase(
            localDayKey: localDayKey,
            revisions: [
                SavedRevision(
                    id: UUID(),
                    sequence: 0,
                    createdAt: SyntheticScenarios.evaluationDate,
                    decision: VerdictDecision(
                        category: category,
                        basis: .provisional,
                        reasonCodes: [.checkInSkipped],
                        isProvisional: true,
                        ruleVersion: DinnerCategoryRule.ruleVersion
                    ),
                    evidence: SyntheticScenarios.typicalDay.snapshot,
                    catalogueVersion: DishCatalogue.version,
                    dishOutcome: .selected(
                        variantID: "dish.pasta.pesto",
                        family: .pasta,
                        alternativeVariantID: nil,
                        alternativeFamily: nil
                    ),
                    narrationText: nil,
                    appeals: []
                ),
            ]
        )
    }

    @Test("Initial stage is loading before load() is ever called")
    func initialStageIsLoading() {
        // Given a freshly constructed view model
        let (sut, _) = makeSUT()

        // Then nothing has been fetched yet
        guard case .loading = sut.stage else {
            Issue.record("Expected .loading, got \(sut.stage.logLabel)")
            return
        }
    }

    @Test("A populated fixture loads exactly the seeded cases")
    func loadWithCasesLoadsThem() async {
        // Given a store seeded with two cases
        let seeded = [
            makeSavedCase(localDayKey: "2026-09-18", category: .balanced),
            makeSavedCase(localDayKey: "2026-09-17", category: .treat),
        ]
        let (sut, _) = makeSUT(result: .success(seeded))

        // When the list is loaded
        await sut.load()

        // Then the stage carries exactly the seeded array — full value equality, not just a count
        guard case let .loaded(cases) = sut.stage else {
            Issue.record("Expected .loaded, got \(sut.stage.logLabel)")
            return
        }
        #expect(cases == seeded)
    }

    @Test("An empty fixture loads to an empty list")
    func loadWithNoCasesLoadsEmpty() async {
        // Given a store with nothing recorded
        let (sut, _) = makeSUT(result: .success([]))

        // When the list is loaded
        await sut.load()

        // Then the stage is `.loaded([])`, not an error and not still loading
        guard case let .loaded(cases) = sut.stage else {
            Issue.record("Expected .loaded, got \(sut.stage.logLabel)")
            return
        }
        #expect(cases.isEmpty)
    }

    @Test("A throwing fixture maps to storeUnavailable")
    func loadWithFailureMapsToStoreUnavailable() async {
        // Given a store that fails to read
        let (sut, _) = makeSUT(result: .failure(FoodgeError.caseCorrupted))

        // When the list is loaded
        await sut.load()

        // Then the stage carries the one coarse mapped error, whatever the store actually threw
        guard case let .error(error) = sut.stage else {
            Issue.record("Expected .error, got \(sut.stage.logLabel)")
            return
        }
        #expect(error == .storeUnavailable)
    }

    @Test("Reloading reflects the fixture's new result, not the first one")
    func reloadingReflectsTheNewResult() async {
        // Given a first load that returned one case
        let first = [makeSavedCase(localDayKey: "2026-09-18", category: .balanced)]
        let (sut, caseStore) = makeSUT(result: .success(first))
        await sut.load()
        guard case let .loaded(firstCases) = sut.stage else {
            Issue.record("Expected .loaded, got \(sut.stage.logLabel)")
            return
        }
        #expect(firstCases == first)

        // When the fixture's scripted result changes and the list is loaded again
        let second = [
            makeSavedCase(localDayKey: "2026-09-18", category: .balanced),
            makeSavedCase(localDayKey: "2026-09-19", category: .light),
        ]
        await caseStore.setResult(.success(second))
        await sut.load()

        // Then the stage reflects the new result — an accidental stage guard added later would
        // pass every other test here while silently breaking History's reason for existing
        guard case let .loaded(secondCases) = sut.stage else {
            Issue.record("Expected .loaded, got \(sut.stage.logLabel)")
            return
        }
        #expect(secondCases == second)
    }
}

/// A scripted `CaseStore` whose `allCases()` result can be changed between calls — the seam
/// `reloadingReflectsTheNewResult` needs to prove `load()` never guards on the current stage.
///
/// Duplicated rather than reusing `PreviewCaseStore`/`TodayFixtureCaseStore` — this suite's own
/// fixture, per this codebase's established per-suite-fixture convention.
private actor HistoryFixtureCaseStore: CaseStore {
    private var result: Result<[SavedCase], any Error>

    init(result: Result<[SavedCase], any Error>) {
        self.result = result
    }

    func setResult(_ newResult: Result<[SavedCase], any Error>) {
        result = newResult
    }

    func savedCase(matching _: EvidenceSnapshot) async throws -> SavedCase? {
        nil
    }

    @discardableResult
    func recordRevision(_: NewRevisionDraft) async throws -> SavedRevision {
        // Not exercised this suite — History only ever reads.
        throw FoodgeError.saveFailed
    }

    func recordAppeal(_: AppealDraft, to _: UUID) async throws {
        // Not exercised this suite — History only ever reads.
        throw FoodgeError.saveFailed
    }

    @discardableResult
    func attachNarration(_: String, to _: UUID) async throws -> SavedRevision {
        // Not exercised this suite — History only ever reads.
        throw FoodgeError.revisionNotFound
    }

    func allCases() async throws -> [SavedCase] {
        try result.get()
    }
}
