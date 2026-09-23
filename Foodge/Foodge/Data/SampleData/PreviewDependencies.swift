//
//  PreviewDependencies.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

#if DEBUG
    import Foundation

    /// The dependency sets previews are built from.
    ///
    /// A `#Preview` is a composition root, which is why this file may name ``AppDependencies``
    /// while production Presentation code may not (D34). It is `#if DEBUG` and never reaches the
    /// shipped binary.
    ///
    /// It vends **Domain-typed seams only**, never a ready-made ViewModel: handing out a ViewModel
    /// would put presentation decisions in Data and quietly become a second place where a screen's
    /// state is decided.
    enum PreviewDependencies {
        /// A device with Health, a typical recorded fortnight, and a store that accepts writes.
        static var all: AppDependencies {
            connected(SyntheticScenarios.typicalDay)
        }

        /// A device with no Health data at all.
        static func healthUnavailable() -> AppDependencies {
            make(
                authorization: PreviewAuthorization(isHealthDataAvailable: false),
                snapshot: SyntheticScenarios.noHealthData.snapshot
            )
        }

        /// Health connected, reading one labelled demonstration scenario.
        static func connected(_ scenario: SyntheticScenario) -> AppDependencies {
            make(
                authorization: PreviewAuthorization(isHealthDataAvailable: true),
                snapshot: scenario.snapshot
            )
        }

        /// Everything readable, but the store refuses to write — the save-failed state.
        static func savingFails() -> AppDependencies {
            make(
                authorization: PreviewAuthorization(isHealthDataAvailable: true),
                snapshot: SyntheticScenarios.typicalDay.snapshot,
                storeFailure: .saveFailed
            )
        }

        /// A day already ruled on: reopening returns the saved revision without regenerating it.
        static func reopeningSavedCase(
            _ scenario: SyntheticScenario = SyntheticScenarios.typicalDay,
            preferencesDraft: PreferencesDraft? = nil,
            appealFailure: FoodgeError? = nil,
            decision: VerdictDecision
        ) -> AppDependencies {
            let evidence = scenario.snapshot
            let dependencies = make(
                authorization: PreviewAuthorization(isHealthDataAvailable: true),
                snapshot: evidence,
                seededPreferences: preferencesDraft
            )
            let seeded = SavedRevision(
                id: UUID(),
                sequence: 0,
                createdAt: evidence.evaluatedAt,
                decision: decision,
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
            return AppDependencies(
                authorization: dependencies.authorization,
                evidence: dependencies.evidence,
                store: dependencies.store,
                caseStore: PreviewCaseStore(seeded: seeded, matching: evidence, appealFailure: appealFailure),
                clock: dependencies.clock,
                narrator: dependencies.narrator
            )
        }

        /// Four days of History: a dish match, a treat day with no appeal, a no-match day, and a
        /// day with a recorded appeal — enough variety for `HistoryListView` and every
        /// `CaseDetailView` outcome to preview from one dependency set.
        static var historyPopulated: AppDependencies {
            let base = make(
                authorization: PreviewAuthorization(isHealthDataAvailable: true),
                snapshot: SyntheticScenarios.typicalDay.snapshot
            )
            return AppDependencies(
                authorization: base.authorization,
                evidence: base.evidence,
                store: base.store,
                caseStore: PreviewHistoryCaseStore(cases: HistorySeedCases.all),
                clock: base.clock,
                narrator: base.narrator
            )
        }

        private static func make(
            authorization: PreviewAuthorization,
            snapshot: EvidenceSnapshot,
            storeFailure: FoodgeError? = nil,
            seededPreferences: PreferencesDraft? = nil
        ) -> AppDependencies {
            AppDependencies(
                authorization: authorization,
                evidence: PreviewEvidence(scripted: snapshot),
                store: PreviewStore(failure: storeFailure, seeded: seededPreferences),
                caseStore: PreviewCaseStore(failure: storeFailure),
                clock: SyntheticScenarios.clock,
                narrator: PreviewNarrator()
            )
        }
    }

    /// Reports availability without presenting anything — there is no system sheet in a preview.
    private struct PreviewAuthorization: HealthAuthorizing {
        let isHealthDataAvailable: Bool

        func requestReadAuthorization() async throws {
            guard isHealthDataAvailable else {
                throw FoodgeError.healthUnavailable
            }
        }
    }

    /// Answers with one fixed, in-voice flourish so previews show the narrated state without a
    /// model — previews run on a simulator, which has no Apple Intelligence at all. Returning
    /// `nil` here instead would show the reviewed template, which every template preview already
    /// covers.
    private struct PreviewNarrator: VerdictNarrator {
        func flourish(for _: VerdictDecision, dishName _: String, note _: Note?) async -> String? {
            "The defence pleaded tiredness; the court finds pasta a proportionate remedy."
        }
    }

    /// Hands back one fixed snapshot, whatever it is asked for.
    private struct PreviewEvidence: HealthEvidenceProvider {
        let scripted: EvidenceSnapshot

        func snapshot(
            at _: Date,
            calendar _: Calendar,
            context _: DailyContext,
            constraints _: DietaryConstraints
        ) async throws -> EvidenceSnapshot {
            scripted
        }
    }

    /// Accepts writes and keeps them for the life of the preview, or refuses them all.
    private actor PreviewStore: PreferencesStore {
        private let failure: FoodgeError?
        private var drafts: [PreferencesDraft]

        init(failure: FoodgeError?, seeded: PreferencesDraft? = nil) {
            self.failure = failure
            drafts = seeded.map { [$0] } ?? []
        }

        func savePreferences(_ draft: PreferencesDraft) async throws {
            if let failure {
                throw failure
            }
            drafts.append(draft)
        }

        func preferences() async throws -> PreferencesDraft? {
            drafts.last
        }
    }

    /// Reopens a seeded case for its own local day, records writes for the life of the preview,
    /// or refuses them all — mirroring `PreviewStore`'s shape for `CaseStore`.
    private actor PreviewCaseStore: CaseStore {
        private let failure: FoodgeError?
        /// Scripted separately from `failure`: an appeal preview reopens a case that already
        /// saved successfully, then fails only the appeal itself.
        private let appealFailure: FoodgeError?
        private var seeded: SavedCase?
        private(set) var recordedAppeals: [(draft: AppealDraft, revisionID: UUID)] = []

        init(failure: FoodgeError? = nil) {
            self.failure = failure
            appealFailure = nil
            seeded = nil
        }

        init(seeded revision: SavedRevision, matching evidence: EvidenceSnapshot, appealFailure: FoodgeError? = nil) {
            failure = nil
            self.appealFailure = appealFailure
            seeded = SavedCase(localDayKey: Self.localDayKey(for: evidence), revisions: [revision])
        }

        func savedCase(matching evidence: EvidenceSnapshot) async throws -> SavedCase? {
            guard let seeded, seeded.localDayKey == Self.localDayKey(for: evidence) else { return nil }
            return seeded
        }

        @discardableResult
        func recordRevision(_ draft: NewRevisionDraft) async throws -> SavedRevision {
            if let failure {
                throw failure
            }
            let priorRevisions = seeded?.revisions ?? []
            let revision = SavedRevision(
                id: UUID(),
                sequence: priorRevisions.count,
                createdAt: draft.evidence.evaluatedAt,
                decision: draft.decision,
                evidence: draft.evidence,
                catalogueVersion: draft.catalogueVersion,
                dishOutcome: draft.dishOutcome,
                narrationText: nil,
                appeals: []
            )
            seeded = SavedCase(
                localDayKey: Self.localDayKey(for: draft.evidence),
                revisions: priorRevisions + [revision]
            )
            return revision
        }

        func recordAppeal(_ draft: AppealDraft, to revisionID: UUID) async throws {
            if let appealFailure {
                throw appealFailure
            }
            recordedAppeals.append((draft, revisionID))
        }

        @discardableResult
        func attachNarration(_ text: String, to revisionID: UUID) async throws -> SavedRevision {
            guard
                let seeded,
                let existing = seeded.revisions.first(where: { $0.id == revisionID })
            else {
                throw FoodgeError.revisionNotFound
            }
            guard existing.narrationText == nil else { return existing }

            let updated = existing.attachingNarration(text)
            self.seeded = SavedCase(
                localDayKey: seeded.localDayKey,
                revisions: seeded.revisions.map { $0.id == revisionID ? updated : $0 }
            )
            return updated
        }

        func allCases() async throws -> [SavedCase] {
            guard let seeded else { return [] }
            return [seeded]
        }

        private static func localDayKey(for evidence: EvidenceSnapshot) -> String {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: evidence.timeZoneIdentifier) ?? .gmt
            let components = calendar.dateComponents([.year, .month, .day], from: evidence.evaluatedAt)
            return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        }
    }

    /// A fixed set of saved cases for `PreviewDependencies.historyPopulated`, read-only for the
    /// life of the preview — History never writes.
    private actor PreviewHistoryCaseStore: CaseStore {
        private let cases: [SavedCase]

        init(cases: [SavedCase]) {
            self.cases = cases
        }

        func savedCase(matching evidence: EvidenceSnapshot) async throws -> SavedCase? {
            cases.first { $0.localDayKey == Self.localDayKey(for: evidence) }
        }

        @discardableResult
        func recordRevision(_ draft: NewRevisionDraft) async throws -> SavedRevision {
            // Unreachable from the History screens this store backs — they only ever read.
            SavedRevision(
                id: UUID(),
                sequence: 0,
                createdAt: draft.evidence.evaluatedAt,
                decision: draft.decision,
                evidence: draft.evidence,
                catalogueVersion: draft.catalogueVersion,
                dishOutcome: draft.dishOutcome,
                narrationText: nil,
                appeals: []
            )
        }

        func recordAppeal(_ draft: AppealDraft, to revisionID: UUID) async throws {}

        @discardableResult
        func attachNarration(_ text: String, to revisionID: UUID) async throws -> SavedRevision {
            // Unreachable from the History screens this store backs — they only ever read, and
            // narration runs on Today. Reported honestly rather than inventing a revision.
            throw FoodgeError.revisionNotFound
        }

        func allCases() async throws -> [SavedCase] {
            cases.sorted { $0.localDayKey > $1.localDayKey }
        }

        private static func localDayKey(for evidence: EvidenceSnapshot) -> String {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: evidence.timeZoneIdentifier) ?? .gmt
            let components = calendar.dateComponents([.year, .month, .day], from: evidence.evaluatedAt)
            return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        }
    }

    /// The four days ``PreviewDependencies/historyPopulated`` seeds, each shifted back from
    /// `SyntheticScenarios.evaluationDate` so every case gets its own local day.
    private enum HistorySeedCases {
        /// Shifts `date` back by `days`, falling back to the unshifted date on the
        /// documented-unreachable failure path — same idiom `SyntheticScenarios.date` uses.
        static func shifted(_ date: Date, byDays days: Int) -> Date {
            SyntheticScenarios.calendar.date(byAdding: .day, value: -days, to: date) ?? date
        }

        static func evidence(_ scenario: SyntheticScenario, shiftedByDays days: Int) -> EvidenceSnapshot {
            let original = scenario.snapshot
            return EvidenceSnapshot(
                evaluatedAt: shifted(original.evaluatedAt, byDays: days),
                timeZoneIdentifier: original.timeZoneIdentifier,
                today: original.today,
                history: original.history,
                availability: original.availability,
                context: original.context,
                constraints: original.constraints,
                trackingRepresentative: original.trackingRepresentative,
                isSynthetic: original.isSynthetic
            )
        }

        static func decision(
            category: DinnerCategory,
            ratio: Double,
            reasonCode: ReasonCode,
            evidence: EvidenceSnapshot
        ) -> VerdictDecision {
            VerdictDecision(
                category: category,
                basis: .recorded(
                    ratio: ratio,
                    baseline: ActivityBaseline(
                        metric: .activeEnergy,
                        median: 400,
                        observationCount: 14,
                        window: SyntheticScenarios.windowSinceMidnight(endingAt: evidence.evaluatedAt)
                    )
                ),
                reasonCodes: [reasonCode],
                isProvisional: false,
                ruleVersion: DinnerCategoryRule.ruleVersion
            )
        }

        static func revision(
            sequence: Int = 0,
            evidence: EvidenceSnapshot,
            decision: VerdictDecision,
            dishOutcome: PersistedDishOutcome,
            appeals: [SavedAppeal] = []
        ) -> SavedRevision {
            SavedRevision(
                id: UUID(),
                sequence: sequence,
                createdAt: evidence.evaluatedAt,
                decision: decision,
                evidence: evidence,
                catalogueVersion: DishCatalogue.version,
                dishOutcome: dishOutcome,
                narrationText: nil,
                appeals: appeals
            )
        }

        /// A dish match: balanced, today.
        static let dishMatch: SavedCase = {
            let day = evidence(SyntheticScenarios.typicalDay, shiftedByDays: 0)
            return SavedCase(
                localDayKey: localDayKey(for: day),
                revisions: [
                    revision(
                        evidence: day,
                        decision: decision(category: .balanced, ratio: 1.02, reasonCode: .withinRecordedPattern, evidence: day),
                        dishOutcome: .selected(
                            variantID: "dish.pasta.pesto",
                            family: .pasta,
                            alternativeVariantID: nil,
                            alternativeFamily: nil
                        )
                    ),
                ]
            )
        }()

        /// A treat day, no appeal.
        static let treatDay: SavedCase = {
            let day = evidence(SyntheticScenarios.activeDay, shiftedByDays: 1)
            return SavedCase(
                localDayKey: localDayKey(for: day),
                revisions: [
                    revision(
                        evidence: day,
                        decision: decision(category: .treat, ratio: 1.4, reasonCode: .aboveRecordedPattern, evidence: day),
                        dishOutcome: .selected(
                            variantID: "dish.burgers.blackBean",
                            family: .burgers,
                            alternativeVariantID: nil,
                            alternativeFamily: nil
                        )
                    ),
                ]
            )
        }()

        /// A no-match day: constraints left every balanced-family variant blocked.
        static let noMatchDay: SavedCase = {
            let day = evidence(SyntheticScenarios.noCompatibleDish, shiftedByDays: 2)
            return SavedCase(
                localDayKey: localDayKey(for: day),
                revisions: [
                    revision(
                        evidence: day,
                        decision: decision(category: .balanced, ratio: 1.0, reasonCode: .withinRecordedPattern, evidence: day),
                        dishOutcome: .noMatch(blockingIngredientIDs: [Ingredient.rice.id, Ingredient.pasta.id])
                    ),
                ]
            )
        }()

        /// A light day with a recorded appeal.
        static let appealedDay: SavedCase = {
            let day = evidence(SyntheticScenarios.restDay, shiftedByDays: 3)
            return SavedCase(
                localDayKey: localDayKey(for: day),
                revisions: [
                    revision(
                        evidence: day,
                        decision: decision(category: .light, ratio: 0.45, reasonCode: .belowRecordedPattern, evidence: day),
                        dishOutcome: .selected(
                            variantID: "dish.lentilSalad.tomato",
                            family: .lentilSalad,
                            alternativeVariantID: nil,
                            alternativeFamily: nil
                        ),
                        appeals: [
                            SavedAppeal(
                                id: UUID(),
                                createdAt: day.evaluatedAt,
                                choice: .catalogue(variantID: "dish.tacos.beef", family: .tacos)
                            ),
                        ]
                    ),
                ]
            )
        }()

        static var all: [SavedCase] { [dishMatch, treatDay, noMatchDay, appealedDay] }

        private static func localDayKey(for evidence: EvidenceSnapshot) -> String {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: evidence.timeZoneIdentifier) ?? .gmt
            let components = calendar.dateComponents([.year, .month, .day], from: evidence.evaluatedAt)
            return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        }
    }
#endif
