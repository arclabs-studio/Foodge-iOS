//
//  ApproximateEquality.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

extension Double {
    /// Comparison for kilocalorie figures in the hundreds, where an exact `==` would depend on the
    /// order the multiplications happen in rather than on the rule being tested.
    ///
    /// The tolerance is deliberately tiny: it absorbs representation error, never a wrong
    /// denominator. `1623.75 × 11400/82800` and `1623.75 × 11400/86400` differ by ~10 kcal, so a
    /// test that means to discriminate between them still does.
    func isApproximately(_ other: Double, tolerance: Double = 1e-9) -> Bool {
        abs(self - other) <= tolerance
    }
}
