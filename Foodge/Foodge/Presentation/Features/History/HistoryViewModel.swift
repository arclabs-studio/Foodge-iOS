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

        /// A bare state label, safe to log. Not even the number of cases: a count is derived
        /// from Health-backed data and would reveal usage cadence in a sysdiagnose.
        var logLabel: String {
            switch self {
            case .loading: "loading"
            case .loaded: "loaded"
            case .error: "error"
            }
        }
    }

    private(set) var stage: Stage = .loading
    /// The loaded cases grouped by month, most recent first — the sections the list draws. Built once
    /// per load rather than in the view's body; empty until a load succeeds, and again after one fails.
    private(set) var months: [HistoryMonth] = []
    var path: [HistoryRoute] = []

    @ObservationIgnored private let caseStore: any CaseStore

    init(caseStore: any CaseStore) {
        self.caseStore = caseStore
    }

    /// Fetches every saved case fresh. Called on every appearance of the tab, not just the first.
    func load() async {
        do {
            let cases = try await caseStore.allCases()
            months = HistoryMonth.grouping(cases)
            transition(to: .loaded(cases))
        } catch {
            months = []
            transition(to: .error(.storeUnavailable))
        }
    }

    private func transition(to newStage: Stage) {
        stage = newStage
        HistoryLog.logger.info("HISTORY stage=\(newStage.logLabel, privacy: .public)")
    }
}
