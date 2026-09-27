//
//  MainTabView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The app after onboarding: Today and History, each owning its own navigation stack.
@MainActor
struct MainTabView: View {
    @State private var today: TodayViewModel
    @State private var history: HistoryViewModel
    @State private var settings: SettingsViewModel
    /// Passed down to Settings, and called once the local store has actually been emptied.
    private let onLocalDataErased: () -> Void
    /// Starting, reporting on and leaving a demonstration — all of it owned by `AppLaunch` and
    /// passed straight through to Settings.
    private let demonstration: DemonstrationControls

    /// A custom `init` because the view models need the composition root's dependencies —
    /// the same reasoning as `AppRootView`'s. Building them here, once, and holding them in
    /// `@State` is what keeps `today`'s navigation path and in-progress stage (and `history`'s
    /// own path) alive across every body re-evaluation this view goes through; calling
    /// `dependencies.makeTodayViewModel()` directly in `body` would silently hand `TodayFlowView`
    /// a brand-new view model — and discard the visible verdict, or mid-flow check-in — every
    /// time anything upstream (an `@Query` refresh in `AppRootView`, say) causes this view to
    /// re-render. Settings is held the same way, so an open sheet keeps its loaded preferences.
    init(
        dependencies: AppDependencies,
        demonstration: DemonstrationControls,
        onLocalDataErased: @escaping () -> Void
    ) {
        _today = State(wrappedValue: dependencies.makeTodayViewModel())
        _history = State(wrappedValue: dependencies.makeHistoryViewModel())
        _settings = State(wrappedValue: dependencies.makeSettingsViewModel())
        self.demonstration = demonstration
        self.onLocalDataErased = onLocalDataErased
    }

    var body: some View {
        TabView {
            Tab("Today", systemImage: "fork.knife") {
                TodayFlowView(
                    vm: today,
                    settings: settings,
                    onLocalDataErased: onLocalDataErased,
                    demonstration: demonstration
                )
            }

            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryFlowView(vm: history)
            }
        }
        // The floating tab bar sits over the content it is scrolled past, so the last rows of a
        // long `Form` read *underneath* it — measured on the simulator at 46 pt of overlap on the
        // verdict screen's disclaimer, and on the phone in WU-25-A as an unreadable flourish.
        // Minimizing on a downward scroll is the platform's own answer (iOS 26+), and it keeps
        // the bar reachable rather than hiding it: it expands again the moment the user scrolls
        // back up.
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview(traits: .completedOnboarding) {
    MainTabView(dependencies: PreviewDependencies.all, demonstration: .previewInert) {}
}
