//
//  EnergyAllowance+Gauge.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import Foundation

extension EnergyAllowance {
    /// ``share`` held inside a gauge's `0...1` track, for drawing the bar only (WU-29-H).
    ///
    /// The share itself is never floored: a day eaten past maintenance has a negative share, and the
    /// figure beside the bar keeps saying so (D112). The bar simply has nothing to fill.
    var gaugeShare: Double {
        min(max(share, 0), 1)
    }
}
