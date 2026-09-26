//
//  SleepIntervalUnion.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Reduces overlapping asleep intervals to the time actually spent asleep.
///
/// Health reports sleep as many records that can overlap — several sources, and individual
/// stages nested inside a longer span. Adding their durations would invent hours, so the only
/// correct reading is the union.
enum SleepIntervalUnion {
    /// The total time covered by `intervals`, counting any overlap once.
    ///
    /// The result is zero for an empty input. That is the union of nothing, not a claim that
    /// someone did not sleep — deciding between "slept nothing" and "nothing readable" is the
    /// caller's job, and the evidence layer keeps the two apart by leaving the aggregate `nil`.
    static func duration(of intervals: [DateInterval]) -> Duration {
        // Sorting first is what makes the merge correct: Health returns samples in whatever
        // order the query produced, and merging unsorted spans anchors on the wrong one.
        let sorted = intervals.sorted { $0.start < $1.start }

        var seconds = 0.0
        var current: DateInterval?

        for interval in sorted {
            guard let open = current else {
                current = interval
                continue
            }

            if interval.start <= open.end {
                // Overlapping or touching: extend the open span, but only forwards — a record
                // wholly inside the open one must not shorten it.
                current = DateInterval(start: open.start, end: max(open.end, interval.end))
            } else {
                seconds += open.duration
                current = interval
            }
        }

        if let open = current {
            seconds += open.duration
        }

        return .seconds(seconds)
    }
}
