//
//  EvidenceWindowPlanner.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// Works out which spans of time an evaluation is allowed to look at.
///
/// Today is measured from local midnight up to the evaluation instant, and each previous day is
/// cut at the *same local clock time* — not at the same elapsed number of seconds. Those differ
/// whenever the clocks change: 4 a.m. on the morning Spain springs forward is three hours after
/// midnight, not four. Comparing today's partial day against previous full days, or assuming
/// every day is 86,400 seconds long, is what this type exists to prevent.
enum EvidenceWindowPlanner {
    /// The window since local midnight, and the matching window on each of the previous
    /// `historyDays` completed days, oldest first.
    static func windows(
        evaluation: Date,
        calendar: Calendar,
        historyDays: Int
    ) -> (today: DateInterval, history: [DateInterval]) {
        let midnight = calendar.startOfDay(for: evaluation)
        let today = DateInterval(start: midnight, end: max(midnight, evaluation))

        let clock = calendar.dateComponents([.hour, .minute, .second], from: evaluation)

        let history: [DateInterval] = (1...max(historyDays, 0))
            .reversed()
            .compactMap { daysAgo in
                guard let dayStart = calendar.date(byAdding: .day, value: -daysAgo, to: midnight) else {
                    return nil
                }
                guard let cutoff = cutoff(matching: clock, on: dayStart, calendar: calendar) else {
                    return nil
                }
                return DateInterval(start: dayStart, end: max(dayStart, cutoff))
            }

        return (today, history)
    }

    /// The instant on `dayStart`'s day that shows the same clock time as the evaluation.
    ///
    /// Midnight is handled directly because searching forward for a time the day already starts
    /// at would step into the next day. Everything else is resolved by the calendar, which is
    /// what makes the skipped and repeated hours come out right: a clock time that does not
    /// exist resolves to the next one that does, and a repeated one to its first occurrence.
    private static func cutoff(
        matching clock: DateComponents,
        on dayStart: Date,
        calendar: Calendar
    ) -> Date? {
        let hour = clock.hour ?? 0
        let minute = clock.minute ?? 0
        let second = clock.second ?? 0

        if hour == 0, minute == 0, second == 0 {
            return dayStart
        }

        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: second,
            of: dayStart,
            matchingPolicy: .nextTime,
            repeatedTimePolicy: .first,
            direction: .forward
        )
    }
}
