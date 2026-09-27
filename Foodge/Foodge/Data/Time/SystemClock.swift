//
//  SystemClock.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// The device's own clock and calendar.
///
/// `calendar` is read fresh on each access. A clock that captured it at launch would still
/// report yesterday's time zone after the user flies somewhere. `Calendar.current` is a snapshot
/// — never `.autoupdatingCurrent`, which could change underneath a computation already in
/// flight (D7).
///
/// A caller reads ``now`` and ``calendar`` **once** and passes both through a single evaluation,
/// so everything in that evaluation agrees about what day it is.
struct SystemClock: EvaluationClock {
    private let timeZoneOverride: TimeZone?

    init(timeZone: TimeZone? = nil) {
        timeZoneOverride = timeZone
    }

    var now: Date { Date() }

    var calendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = timeZoneOverride ?? .current
        return calendar
    }
}
