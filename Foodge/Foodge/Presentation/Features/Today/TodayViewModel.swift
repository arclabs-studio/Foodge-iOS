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
/// Nothing is written until a verdict is actually reached. The verdict itself comes from
/// `CheatMealAllowanceRule`: this view model's job is to assemble the request from three sources
/// the rule cannot reach — today's Health readings, the stored body basics and the intake check-in —
/// and to decide nothing itself. `VerdictEngine` was deleted with D111 rather than reshaped; it had
/// no conformer and nothing left to abstract.
@MainActor
@Observable
final class TodayViewModel {
    /// Where the flow currently stands.
    enum Stage: Sendable {
        case gathering
        case evaluating
        /// Waiting on the self-report check-in — no allowance could be computed, and a day with no
        /// readable active energy cannot be given a number without inventing one.
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

    // MARK: - The intake check-in
    //
    // Three separate optionals bound to three pickers, so "not answered" stays distinct from
    // `.skipped` all the way from the control to the rule. They are only consulted when Health has
    // no `dietaryEnergy`: a recorded total replaces an estimate, never adds to it.

    var breakfast: MealPortion?
    var lunch: MealPortion?
    var snacks: MealPortion?

    /// What the pickers currently say.
    var intakeQuestionnaire: IntakeQuestionnaire {
        IntakeQuestionnaire(breakfast: breakfast, lunch: lunch, snacks: snacks)
    }

    @ObservationIgnored private let evidence: any HealthEvidenceProvider
    @ObservationIgnored private let preferences: any PreferencesStore
    @ObservationIgnored private let caseStore: any CaseStore
    @ObservationIgnored private let clock: any EvaluationClock
    @ObservationIgnored private let narrator: any VerdictNarrator

    /// Retained across the tracking-confirmation and self-report pauses, so answering either one
    /// never reads Health a second time.
    private var pendingSnapshot: EvidenceSnapshot?
    private var pendingDraft: PreferencesDraft?

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

        let read: EvidenceSnapshot
        do {
            read = try await evidence.snapshot(
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

        // The two estimate inputs are attached here, before anything is evaluated or saved, so the
        // snapshot a case is reopened from says which figures were estimates and from what.
        let snapshot = read.attaching(
            intake: resolvedQuestionnaire(scripted: read.intake),
            body: draft.bodyBasics
        )
        pendingSnapshot = snapshot

        await evaluateAllowance(in: snapshot)
    }

    /// The questionnaire the rule should use: the user's own answers, or the scenario's when a
    /// demonstration scripted them and the user has answered nothing.
    ///
    /// Body basics come from stored preferences instead, which is why a demonstration seeds them
    /// (D100/D117). A questionnaire cannot: it is a per-day answer, not a preference, so a scripted
    /// one has to travel on the snapshot.
    private func resolvedQuestionnaire(scripted: IntakeQuestionnaire?) -> IntakeQuestionnaire? {
        let answered = intakeQuestionnaire
        if answered.isAnswered {
            return answered
        }
        return scripted
    }

    /// Assembles the allowance request and rules on it, or pauses for the self-report when the
    /// request has no usable basis.
    ///
    /// Every unusable case ends in the same place — the self-report check-in — but the **reason** is
    /// logged by name, because "no resting basis" and "too early in the day" are different problems
    /// and the log is the only place that distinction survives. The reason label is a case name,
    /// never a Health figure.
    private func evaluateAllowance(in snapshot: EvidenceSnapshot) async {
        let window = EvidenceWindowPlanner.today(evaluation: snapshot.evaluatedAt, calendar: clock.calendar)

        let request = AllowanceRequest(
            activeEnergy: snapshot.today.activeEnergy,
            resting: restingEnergy(in: snapshot, window: window),
            intake: dailyIntake(in: snapshot),
            window: window
        )

        switch CheatMealAllowanceRule.allowance(request) {
        case let .allowance(allowance):
            let decision = CheatMealAllowanceRule.decide(
                allowance: allowance,
                today: snapshot.today,
                context: snapshot.context
            )
            await finish(decision: decision, snapshot: snapshot)
        case let .unavailable(reason):
            TodayLog.logger.info("TODAY allowance=unavailable reason=\(reason.logLabel, privacy: .public)")
            transition(to: .needsSelfReport)
        }
    }

    /// Health's own resting figure, else a Mifflin estimate from the stored body basics, else
    /// nothing at all — never a zero.
    private func restingEnergy(in snapshot: EvidenceSnapshot, window: DateInterval) -> RestingEnergy? {
        if let recorded = snapshot.today.restingEnergy {
            return .recorded(recorded)
        }
        guard
            let body = snapshot.body,
            let kilocalories = BasalMetabolicRate.kilocalories(
                for: body,
                upTo: window,
                calendar: clock.calendar
            )
        else { return nil }

        return .estimated(kilocalories: kilocalories, body: body, window: window)
    }

    /// Health's own dietary total **replaces** the questionnaire rather than adding to it, and an
    /// unanswered questionnaire is no basis at all.
    private func dailyIntake(in snapshot: EvidenceSnapshot) -> DailyIntake? {
        if let recorded = snapshot.today.dietaryEnergy {
            return .recorded(recorded)
        }
        guard let questionnaire = snapshot.intake, questionnaire.isAnswered else { return nil }
        return .estimated(questionnaire)
    }

    /// Answers the self-report check-in, or skips it with `nil`.
    ///
    /// The report is written into the saved evidence as well as into the decision's basis, so a
    /// reopened case can say what was asked and what was answered.
    func submitSelfReport(_ report: SelfReportedActivity?) async {
        guard let snapshot = pendingSnapshot else { return }

        await finish(
            decision: CheatMealAllowanceRule.decide(selfReport: report),
            snapshot: snapshot.recordingSelfReport(report)
        )
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

        // A revision that already carries narration shows exactly that, and the model is never
        // asked again. `attachNarration` is write-once (D76), so regenerating here would leave
        // Today showing one flourish while History showed the one actually stored for the same
        // day — and would spend two to four seconds of model work on every launch to do it.
        if let existing = revision.narrationText {
            transitionNarration(to: .narrated(existing))
            return
        }

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
