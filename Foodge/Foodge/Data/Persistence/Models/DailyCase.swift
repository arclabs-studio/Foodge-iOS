//
//  DailyCase.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation
import SwiftData

/// The one saved case for a local day.
///
/// Reopening this case returns its saved revisions without regenerating anything; an explicit
/// second save appends a new revision alongside the first rather than replacing it.
@Model
final class DailyCase {
    /// `"yyyy-MM-dd"`, Gregorian, computed once at write time from the revision's own evidence —
    /// never recomputed later from `Calendar.current`.
    @Attribute(.unique) private(set) var localDayKey: String

    @Relationship(deleteRule: .cascade, inverse: \VerdictRevision.dailyCase)
    var revisions: [VerdictRevision] = []

    init(localDayKey: String) {
        self.localDayKey = localDayKey
    }
}
