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
///
/// Settings opens from the toolbar as a sheet with its own stack (`DESIGN.md` §"Screens"), so it
/// never lands on the path back from a verdict.
@MainActor
struct TodayFlowView: View {
    @Bindable var vm: TodayViewModel
    @Bindable var settings: SettingsViewModel
    let onLocalDataErased: () -> Void

    @State private var isShowingSettings = false

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
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gearshape") {
                            isShowingSettings = true
                        }
                    }
                }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(vm: settings, onLocalDataErased: onLocalDataErased)
        }
    }
}

#Preview(traits: .sampleData) {
    TodayFlowView(
        vm: PreviewDependencies.all.makeTodayViewModel(),
        settings: PreviewDependencies.all.makeSettingsViewModel()
    ) {}
}
