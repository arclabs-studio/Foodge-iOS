//
//  AppSession.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation
import SwiftData

/// One running configuration of the app: a store, the dependencies over it, and whether it is a
/// labelled demonstration.
///
/// The container and the dependencies travel together because they must always agree — the
/// dependencies read and write through a `PersistenceActor` over *this* container, and the same
/// container is what goes into the SwiftUI environment for `@Query` (D98).
///
/// ``id`` is what SwiftUI's view identity hangs off. Swapping sessions changes it, which forces
/// the whole tree to be rebuilt; `.modelContainer(_:)` alone would rebind `@Query` and leave
/// `MainTabView`'s `@State` view models — and therefore the live `TodayViewModel` — alive.
struct AppSession: Identifiable, Sendable {
    let id = UUID()
    let container: ModelContainer
    let dependencies: AppDependencies
    /// The scenario being demonstrated, or `nil` for the live session.
    let demonstration: DemonstrationScenarioID?

    var isDemonstration: Bool { demonstration != nil }

    init(container: ModelContainer, dependencies: AppDependencies, demonstration: DemonstrationScenarioID? = nil) {
        self.container = container
        self.dependencies = dependencies
        self.demonstration = demonstration
    }
}
