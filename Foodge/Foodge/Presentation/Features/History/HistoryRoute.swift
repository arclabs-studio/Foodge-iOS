//
//  HistoryRoute.swift
//  Foodge
//
//  Created by ARC Labs Studio on 23/09/2026.
//

import Foundation

/// The destinations the History flow can push.
///
/// Carries the ``SavedCase`` value directly, unlike `TodayRoute.evidenceDetails` (which reads
/// `vm.currentRevision` at the destination): `SavedCase` is already documented as "the form built
/// to cross a boundary," so handing it straight to the route avoids a redundant optional unwrap.
enum HistoryRoute: Hashable, Sendable {
    case caseDetail(SavedCase)
}
