//
//  HistoryListView.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import Accessibility
import SwiftUI

/// Every day Foodge has ruled on, most recent first.
@MainActor
struct HistoryListView: View {
    @Bindable var vm: HistoryViewModel

    private var loadFailureMessage: LocalizedStringResource {
        "Couldn’t load history"
    }

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
                    Label(loadFailureMessage, systemImage: "exclamationmark.triangle")
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
        // The tab swaps its content in place, so VoiceOver gets no signal that the list failed
        // to load (WCAG 4.1.3). `logLabel` is the change key because `Stage` carries the cases
        // themselves and is deliberately not `Equatable`. `load()` does not return to `.loading`
        // first, so a failed "Try again" from `.error` is not a change of label and stays
        // unannounced — the visible row does not change either.
        .onChange(of: vm.stage.logLabel) { _, _ in
            guard case .error = vm.stage else { return }
            AccessibilityNotification.Announcement(String(localized: loadFailureMessage)).post()
        }
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
