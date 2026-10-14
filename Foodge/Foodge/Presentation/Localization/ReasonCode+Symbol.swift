//
//  ReasonCode+Symbol.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import Foundation

extension ReasonCode {
    /// The SF Symbol beside the reason's sentence (D151) — a display helper, not logic.
    ///
    /// The four allowance bands read as a gauge needle at four positions, so the band is not told by
    /// wording alone; `SymbolNameTests` keeps them distinct and checks every name exists.
    var symbolName: String {
        switch self {
        case .generousAllowance: "gauge.with.dots.needle.67percent"
        case .moderateAllowance: "gauge.with.dots.needle.50percent"
        case .slimAllowance: "gauge.with.dots.needle.33percent"
        case .allowanceSpent: "gauge.with.dots.needle.0percent"
        case .restingEnergyEstimated: "function"
        case .intakeEstimated: "checklist"
        case .strongActivityToday: "figure.run"
        case .shortSleep: "moon.zzz"
        case .selfReportedMore, .selfReportedUsual, .selfReportedLess: "quote.bubble"
        case .checkInSkipped: "questionmark.circle"
        }
    }
}
