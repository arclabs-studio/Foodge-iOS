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
            decision: VerdictDecision
        ) -> AppDependencies {
            let evidence = scenario.snapshot
            let dependencies = make(
                authorization: PreviewAuthorization(isHealthDataAvailable: true),
                snapshot: evidence
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
                caseStore: PreviewCaseStore(seeded: seeded, matching: evidence),
                clock: dependencies.clock
            )
        }

        private static func make(
            authorization: PreviewAuthorization,
            snapshot: EvidenceSnapshot,
            storeFailure: FoodgeError? = nil
        ) -> AppDependencies {
            AppDependencies(
                authorization: authorization,
                evidence: PreviewEvidence(scripted: snapshot),
                store: PreviewStore(failure: storeFailure),
                caseStore: PreviewCaseStore(failure: storeFailure),
                clock: SyntheticScenarios.clock
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
        private var drafts: [PreferencesDraft] = []

        init(failure: FoodgeError?) {
            self.failure = failure
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
        private var seeded: SavedCase?

        init(failure: FoodgeError? = nil) {
            self.failure = failure
            seeded = nil
        }

        init(seeded revision: SavedRevision, matching evidence: EvidenceSnapshot) {
            failure = nil
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

        func recordAppeal(_: AppealDraft, to _: UUID) async throws {
            if let failure {
                throw failure
            }
        }

        private static func localDayKey(for evidence: EvidenceSnapshot) -> String {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: evidence.timeZoneIdentifier) ?? .gmt
            let components = calendar.dateComponents([.year, .month, .day], from: evidence.evaluatedAt)
            return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
        }
    }
#endif
