//
//  AppLaunch.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import OSLog
import SwiftData

/// Opens the local store once, and reports honestly when it cannot.
///
/// There is deliberately **no in-memory fallback**. Silently swapping to a throwaway container
/// would let onboarding report success and then lose everything on the next launch — exactly
/// the dishonesty ``FoodgeError/storeUnavailable`` exists to prevent. Failure shows a screen
/// with a retry instead.
///
/// The explicit loading state lets SwiftUI present the branded launch view before the synchronous
/// container open begins. `Task.yield()` gives that first frame a chance to render without adding
/// an artificial delay to every launch.
@MainActor
@Observable
final class AppLaunch {
    enum State {
        case loading
        case ready(ModelContainer, AppDependencies)
        case storeUnavailable(FoodgeError)
    }

    private(set) var state: State = .loading

    func load() async {
        guard case .loading = state else { return }

        await Task.yield()
        state = Self.open()
    }

    func retry() {
        state = .loading
    }

    /// The enum is what lets the failure path exist without a force unwrap.
    ///
    /// The failure is logged under the same `ONBOARDING` marker family as the rest of the launch
    /// decision, deliberately: on a physical device the console is the only instrument (D21), and
    /// a store that refuses to open otherwise looks exactly like an app that logged nothing at
    /// all. The label says what happened and never why — no path, no underlying error.
    private static func open() -> State {
        do {
            let container = try ContainerFactory.makeLive()
            return .ready(container, AppDependencies(container: container))
        } catch {
            OnboardingLog.logger.error("ONBOARDING launch store=unavailable")
            return .storeUnavailable(.storeUnavailable)
        }
    }
}
