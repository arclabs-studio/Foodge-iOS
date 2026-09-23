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

    /// A custom `init` because the view models need the composition root's dependencies —
    /// the same reasoning as `AppRootView`'s. Building them here, once, and holding them in
    /// `@State` is what keeps `today`'s navigation path and in-progress stage (and `history`'s
    /// own path) alive across every body re-evaluation this view goes through; calling
    /// `dependencies.makeTodayViewModel()` directly in `body` would silently hand `TodayFlowView`
    /// a brand-new view model — and discard the visible verdict, or mid-flow check-in — every
    /// time anything upstream (an `@Query` refresh in `AppRootView`, say) causes this view to
    /// re-render.
    init(dependencies: AppDependencies) {
        _today = State(wrappedValue: dependencies.makeTodayViewModel())
        _history = State(wrappedValue: dependencies.makeHistoryViewModel())
    }

    var body: some View {
        TabView {
            Tab("Today", systemImage: "fork.knife") {
                TodayFlowView(vm: today)
            }

            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryFlowView(vm: history)
            }
        }
    }
}

#Preview(traits: .completedOnboarding) {
    MainTabView(dependencies: PreviewDependencies.all)
}
