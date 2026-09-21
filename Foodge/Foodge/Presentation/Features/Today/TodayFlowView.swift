//
//  TodayFlowView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import SwiftUI

/// The Today stack: gathering, then the verdict, then evidence details.
///
/// One `NavigationStack` over a typed route, driven by the view model's path — the same shape
/// `OnboardingFlowView` uses. There is no custom router here and never will be.
@MainActor
struct TodayFlowView: View {
    @Bindable var vm: TodayViewModel

    var body: some View {
        NavigationStack(path: $vm.path) {
            TodayBeforeVerdictView(vm: vm)
                .navigationDestination(for: TodayRoute.self) { route in
                    switch route {
                    case .verdict:
                        VerdictView(vm: vm)
                    case .evidenceDetails:
                        if let revision = vm.currentRevision {
                            EvidenceDetailsView(revision: revision)
                        }
                    }
                }
        }
    }
}

#Preview(traits: .sampleData) {
    TodayFlowView(vm: PreviewDependencies.all.makeTodayViewModel())
}
