//
//  OnboardingFlowView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import SwiftUI

/// The onboarding stack: Welcome, then Health, then Preferences.
///
/// One `NavigationStack` over a typed route, driven by the view model's path. There is no
/// router type here and never will be — this is Apple's own pattern, and a custom one would
/// lose state restoration and deep links along with it.
@MainActor
struct OnboardingFlowView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        NavigationStack(path: $vm.path) {
            WelcomeView()
                .navigationDestination(for: OnboardingRoute.self) { route in
                    switch route {
                    case .healthConnection:
                        HealthConnectionView(vm: vm)
                    case .preferences:
                        PreferencesView(vm: vm)
                    case .ingredientExclusions:
                        IngredientExclusionsView(
                            excludedIngredientIDs: vm.draft.excludedIngredientIDs,
                            toggle: vm.toggleExclusion
                        )
                    }
                }
        }
    }
}

#Preview(traits: .sampleData) {
    OnboardingFlowView(vm: PreviewDependencies.all.makeOnboardingViewModel())
}
