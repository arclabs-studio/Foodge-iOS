//
//  MainTabView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The app after onboarding: Today and History, each owning its own navigation stack.
///
/// History stays a placeholder until Day 22 fills it. It is a real tab rather than a "coming
/// soon" screen so the shape of the app — and its navigation — is verified now.
@MainActor
struct MainTabView: View {
    @State private var today: TodayViewModel

    /// A custom `init` because the view model needs the composition root's dependencies —
    /// the same reasoning as `AppRootView`'s. Building it here, once, and holding it in `@State`
    /// is what keeps `today`'s navigation path and in-progress stage alive across every body
    /// re-evaluation this view goes through; a `dependencies.makeTodayViewModel()` called
    /// directly in `body` would silently hand `TodayFlowView` a brand-new view model — and
    /// discard the visible verdict, or mid-flow check-in — every time anything upstream (an
    /// `@Query` refresh in `AppRootView`, say) causes this view to re-render.
    init(dependencies: AppDependencies) {
        _today = State(wrappedValue: dependencies.makeTodayViewModel())
    }

    var body: some View {
        TabView {
            Tab("Today", systemImage: "fork.knife") {
                TodayFlowView(vm: today)
            }

            Tab("History", systemImage: "clock.arrow.circlepath") {
                NavigationStack {
                    HistoryPlaceholderView()
                }
            }
        }
    }
}

#Preview(traits: .completedOnboarding) {
    MainTabView(dependencies: PreviewDependencies.all)
}
