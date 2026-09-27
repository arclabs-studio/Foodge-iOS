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
    let demonstration: DemonstrationControls

    @State private var isShowingSettings = false

    /// The same controls, with **exit** wrapped so the sheet closes first.
    ///
    /// Switching sessions re-identifies the whole root (`.id(session.id)`, D98), which destroys
    /// this view along with the presenter of an open sheet. Leaving a demonstration cannot fail,
    /// so dismissing first is free and keeps UIKit from tearing down a presentation whose
    /// presenter has already gone.
    ///
    /// **Starting one is deliberately not wrapped** (D105). It can fail, and dismissing first
    /// would close the only screen able to report that — the scenario list is where
    /// `controls.failure` renders and where its announcement is posted. On the success path the
    /// `.id` teardown takes the sheet with it, which is what the exit wrapper exists to avoid;
    /// this is the one place that trade is worth making, and the console is checked for
    /// presentation warnings on the simulator because of it.
    private var sheetSafeControls: DemonstrationControls {
        DemonstrationControls(
            running: demonstration.running,
            failure: demonstration.failure,
            start: demonstration.start,
            exit: {
                isShowingSettings = false
                demonstration.exit()
            }
        )
    }

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
            SettingsView(
                vm: settings,
                onLocalDataErased: onLocalDataErased,
                demonstration: sheetSafeControls
            )
        }
    }
}

#Preview(traits: .sampleData) {
    TodayFlowView(
        vm: PreviewDependencies.all.makeTodayViewModel(),
        settings: PreviewDependencies.all.makeSettingsViewModel(),
        onLocalDataErased: {},
        demonstration: .previewInert
    )
}
