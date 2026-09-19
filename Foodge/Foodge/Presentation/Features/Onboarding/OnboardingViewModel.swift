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
        case connected(RecordedPatternSummary)

        /// A label that is safe to log: the case name alone, never an associated value.
        ///
        /// `.connected` carries the recorded median — a Health value — so `String(describing:)`
        /// on this enum would put someone's health data in the device log.
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

    /// Retained so that marking the days unrepresentative recomputes the summary without
    /// reading Health a second time.
    private var snapshot: EvidenceSnapshot?

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

        // Read both once, so everything in this evaluation agrees about what day it is.
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

        snapshot = read
        transition(to: Self.state(for: read, trackingRepresentative: draft.trackingRepresentative))
    }

    /// Continues without Health, leaving no failed attempt on the screen behind them.
    func skipHealth() {
        snapshot = nil
        transition(to: .idle)
        path.append(.preferences)
    }

    /// Records whether the recorded days may be used as a baseline, and recomputes the summary.
    ///
    /// Writes nothing. The single write is in ``finish()``, so a user who abandons onboarding
    /// here leaves nothing behind. The retained snapshot is what makes taking the mark back
    /// free — Health is not read a second time.
    func markUnrepresentative(_ unrepresentative: Bool) {
        draft.trackingRepresentative = !unrepresentative

        guard let snapshot else { return }
        transition(to: Self.state(for: snapshot, trackingRepresentative: draft.trackingRepresentative))
    }

    /// The single place ``healthState`` changes, so every transition is logged the same way.
    ///
    /// The label, never the state: `.connected` carries the recorded median, and
    /// `String(describing:)` on it would write a Health value into the device log.
    private func transition(to state: HealthState) {
        healthState = state
        OnboardingLog.logger.info("ONBOARDING state=\(state.logLabel, privacy: .public)")
    }

    /// Classifies a snapshot, keeping "we read nothing" separate from "we read something".
    private static func state(
        for snapshot: EvidenceSnapshot,
        trackingRepresentative: Bool
    ) -> HealthState {
        let summary = RecordedPatternSummary(
            snapshot: snapshot,
            trackingRepresentative: trackingRepresentative
        )

        // Either today or the fortnight counts as readable: just after midnight there may be
        // nothing recorded today while a full recorded pattern still exists.
        guard snapshot.today.hasAnyReading || summary.daysWithAnyReading > 0 else {
            return .noReadableData
        }
        return .connected(summary)
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
