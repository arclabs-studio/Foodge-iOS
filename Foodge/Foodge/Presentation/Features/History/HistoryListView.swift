//
//  HistoryListView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import SwiftUI

/// Every day Foodge has ruled on, most recent first.
@MainActor
struct HistoryListView: View {
    @Bindable var vm: HistoryViewModel

    var body: some View {
        Group {
            switch vm.stage {
            case .loading:
                ProgressView()
            case let .loaded(cases):
                if cases.isEmpty {
                    ContentUnavailableView(
                        "No cases yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Once Foodge has ruled on a day, it is filed here with the evidence it used.")
                    )
                } else {
                    List(cases, id: \.localDayKey) { savedCase in
                        if let revision = savedCase.latestRevision {
                            NavigationLink(value: HistoryRoute.caseDetail(savedCase)) {
                                HistoryCaseRow(revision: revision)
                            }
                        }
                    }
                }
            case .error:
                ContentUnavailableView {
                    Label("Couldn’t load history", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("Something went wrong reading your saved cases.")
                } actions: {
                    Button("Try again") {
                        Task { await vm.load() }
                    }
                }
            }
        }
        .navigationTitle("History")
        .task { await vm.load() }
    }
}

/// One row: the day and the category Foodge ruled.
@MainActor
private struct HistoryCaseRow: View {
    let revision: SavedRevision

    var body: some View {
        HStack {
            Text(revision.createdAt, format: .dateTime.year().month().day())
            Spacer()
            Text(revision.decision.category.displayName)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Empty", traits: .sampleData) {
    NavigationStack {
        HistoryListView(vm: PreviewDependencies.all.makeHistoryViewModel())
    }
}

#Preview("Populated", traits: .sampleData) {
    NavigationStack {
        HistoryListView(vm: PreviewDependencies.historyPopulated.makeHistoryViewModel())
    }
}
