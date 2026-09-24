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

    /// A custom `init` because the view models need the composition root's dependencies —
    /// the same reasoning as `AppRootView`'s. Building them here, once, and holding them in
    /// `@State` is what keeps `today`'s navigation path and in-progress stage (and `history`'s
    /// own path) alive across every body re-evaluation this view goes through; calling
    /// `dependencies.makeTodayViewModel()` directly in `body` would silently hand `TodayFlowView`
    /// a brand-new view model — and discard the visible verdict, or mid-flow check-in — every
    /// time anything upstream (an `@Query` refresh in `AppRootView`, say) causes this view to
    /// re-render. Settings is held the same way, so an open sheet keeps its loaded preferences.
    init(dependencies: AppDependencies, onLocalDataErased: @escaping () -> Void) {
        _today = State(wrappedValue: dependencies.makeTodayViewModel())
        _history = State(wrappedValue: dependencies.makeHistoryViewModel())
        _settings = State(wrappedValue: dependencies.makeSettingsViewModel())
        self.onLocalDataErased = onLocalDataErased
    }

    var body: some View {
        TabView {
            Tab("Today", systemImage: "fork.knife") {
                TodayFlowView(vm: today, settings: settings, onLocalDataErased: onLocalDataErased)
            }

            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryFlowView(vm: history)
            }
        }
    }
}

#Preview(traits: .completedOnboarding) {
    MainTabView(dependencies: PreviewDependencies.all) {}
}
