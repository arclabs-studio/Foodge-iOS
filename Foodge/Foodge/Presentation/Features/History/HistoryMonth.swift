//
//  HistoryMonth.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import Foundation

/// One month of History: the cases whose local day falls in it, under one section header (WU-29-H).
///
/// Built from each case's `localDayKey` — the day as the case's own time zone saw it — rather than
/// from a `Date`, so the header names the month of the case's own local day wherever the phone is
/// now. The row's date (`HistoryCaseRow`) is the revision's `createdAt` in the device's time zone, so
/// after travel across midnight a row can show a day the header's month does not contain. A section
/// whose keys cannot be read has no header.
struct HistoryMonth: Identifiable {
    /// The id of the one group that collects keys which cannot be read as a year and a month.
    static let undatedID = "undated"

    /// `yyyy-MM`, the month zero-padded, or ``undatedID``.
    let id: String
    /// `nil` only for the undated group.
    let year: Int?
    /// `1...12`; `nil` only for the undated group.
    let month: Int?
    let cases: [SavedCase]

    /// How a section header names its month: in the Gregorian calendar the grouping uses, so a person
    /// whose system calendar is another one is not shown a month the section does not hold.
    static let headerFormat = Date.FormatStyle(calendar: Calendar(identifier: .gregorian)).month(.wide).year()

    /// The first day of the month, for its section header; `nil` for the undated group.
    var firstDay: Date? {
        guard let year, let month else { return nil }
        return Calendar(identifier: .gregorian).date(from: DateComponents(year: year, month: month, day: 1))
    }

    /// Groups `cases` by the year and month of their local day key.
    ///
    /// Months appear in the order their first case does — the store returns the most recent day first,
    /// so the most recent month leads — and cases keep their order inside a month. A key that cannot
    /// be read (not at least `year-month`, a part that is not a number, a month outside `1...12`) is
    /// **not dropped**: every such case goes to one undated group, placed last.
    static func grouping(_ cases: [SavedCase]) -> [HistoryMonth] {
        var months: [HistoryMonth] = []
        var undated: [SavedCase] = []

        for savedCase in cases {
            guard let (year, month) = yearAndMonth(of: savedCase.localDayKey) else {
                undated.append(savedCase)
                continue
            }
            let id = "\(year)-\(month < 10 ? "0" : "")\(month)"
            if let index = months.firstIndex(where: { $0.id == id }) {
                months[index] = HistoryMonth(
                    id: id,
                    year: year,
                    month: month,
                    cases: months[index].cases + [savedCase]
                )
            } else {
                months.append(HistoryMonth(id: id, year: year, month: month, cases: [savedCase]))
            }
        }

        if !undated.isEmpty {
            months.append(HistoryMonth(id: undatedID, year: nil, month: nil, cases: undated))
        }
        return months
    }

    /// The year and month a `yyyy-MM-dd` key names. Unpadded parts (`2026-9-18`) read too.
    private static func yearAndMonth(of key: String) -> (Int, Int)? {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count >= 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              (1 ... 12).contains(month)
        else { return nil }
        return (year, month)
    }
}
