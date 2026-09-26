//
//  DemonstrationControls.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// What a screen needs in order to start, report on, or leave a demonstration.
///
/// One value rather than three parameters, because all four views in the chain
/// (`AppRootView` → `MainTabView` → `TodayFlowView` → `SettingsView`) pass the whole set
/// straight down and none of them uses one part without the others. It carries closures rather
/// than a reference to `AppLaunch`: the session owner is an App-layer type, and Presentation may
/// not name it (D34).
@MainActor
struct DemonstrationControls {
    /// The scenario currently running, or `nil` when the live session is the one on screen.
    let running: DemonstrationScenarioID?
    /// Set when the last attempt to start one failed. The live session kept running.
    let failure: FoodgeError?
    let start: (DemonstrationScenarioID) -> Void
    let exit: () -> Void

    var isRunning: Bool { running != nil }
}
