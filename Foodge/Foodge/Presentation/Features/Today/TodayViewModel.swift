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

    /// Where an appeal in progress currently stands. Separate from ``Stage`` — the plan requires
    /// the original category, evidence and dish to stay visible and unchanged throughout an
    /// appeal, so appeal state must never perturb ``stage``.
    enum AppealStage: Sendable {
        case choosingCraving
        case compatibleFound(family: DishFamily, entry: CatalogueEntry)
        case noMatchFound(family: DishFamily, blockingIngredientIDs: Set<String>)
        case enteringFreeText
        case recorded(AppealChoice)
        case appealFailed(draft: AppealDraft, revisionID: UUID, error: FoodgeError)
    }

    private(set) var appealStage: AppealStage = .choosingCraving

    /// Where the optional flourish currently stands.
    ///
    /// Its own property, never a ``Stage`` case, for three reasons. `transition(to:)` appends
    /// `.verdict` to the navigation path, so a narration case would need a navigation carve-out —
    /// the exact wall appeals hit (D65). `Stage` is the save-integrity machine, where
    /// `.saveFailed` means "not saved, here is a retry" — the opposite of a narration failure,
    /// which must stay silent, and folding them together puts "narration failed" one refactor away
    /// from the user's eyes. And the verdict must stay visible and unchanged while narration runs.
    ///
    /// `.idle`, `.narrating` and `.template` all render as "no model text", which is why the view
    /// needs neither a spinner nor a pending flag.
    enum NarrationStage: Hashable, Sendable {
        case idle
        case narrating
        /// A validated model line, showing now.
        case narrated(String)
        /// Nothing usable was produced. The reviewed template shows, silently.
        case template

        var text: String? {
            if case let .narrated(text) = self {
                text
            } else {
                nil
            }
        }

        /// A label that is safe to log: the case name alone, never the narration itself.
        var logLabel: String {
            switch self {
            case .idle: "idle"
            case .narrating: "narrating"
            case .narrated: "narrated"
            case .template: "template"
            }
        }
    }

    private(set) var narrationStage: NarrationStage = .idle

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
    @ObservationIgnored private let narrator: any VerdictNarrator

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
        clock: any EvaluationClock,
        narrator: any VerdictNarrator
    ) {
        self.evidence = evidence
        self.preferences = preferences
        self.caseStore = caseStore
        self.clock = clock
        self.narrator = narrator
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

    // MARK: - Narration

    /// Asks for the optional flourish, once per verdict.
    ///
    /// A plain `async` method with no detached `Task` and no stored handle: `VerdictView` drives
    /// it from `.task(id:)`, so SwiftUI cancels it on disappear and restarts it on a new revision,
    /// and cancellation propagates straight through `DeadlineNarrator`'s task group into the model
    /// call. Nothing here can fail visibly — every unhappy path ends in `.template`, which renders
    /// exactly like never having tried.
    ///
    /// Opens on `.idle` because `.task` re-fires on every tab revisit (D69), and transitions to
    /// `.narrating` **before the first await**, so a second entry during that await is refused too.
    func narrateIfNeeded() async {
        guard case .idle = narrationStage, let revision = currentRevision else { return }

        // A `.noMatch` night has no dish to be playful about, and inventing one would be the
        // opposite of the honest no-match the product rule requires.
        guard case let .selected(variantID, _, _, _) = revision.dishOutcome else {
            transitionNarration(to: .template)
            return
        }

        let capturedID = revision.id
        transitionNarration(to: .narrating)

        let draft = (try? await preferences.preferences()) ?? PreferencesDraft()
        guard !Task.isCancelled else { return }
        guard draft.narrationEnabled else {
            transitionNarration(to: .template)
            return
        }

        let flourish = await narrator.flourish(
            for: revision.decision,
            dishName: DishCatalogue.displayName(forVariantID: variantID),
            note: revision.evidence.context.note
        )

        // Cancellation and staleness, checked before any mutation: `.task(id:)` already tears this
        // down on a new revision, and this second check is the unit-testable half of that.
        guard !Task.isCancelled, currentRevision?.id == capturedID else { return }

        guard let flourish else {
            transitionNarration(to: .template)
            return
        }

        transitionNarration(to: .narrated(flourish))

        // The text is genuine and validated, so it stays on screen this session whether or not the
        // write lands. A failed narration save is silent — `stage` never becomes `.saveFailed`.
        guard let updated = try? await caseStore.attachNarration(flourish, to: capturedID) else {
            TodayLog.logger.info("TODAY narration=attachFailed")
            return
        }
        guard !Task.isCancelled, currentRevision?.id == capturedID else { return }
        transition(to: .verdict(updated))
    }

    /// The single place ``narrationStage`` changes, so every transition is logged the same way —
    /// and only ever by its label. The narration text itself never reaches a `Logger`.
    private func transitionNarration(to newStage: NarrationStage) {
        narrationStage = newStage
        TodayLog.logger.info("TODAY narration=\(newStage.logLabel, privacy: .public)")
    }

    // MARK: - Appeals

    /// Resets appeal state fresh. Called once per sheet presentation.
    func beginAppeal() {
        appealStage = .choosingCraving
    }

    /// Negotiates one craving against the current preferences, re-fetched fresh — `pendingDraft`
    /// is already `nil` by the time a verdict is showing, and an appeal must reflect the user's
    /// preferences as they stand now, not as they stood when the original verdict was recorded.
    func proposeCraving(_ family: DishFamily) async {
        guard let revision = currentRevision else { return }
        let draft = (try? await preferences.preferences()) ?? PreferencesDraft()
        let context = DailyContext(
            dinnerTime: revision.evidence.context.dinnerTime,
            energyLevel: revision.evidence.context.energyLevel,
            craving: family,
            selfReportedActivity: revision.evidence.context.selfReportedActivity,
            note: revision.evidence.context.note
        )
        let outcome = DishSelection.negotiateAppeal(
            from: DishCatalogue.entries,
            request: AppealNegotiationRequest(
                craving: family,
                constraints: draft.constraints,
                context: context,
                favouriteFamilies: draft.favouriteFamilies
            ),
            on: clock.now,
            calendar: clock.calendar
        )
        switch outcome {
        case let .selected(recommendation, _):
            appealStage = .compatibleFound(family: family, entry: recommendation)
        case let .noMatch(blockingIngredientIDs):
            appealStage = .noMatchFound(family: family, blockingIngredientIDs: blockingIngredientIDs)
        }
    }

    /// Accepts the compatible variant an appeal negotiation just found.
    func acceptCompatible(entry: CatalogueEntry) async {
        guard let revisionID = currentRevision?.id else { return }
        let draft = AppealDraft(createdAt: clock.now, choice: .catalogue(variantID: entry.id, family: entry.family))
        await recordAppeal(draft, to: revisionID)
    }

    func beginFreeText() {
        appealStage = .enteringFreeText
    }

    /// Whether `text` is non-empty once trimmed — the one rule `submitFreeText` itself enforces,
    /// exposed so `AppealFreeTextSection` can disable Submit without a second copy of the rule.
    func canSubmitFreeText(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Records a free-text dish outside the catalogue — no invented nutritional analysis, no
    /// catalogue lookup at all.
    func submitFreeText(_ text: String) async {
        guard let revisionID = currentRevision?.id else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let draft = AppealDraft(createdAt: clock.now, choice: .freeText(trimmed))
        await recordAppeal(draft, to: revisionID)
    }

    /// Retries the exact appeal draft a failed save left behind.
    func retryAppeal() async {
        guard case let .appealFailed(draft, revisionID, _) = appealStage else { return }
        await recordAppeal(draft, to: revisionID)
    }

    private func recordAppeal(_ draft: AppealDraft, to revisionID: UUID) async {
        do {
            try await caseStore.recordAppeal(draft, to: revisionID)
            appealStage = .recorded(draft.choice)
        } catch {
            // Same coarse-mapping precedent as `record(_:)`: whatever `caseStore` actually threw
            // becomes the one `.appealFailed` case — `FoodgeError` is deliberately coarse
            // everywhere, and the retry offered is the same regardless of cause.
            appealStage = .appealFailed(draft: draft, revisionID: revisionID, error: .saveFailed)
        }
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
