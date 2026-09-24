//
//  AppRootView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import OSLog
import SwiftData
import SwiftUI

/// Root of the app's view hierarchy and the single place that decides which experience is shown.
///
/// The stored `onboardingCompletedAt` is the one source of that truth (D9). The `didFinish`
/// term beside it is a **within-session latch, set strictly after a save returned without
/// throwing** — not a second source of truth, and a failed save can never flip it. It exists
/// to cover the one thing here that can fail silently: whether `@Query` refreshes after
/// `PersistenceActor`, which owns a separate `ModelContext`, has written. Only a relaunch
/// proves the persistent half.
@MainActor
struct AppRootView: View {
    @Query private var preferences: [UserPreferences]
    @State private var onboarding: OnboardingViewModel
    private let dependencies: AppDependencies
    private let demonstration: DemonstrationControls

    /// A custom `init` because the view model needs the composition root's dependencies —
    /// the real-input-transformation case, and Apple's documented injection pattern.
    init(dependencies: AppDependencies, demonstration: DemonstrationControls) {
        self.dependencies = dependencies
        self.demonstration = demonstration
        _onboarding = State(wrappedValue: dependencies.makeOnboardingViewModel())
    }

    private var hasCompletedOnboarding: Bool {
        preferences.first?.hasCompletedOnboarding == true || onboarding.didFinish
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(dependencies: dependencies, demonstration: demonstration) {
                    // The latch above is a within-session `true` that a deletion has to clear,
                    // or someone who onboarded and then deleted in the same session would stay
                    // in the tab bar with no profile behind it. A fresh view model is the whole
                    // reset: `didFinish` starts `false` again, and the stored side is already
                    // gone. What is *not* proven here is whether `@Query` re-reads after
                    // `PersistenceActor`'s own context deleted the record — the same open
                    // question this view's own note describes, and only a device shows it.
                    onboarding = dependencies.makeOnboardingViewModel()
                }
            } else {
                OnboardingFlowView(vm: onboarding)
            }
        }
        .task {
            OnboardingLog.logger.info(
                "ONBOARDING launch completed=\(hasCompletedOnboarding, privacy: .public)"
            )
        }
    }
}

#Preview("First launch", traits: .sampleData) {
    AppRootView(dependencies: PreviewDependencies.all, demonstration: .previewInert)
}

#Preview("Onboarding already done", traits: .completedOnboarding) {
    AppRootView(dependencies: PreviewDependencies.all, demonstration: .previewInert)
}
