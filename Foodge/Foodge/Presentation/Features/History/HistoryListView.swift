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
                    ContentUnavailableView {
                        Label {
                            Text("No cases yet")
                        } icon: {
                            // The judge with nothing on the docket yet (D145). Decorative: the
                            // title says what the screen is. Capped in size because this view does
                            // not scroll and the text needs the room; in Spanish at AX 5 the title
                            // and the description fill the screen and the system leaves it out.
                            JudgeBadgeView(artwork: .judgeWelcome)
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        }
                    } description: {
                        Text("Once Foodge has ruled on a day, it is filed here with the evidence it used.")
                            // The system draws a description in `.secondary`, about 3.4:1 on a
                            // light background; `appBurgundyMuted` is measured there (D134).
                            .foregroundStyle(.appBurgundyMuted)
                    }
                } else {
                    // One section per month (WU-29-H), most recent first. No totals and no streaks:
                    // a count of days eaten is a score, and the voice rules keep scores off food (D118).
                    List(vm.months) { month in
                        Section {
                            ForEach(month.cases, id: \.localDayKey) { savedCase in
                                if let revision = savedCase.latestRevision {
                                    NavigationLink(value: HistoryRoute.caseDetail(savedCase)) {
                                        HistoryCaseRow(revision: revision)
                                    }
                                }
                            }
                        } header: {
                            if let firstDay = month.firstDay {
                                Text(firstDay, format: HistoryMonth.headerFormat)
                                    .formCaption()
                            }
                        }
                    }
                }
            case .error:
                ContentUnavailableView {
                    Label(loadFailureMessage, systemImage: "exclamationmark.triangle")
                } description: {
                    Text("Something went wrong reading your saved cases.")
                        .foregroundStyle(.appBurgundyMuted)
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
