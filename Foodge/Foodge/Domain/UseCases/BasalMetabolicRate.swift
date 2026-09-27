//
//  BasalMetabolicRate.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

/// The Mifflin–St Jeor resting-energy estimate, used only when Health cannot supply
/// `basalEnergyBurned` (D113).
///
/// Pure and Foundation-only, with the `Calendar` injected — `.autoupdatingCurrent` appears
/// nowhere, matching `DishSelection`'s precedent — so the daylight-saving behaviour can be
/// exercised against a fixed time zone instead of the tester's own.
enum BasalMetabolicRate {
    /// Recorded alongside a stored estimate so a saved case always says which formula produced it.
    static let formulaVersion = "mifflin-st-jeor"

    /// The published equation, per 24 hours:
    /// men `10W + 6.25H − 5A + 5`, women `10W + 6.25H − 5A − 161`
    /// (W kg, H cm, A years).
    static func dailyKilocalories(for body: BodyBasics) -> Double {
        let base = 10 * body.weightKilograms
            + 6.25 * body.heightCentimetres
            - 5 * Double(body.ageYears)

        return switch body.sex {
        case .male: base + 5
        case .female: base - 161
        }
    }

    /// The daily figure scaled by how far through its own local day `window` has reached, or `nil`
    /// when the calendar cannot say how long that day is.
    ///
    /// **The fraction is clock time over the local day's real length, never over 86,400 seconds.**
    /// On the 23-hour day Spain springs forward, 19:30 is `19.5 / 23` of the day rather than
    /// `19.5 / 24`, so a short day spends its maintenance faster instead of appearing to run late.
    /// This is a product definition — "how far through today am I" — and not an integral of energy
    /// actually burned: across a skipped hour the two differ, and the figure this returns is an
    /// estimate labelled as one everywhere it is shown.
    ///
    /// `nil` rather than a zero or a silent 24-hour fallback: a proration that cannot name its own
    /// day has no honest value, and the rule has a named reason to report
    /// (`AllowanceUnavailableReason.noRestingBasis`). For a Gregorian calendar the case does not
    /// arise, which is exactly why it must not be papered over with a number.
    static func kilocalories(
        for body: BodyBasics,
        upTo window: DateInterval,
        calendar: Calendar
    ) -> Double? {
        guard let fraction = elapsedFractionOfLocalDay(at: window.end, calendar: calendar) else {
            return nil
        }
        return dailyKilocalories(for: body) * fraction
    }

    /// The share of `instant`'s own local day that the clock has already passed, clamped to
    /// `0...1`.
    private static func elapsedFractionOfLocalDay(at instant: Date, calendar: Calendar) -> Double? {
        guard
            let day = calendar.dateInterval(of: .day, for: instant),
            day.duration > 0
        else { return nil }

        let clock = calendar.dateComponents([.hour, .minute, .second], from: instant)
        let elapsedSeconds = Double((clock.hour ?? 0) * 3600 + (clock.minute ?? 0) * 60 + (clock.second ?? 0))

        return min(max(elapsedSeconds / day.duration, 0), 1)
    }
}
