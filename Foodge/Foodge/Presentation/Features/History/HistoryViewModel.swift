//
//  HistoryViewModel.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import Foundation
import OSLog

/// Drives the History tab: every case Foodge has ruled on, most recent first.
///
/// `load()` never guards on the current stage — unlike `TodayViewModel.onAppear()`'s
/// `guard case .gathering …` — because every tab revisit must re-fetch: History exists purely to
/// reflect whatever Today most recently saved.
@MainActor
@Observable
final class HistoryViewModel {
    /// Where the list currently stands.
    enum Stage: Sendable {
        case loading
        case loaded([SavedCase])
        case error(FoodgeError)

        /// A label that is safe to log — the count for `.loaded`, never the cases themselves.
        var logLabel: String {
            switch self {
            case .loading: "loading"
            case let .loaded(cases): "loaded(\(cases.count))"
            case .error: "error"
            }
        }
    }

    private(set) var stage: Stage = .loading
    var path: [HistoryRoute] = []

    @ObservationIgnored private let caseStore: any CaseStore

    init(caseStore: any CaseStore) {
        self.caseStore = caseStore
    }

    /// Fetches every saved case fresh. Called on every appearance of the tab, not just the first.
    func load() async {
        do {
            let cases = try await caseStore.allCases()
            transition(to: .loaded(cases))
        } catch {
            transition(to: .error(.storeUnavailable))
        }
    }

    private func transition(to newStage: Stage) {
        stage = newStage
        HistoryLog.logger.info("HISTORY stage=\(newStage.logLabel, privacy: .public)")
    }
}
