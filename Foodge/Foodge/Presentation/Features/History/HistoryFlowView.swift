//
//  HistoryFlowView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import SwiftUI

/// The History stack: the list of cases, then one case's detail.
///
/// One `NavigationStack` over a typed route, driven by the view model's path — the same shape
/// `TodayFlowView`/`OnboardingFlowView` use. There is no custom router here and never will be.
@MainActor
struct HistoryFlowView: View {
    @Bindable var vm: HistoryViewModel

    var body: some View {
        NavigationStack(path: $vm.path) {
            HistoryListView(vm: vm)
                .navigationDestination(for: HistoryRoute.self) { route in
                    switch route {
                    case let .caseDetail(savedCase):
                        CaseDetailView(savedCase: savedCase)
                    }
                }
        }
    }
}

#Preview(traits: .sampleData) {
    HistoryFlowView(vm: PreviewDependencies.historyPopulated.makeHistoryViewModel())
}
