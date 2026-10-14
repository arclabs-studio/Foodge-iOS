//
//  HealthKind+Symbol.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import Foundation

extension HealthKind {
    /// The reading's SF Symbol (D151) — a display helper. The evidence screens draw it beside the four
    /// readings that have a row of their own (active, resting, steps, dietary energy); sleep and
    /// workouts are mapped too so the switch stays total, and `SymbolNameTests` checks every name.
    var symbolName: String {
        switch self {
        case .activeEnergy: "flame"
        case .restingEnergy: "bolt.heart"
        case .steps: "figure.walk"
        case .sleep: "bed.double"
        case .workouts: "figure.run"
        case .dietaryEnergy: "fork.knife"
        }
    }
}
