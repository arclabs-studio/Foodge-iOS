//
//  TodayViewModel.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation
import OSLog

/// Drives the Today flow: reopening a saved case without regenerating it, gathering optional
/// context, requesting a verdict, and recording the one revision that results.
///
/// Nothing is written until a verdict is actually reached. `VerdictEngine` has no conformer this
/// unit — its `decideCategory(for snapshot:)` signature cannot receive
/// `PreferencesDraft.trackingRepresentative`, which `ActivityBaselineCalculator` needs, so this
/// view model calls `ActivityBaselineCalculator`/`DinnerCategoryRule.decide` directly (D55).
@MainActor
@Observable
final class TodayViewModel {
    /// Where the flow currently stands.
    enum Stage: Sendable {
        case gathering
        case evaluating
        /// Waiting on "does the recorded activity reflect today?".
        case needsTrackingConfirmation
        /// Waiting on the self-report check-in — no usable recorded comparison exists.
        case needsSelfReport
        case verdict(SavedRevision)
        case evidenceUnavailable
        /// The computed decision, still visible with a retry — never reported as saved.
        case saveFailed(NewRevisionDraft, FoodgeError)

        /// A label that is safe to log: the case name alone, never the decision or evidence a
        /// `.verdict` or `.saveFailed` case carries.
        var logLabel: String {
            switch self {
            case .gathering: "gathering"
            case .evaluating: "evaluating"
            case .needsTrackingConfirmation: "needsTrackingConfirmation"
            case .needsSelfReport: "needsSelfReport"
            case .verdict: "verdict"
            case .evidenceUnavailable: "evidenceUnavailable"
            case .saveFailed: "saveFailed"
            }
        }
    }

    var path: [TodayRoute] = []
    private(set) var stage: Stage = .gathering

    /// What the verdict screen shows: a category, a dish outcome and the evidence behind it —
    /// whether the revision actually saved or a save is still pending retry. Without this, a
    /// failed save would strand `VerdictView` on an infinite spinner, since only `.verdict`
    /// carries a `SavedRevision` but the computed decision must stay visible regardless.
    struct Display {
        let decision: VerdictDecision
        let dishOutcome: PersistedDishOutcome
        let evidence: EvidenceSnapshot
    }

    var currentDisplay: Display? {
        switch stage {
        case let .verdict(revision):
            Display(decision: revision.decision, dishOutcome: revision.dishOutcome, evidence: revision.evidence)
        case let .saveFailed(draft, _):
            Display(decision: draft.decision, dishOutcome: draft.dishOutcome, evidence: draft.evidence)
        default:
            nil
        }
    }

    /// The revision behind the current verdict, or `nil` when ``stage`` is not `.verdict`.
    var currentRevision: SavedRevision? {
        if case let .verdict(revision) = stage {
            revision
        } else {
            nil
        }
    }

    // MARK: - Context inputs, gathered before a verdict is requested

    var dinnerTime: DinnerTime?
    var energyLevel: EnergyLevel?
    var craving: DishFamily?
    /// Bound to the `TextField` directly; only turned into a `Note?` at submit time, in
    /// ``requestVerdict()`` — never a hand-built `Binding<Note?>`.
    var noteText = ""

    @ObservationIgnored private let evidence: any HealthEvidenceProvider
    @ObservationIgnored private let preferences: any PreferencesStore
    @ObservationIgnored private let caseStore: any CaseStore
    @ObservationIgnored private let clock: any EvaluationClock

    /// Retained across the tracking-confirmation and self-report pauses, so answering either one
    /// never reads Health a second time.
    private var pendingSnapshot: EvidenceSnapshot?
    private var pendingDraft: PreferencesDraft?
    /// The recorded comparison a "Yes" can still finish with.
    ///
    /// Cleared on "No" (D56): the comparison is discarded entirely rather than re-entered into
    /// `DinnerCategoryRule.decide` with `trackingRepresentative: false`, which
    /// `decideFromRecording` treats identically to `nil` and would hand back
    /// `.needsTrackingConfirmation` again, forever.
    private var pendingComparison: (today: Double, baseline: ActivityBaseline)?

    init(
        evidence: any HealthEvidenceProvider,
        preferences: any PreferencesStore,
        caseStore: any CaseStore,
        clock: any EvaluationClock
    ) {
        self.evidence = evidence
        self.preferences = preferences
        self.caseStore = caseStore
        self.clock = clock
    }

    // MARK: - Reopening

    /// Reopens today's case if one already exists, without ever reading Health.
    ///
    /// A minimal snapshot — just the instant and time zone the local-day key is derived from —
    /// is all `caseStore` needs; nothing else about it is used. Health is read only from
    /// ``requestVerdict()``, when there is no saved case to reopen.
    func onAppear() async {
        guard case .gathering = stage else { return }

        let probe = EvidenceSnapshot(
            evaluatedAt: clock.now,
            timeZoneIdentifier: clock.calendar.timeZone.identifier,
            today: .empty,
            history: [],
            availability: .notRequested
        )

        do {
            guard
                let saved = try await caseStore.savedCase(matching: probe),
                let latest = saved.latestRevision
            else {
                return
            }
            transition(to: .verdict(latest))
        } catch {
            // A corrupted read here must not block starting a fresh evaluation today.
            TodayLog.logger.error("TODAY reopen=failed")
        }
    }

    // MARK: - Requesting a verdict

    func requestVerdict() async {
        transition(to: .evaluating)

        let draft = (try? await preferences.preferences()) ?? PreferencesDraft()
        pendingDraft = draft

        let context = DailyContext(
            dinnerTime: dinnerTime ?? draft.dinnerRoutine,
            energyLevel: energyLevel,
            craving: craving,
            note: Note(noteText)
        )

        let snapshot: EvidenceSnapshot
        do {
            snapshot = try await evidence.snapshot(
                at: clock.now,
                calendar: clock.calendar,
                context: context,
                constraints: draft.constraints
            )
        } catch is CancellationError {
            transition(to: .gathering)
            return
        } catch {
            transition(to: .evidenceUnavailable)
            return
        }

        pendingSnapshot = snapshot
        await evaluateRecordedComparison(in: snapshot, trackingRepresentative: draft.trackingRepresentative)
    }

    /// Tries the recorded comparison first. Only a usable one is handed to
    /// `DinnerCategoryRule.decide`: an unusable one pauses for a self-report instead of letting
    /// the rule fall straight through to a provisional verdict the user was never asked about.
    private func evaluateRecordedComparison(in snapshot: EvidenceSnapshot, trackingRepresentative: Bool) async {
        let baselineResult = ActivityBaselineCalculator.baseline(
            from: snapshot.history,
            trackingRepresentative: trackingRepresentative
        )

        guard
            let baseline = try? baselineResult.get(),
            let today = snapshot.today.value(for: baseline.metric)
        else {
            pendingComparison = nil
            transition(to: .needsSelfReport)
            return
        }

        pendingComparison = (today, baseline)
        let outcome = DinnerCategoryRule.decide(
            today: today,
            baseline: baseline,
            trackingRepresentative: nil,
            selfReport: nil
        )

        switch outcome {
        case .needsTrackingConfirmation:
            transition(to: .needsTrackingConfirmation)
        case let .verdict(decision):
            await finish(decision: decision, snapshot: snapshot)
        }
    }

    /// Answers the per-day "does the recorded activity reflect today?" check-in.
    func confirmTrackingReflectsToday(_ reflectsToday: Bool) async {
        guard let snapshot = pendingSnapshot else { return }

        guard reflectsToday, let comparison = pendingComparison else {
            pendingComparison = nil
            transition(to: .needsSelfReport)
            return
        }

        let outcome = DinnerCategoryRule.decide(
            today: comparison.today,
            baseline: comparison.baseline,
            trackingRepresentative: true,
            selfReport: nil
        )

        guard case let .verdict(decision) = outcome else {
            // Unreachable: `trackingRepresentative: true` always satisfies `decideFromRecording`'s
            // guard, so the rule can only hand back a verdict from here.
            return
        }
        await finish(decision: decision, snapshot: snapshot)
    }

    /// Answers the self-report check-in, or skips it with `nil`.
    func submitSelfReport(_ report: SelfReportedActivity?) async {
        guard let snapshot = pendingSnapshot else { return }

        let outcome = DinnerCategoryRule.decide(
            today: nil,
            baseline: nil,
            trackingRepresentative: nil,
            selfReport: report
        )

        guard case let .verdict(decision) = outcome else {
            // Unreachable: with `today`/`baseline` both `nil`, the rule can only hand back a
            // verdict — self-reported or provisional — never ask for tracking confirmation.
            return
        }
        await finish(decision: decision, snapshot: snapshot)
    }

    // MARK: - Finishing

    private func finish(decision: VerdictDecision, snapshot: EvidenceSnapshot) async {
        let draft = pendingDraft ?? PreferencesDraft()

        let selection = DishSelection.select(
            from: DishCatalogue.entries,
            request: DishSelectionRequest(
                category: decision.category,
                constraints: draft.constraints,
                context: snapshot.context,
                favouriteFamilies: draft.favouriteFamilies
            ),
            on: clock.now,
            calendar: clock.calendar
        )

        let revisionDraft = NewRevisionDraft(
            decision: decision,
            evidence: snapshot,
            catalogueVersion: DishCatalogue.version,
            dishOutcome: PersistedDishOutcome(selection)
        )

        await record(revisionDraft)
    }

    private func record(_ draft: NewRevisionDraft) async {
        do {
            let saved = try await caseStore.recordRevision(draft)
            pendingSnapshot = nil
            pendingDraft = nil
            pendingComparison = nil
            transition(to: .verdict(saved))
        } catch is CancellationError {
            transition(to: .gathering)
        } catch {
            // Whatever `caseStore` actually threw is mapped to the one coarse `.saveFailed` case:
            // `FoodgeError` is deliberately coarse everywhere, and the retry offered to the user
            // is the same regardless of which underlying failure occurred.
            transition(to: .saveFailed(draft, .saveFailed))
        }
    }

    /// Retries the exact draft a failed save left behind.
    func retrySave() async {
        guard case let .saveFailed(draft, _) = stage else { return }
        transition(to: .evaluating)
        await record(draft)
    }

    // MARK: - Helpers

    /// The single place ``stage`` changes, so every transition is logged the same way and the
    /// verdict screen is always pushed once there is something for it to show — a saved verdict
    /// or a failed save whose computed decision still needs to stay visible with a retry.
    private func transition(to newStage: Stage) {
        stage = newStage
        switch newStage {
        case .verdict, .saveFailed:
            if path.last != .verdict {
                path.append(.verdict)
            }
        default:
            break
        }
        TodayLog.logger.info("TODAY stage=\(newStage.logLabel, privacy: .public)")
    }
}
