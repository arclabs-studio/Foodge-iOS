//
//  AppLaunch.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import OSLog
import SwiftData

/// Opens the local store once, reports honestly when it cannot, and owns the demonstration
/// session that can temporarily replace it.
///
/// There is deliberately **no in-memory fallback for the live session**. Silently swapping to a
/// throwaway container would let onboarding report success and then lose everything on the next
/// launch — exactly the dishonesty ``FoodgeError/storeUnavailable`` exists to prevent. Failure
/// shows a screen with a retry instead. Demonstration mode is the opposite case and says so: it is
/// labelled everywhere it appears, and it is the user who asks for it.
///
/// The explicit loading state lets SwiftUI present the branded launch view before the synchronous
/// container open begins. `Task.yield()` gives that first frame a chance to render without adding
/// an artificial delay to every launch.
///
/// The session lives here rather than in a second object because this type already holds the
/// container/dependency pair and is the only thing `FoodgeApp` switches on; two owners would mean
/// two things that must agree about which container is in the environment (D98).
@MainActor
@Observable
final class AppLaunch {
    enum State {
        case loading
        case ready(AppSession)
        case storeUnavailable(FoodgeError)
    }

    private(set) var state: State = .loading

    /// Set when starting a demonstration failed. The live session keeps running; this is what
    /// Settings shows so the failure is reported as a failed demonstration rather than as a broken
    /// store.
    private(set) var demonstrationFailure: FoodgeError?

    /// The live session, kept alive for the whole run of the app.
    ///
    /// Retained rather than reopened, so leaving a demonstration is synchronous and **cannot
    /// fail**: reopening would put `storeUnavailable` on the path back from a demonstration, which
    /// is the worst possible moment for it.
    private var liveSession: AppSession?

    /// How the live container is opened. Injectable so that entering and leaving a demonstration —
    /// and the `storeUnavailable` path, previously untested — can be proved against a temporary
    /// store instead of the real one in Application Support (D104).
    @ObservationIgnored private let openLive: @MainActor () throws -> ModelContainer

    /// How a demonstration session is built. Injectable for the same reason as ``openLive``: the
    /// "a failed demonstration leaves the live session running" path has no other way to be
    /// reached, since opening an in-memory container does not fail on request (D104).
    @ObservationIgnored private let openDemonstration: @MainActor (DemonstrationScenarioID) async throws -> AppSession

    init(
        openLive: @escaping @MainActor () throws -> ModelContainer = { try ContainerFactory.makeLive() },
        openDemonstration: @escaping @MainActor (DemonstrationScenarioID) async throws -> AppSession
            = { try await DemonstrationSessionFactory.make($0) }
    ) {
        self.openLive = openLive
        self.openDemonstration = openDemonstration
    }

    func load() async {
        guard case .loading = state else { return }

        await Task.yield()
        state = open()
    }

    func retry() {
        state = .loading
    }

    /// Replaces the whole session with a labelled demonstration.
    ///
    /// **`state` is touched only on success** (D105). It is tempting to show `CourtLoadingView`
    /// while the container opens, the way `load()` does — but `FoodgeApp` switches on `state`, so
    /// passing through a loading case and back tears down `AppRootView` → `MainTabView` →
    /// `TodayFlowView` and everything they hold in `@State`. On the success path that teardown is
    /// the entire point (D98). On the **failure** path it would throw away an in-progress verdict
    /// flow for nothing, and take the failure message with it: the rebuilt `TodayFlowView` has a
    /// fresh `isShowingSettings = false`, so nothing would be left on screen to render
    /// ``demonstrationFailure``. Found by `arc-audit-accessibility`.
    ///
    /// Starting a second scenario while one runs is safe — `liveSession` stays stashed and a
    /// brand-new container replaces the old demonstration one, so nothing leaks between scenarios.
    func startDemonstration(_ id: DemonstrationScenarioID) async {
        guard currentLiveSession != nil else { return }

        demonstrationFailure = nil

        do {
            state = .ready(try await openDemonstration(id))
        } catch {
            // Nothing about the session changes: the live one was never stood down, so there is
            // no state to put back. Only the flag moves, and the Settings sheet the user is still
            // looking at renders it.
            demonstrationFailure = (error as? FoodgeError) ?? .storeUnavailable
            DemonstrationLog.logger.error("DEMO start=failed scenario=\(id.rawValue, privacy: .public)")
        }
    }

    /// Returns to the live session. Synchronous, and cannot fail.
    func exitDemonstration() {
        guard let live = liveSession else { return }
        demonstrationFailure = nil
        state = .ready(live)
    }

    /// The live session if one has been opened, remembering it the first time.
    private var currentLiveSession: AppSession? {
        if let liveSession { return liveSession }
        guard case let .ready(session) = state, !session.isDemonstration else { return nil }
        liveSession = session
        return session
    }

    /// The enum is what lets the failure path exist without a force unwrap.
    ///
    /// The failure is logged under the same `ONBOARDING` marker family as the rest of the launch
    /// decision, deliberately: on a physical device the console is the only instrument (D21), and
    /// a store that refuses to open otherwise looks exactly like an app that logged nothing at
    /// all. The label says what happened and never why — no path, no underlying error.
    private func open() -> State {
        do {
            let container = try openLive()
            let session = AppSession(container: container, dependencies: AppDependencies(container: container))
            liveSession = session
            return .ready(session)
        } catch {
            OnboardingLog.logger.error("ONBOARDING launch store=unavailable")
            return .storeUnavailable(.storeUnavailable)
        }
    }
}
