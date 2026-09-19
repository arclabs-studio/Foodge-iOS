//
//  AppLaunch.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import SwiftData

/// Opens the local store once, and reports honestly when it cannot.
///
/// There is deliberately **no in-memory fallback**. Silently swapping to a throwaway container
/// would let onboarding report success and then lose everything on the next launch — exactly
/// the dishonesty ``FoodgeError/storeUnavailable`` exists to prevent. Failure shows a screen
/// with a retry instead.
///
/// Building the container is synchronous and cheap, so there is no loading state and no
/// `.task`: by the time the first body runs, the answer is already known.
@MainActor
@Observable
final class AppLaunch {
    enum State {
        case ready(ModelContainer, AppDependencies)
        case storeUnavailable(FoodgeError)
    }

    private(set) var state: State

    init() {
        state = Self.open()
    }

    func retry() {
        state = Self.open()
    }

    /// The enum is what lets the failure path exist without a force unwrap.
    private static func open() -> State {
        do {
            let container = try ContainerFactory.makeLive()
            return .ready(container, AppDependencies(container: container))
        } catch {
            return .storeUnavailable(.storeUnavailable)
        }
    }
}
