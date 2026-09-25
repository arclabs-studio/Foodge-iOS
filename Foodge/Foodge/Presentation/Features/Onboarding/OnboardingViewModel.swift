//
//  OnboardingViewModel.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import OSLog

/// Drives the whole onboarding flow: what Health said, what the user chose, and the one write.
///
/// Nothing is persisted until ``finish()`` succeeds. Someone who abandons onboarding half way
/// leaves nothing behind, and there is never a half-written record.
@MainActor
@Observable
final class OnboardingViewModel {
    /// What Foodge can honestly say about Health right now.
    ///
    /// There is no "denied" case and there never will be: HealthKit cannot tell an app that.
    enum HealthState: Hashable, Sendable {
        /// Not asked yet.
        case idle
        case requesting
        /// This device has no Health data at all — the one refusal that is provable.
        case unavailable
        /// The request completed and the read came back with nothing.
        case noReadableData
        /// The authorization request itself did not complete. Distinct from an absence, which
        /// this app may only claim after an actual read returned empty (D35).
        case requestFailed
        /// The read came back with something. `missing` is the kinds that did not — never a
        /// denial, because HealthKit cannot tell an app that.
        case connected(missing: Set<HealthKind>)

        /// A label that is safe to log: the case name alone, never an associated value.
        ///
        /// The missing *kinds* would be safe to log, but the rule is the same for every state so
        /// there is nothing to get wrong later: the label, never the value.
        var logLabel: String {
            switch self {
            case .idle: "idle"
            case .requesting: "requesting"
            case .unavailable: "unavailable"
            case .noReadableData: "noReadableData"
            case .requestFailed: "requestFailed"
            case .connected: "connected"
            }
        }
    }

    enum SaveState: Hashable, Sendable {
        case editing
        case saving
        case failed(FoodgeError)
    }

    var path: [OnboardingRoute] = []
    var draft = PreferencesDraft()
    private(set) var healthState: HealthState = .idle
    private(set) var saveState: SaveState = .editing
    /// Set only after a save returned without throwing.
    private(set) var didFinish = false

    // MARK: - Body basics, gathered on their own step

    //
    // Held as text because that is what a keypad produces, and parsed in one place
    // (``bodyBasicsFromInputs``) so a half-typed answer is simply not a body yet. Nothing is
    // clamped and nothing is guessed: an implausible figure means no estimate is possible.

    var bodySex: BiologicalSex?
    var ageText = ""
    var heightText = ""
    var weightText = ""

    @ObservationIgnored private let authorization: any HealthAuthorizing
    @ObservationIgnored private let evidence: any HealthEvidenceProvider
    @ObservationIgnored private let store: any PreferencesStore
    @ObservationIgnored private let clock: any EvaluationClock

    init(
        authorization: any HealthAuthorizing,
        evidence: any HealthEvidenceProvider,
        store: any PreferencesStore,
        clock: any EvaluationClock
    ) {
        self.authorization = authorization
        self.evidence = evidence
        self.store = store
        self.clock = clock
    }

    // MARK: - Health

    /// Asks for Health access and, if that completes, reads one snapshot.
    ///
    /// The order matters more than it looks. A device with no Health data is never asked for
    /// authorization *and never asked for evidence*; a request that does not complete is
    /// reported as a failed request rather than an absence; and only a read that actually came
    /// back empty produces ``HealthState/noReadableData``.
    func connectHealth() async {
        guard authorization.isHealthDataAvailable else {
            transition(to: .unavailable)
            return
        }

        // Kept so a cancelled attempt can put back what the user last saw, rather than leaving
        // them looking at a spinner that will never resolve.
        let previous = healthState
        transition(to: .requesting)

        do {
            try await authorization.requestReadAuthorization()
        } catch FoodgeError.healthUnavailable {
            transition(to: .unavailable)
            return
        } catch {
            transition(to: .requestFailed)
            return
        }

        // Read once from the clock, so everything in this evaluation agrees about what day it is.
        let now = clock.now
        let calendar = clock.calendar

        let read: EvidenceSnapshot
        do {
            read = try await evidence.snapshot(
                at: now,
                calendar: calendar,
                context: .empty,
                constraints: draft.constraints
            )
        } catch is CancellationError {
            // The user moved on. Put back the state they last saw rather than a failure they
            // did not cause — and rather than leaving `.requesting` on screen for good.
            transition(to: previous)
            return
        } catch {
            transition(to: .requestFailed)
            return
        }

        transition(to: Self.state(for: read))
    }

    /// Continues without Health, leaving no failed attempt on the screen behind them.
    func skipHealth() {
        transition(to: .idle)
        path.append(.bodyBasics)
    }

    // MARK: - Body basics

    /// The basics as typed, or `nil` while they are incomplete or implausible.
    ///
    /// Parsed with `.number` rather than `Double.init(_:)`, so a comma decimal separator is read
    /// the way the user's locale writes it instead of silently failing.
    var bodyBasicsFromInputs: BodyBasics? {
        guard
            let bodySex,
            let ageYears = try? Int(ageText, format: .number),
            let heightCentimetres = try? Double(heightText, format: .number),
            let weightKilograms = try? Double(weightText, format: .number)
        else { return nil }

        return BodyBasics(
            sex: bodySex,
            ageYears: ageYears,
            heightCentimetres: heightCentimetres,
            weightKilograms: weightKilograms
        )
    }

    /// Whether anything at all has been typed on the body-basics step.
    ///
    /// Drives the difference between "Skip" and an answer that does not parse: a completely empty
    /// step is a legitimate choice, a half-filled one is worth saying so about.
    var hasStartedBodyBasics: Bool {
        bodySex != nil || !ageText.isEmpty || !heightText.isEmpty || !weightText.isEmpty
    }

    /// Whether the step still offers a way out that is not "answer all four" (D126).
    ///
    /// Deliberately keyed on the *answer*, not on whether typing has begun. Keying it on
    /// ``hasStartedBodyBasics`` trapped the user: touching one field disabled Continue and hid Skip
    /// at the same moment, leaving the step escapable only by clearing every field again — while
    /// its own footer said skipping was fine. Skipping discards the partial answer, which is what
    /// ``applyBodyBasics()`` already does.
    var canSkipBodyBasics: Bool {
        bodyBasicsFromInputs == nil
    }

    /// Records the basics on the draft, or clears them. Writes nothing — the single write is
    /// ``finish()``.
    func applyBodyBasics() {
        draft.bodyBasics = bodyBasicsFromInputs
    }

    /// The single place ``healthState`` changes, so every transition is logged the same way.
    ///
    /// The label, never the state: nothing about a Health *value* may reach a `Logger`, and a rule
    /// that holds for every case is a rule nobody has to re-check when a case gains a payload.
    private func transition(to state: HealthState) {
        healthState = state
        OnboardingLog.logger.info("ONBOARDING state=\(state.logLabel, privacy: .public)")
    }

    /// Classifies a snapshot, keeping "we read nothing" separate from "we read something".
    ///
    /// Only today's readings count now that there is no fortnight to fall back on (D111): a first
    /// launch just after midnight can therefore land on `.noReadableData` where it used to report a
    /// recorded pattern — correctly, because there is nothing readable *yet*, and the allowance rule
    /// refuses a window under ninety minutes for the same reason.
    private static func state(for snapshot: EvidenceSnapshot) -> HealthState {
        guard snapshot.today.hasAnyReading else {
            return .noReadableData
        }
        return .connected(missing: missingKinds(in: snapshot.availability))
    }

    private static func missingKinds(in availability: EvidenceAvailability) -> Set<HealthKind> {
        switch availability {
        case let .readable(missing): missing
        case .healthUnavailable, .notRequested: []
        }
    }

    // MARK: - Preferences

    /// Adds or removes a favourite, preserving the order they were chosen in.
    func toggleFavourite(_ family: DishFamily) {
        if let index = draft.favouriteFamilies.firstIndex(of: family) {
            draft.favouriteFamilies.remove(at: index)
        } else {
            draft.favouriteFamilies.append(family)
        }
    }

    /// Adds or removes an ingredient exclusion.
    func toggleExclusion(_ ingredientID: String) {
        if draft.excludedIngredientIDs.contains(ingredientID) {
            draft.excludedIngredientIDs.remove(ingredientID)
        } else {
            draft.excludedIngredientIDs.insert(ingredientID)
        }
    }

    /// Writes the preferences, and only then reports onboarding complete.
    ///
    /// The stamped draft is built as a local copy: on failure nothing is mutated, so no part of
    /// the app — not ``draft``, not ``didFinish`` — claims onboarding happened.
    func finish() async {
        saveState = .saving

        var completed = draft
        completed.onboardingCompletedAt = clock.now

        do {
            try await store.savePreferences(completed)
        } catch {
            saveState = .failed(.saveFailed)
            OnboardingLog.logger.error("ONBOARDING save=failed")
            return
        }

        draft = completed
        didFinish = true
        saveState = .editing
        OnboardingLog.logger.info("ONBOARDING save=completed")
    }
}
