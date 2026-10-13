//
//  DinnerCategory+ShareBand.swift
//  Foodge
//
//  Created by ARC Labs Studio on 13/10/2026.
//

import Foundation

extension DinnerCategory {
    /// Where the category's band sits on the share of today left, for the legend under the
    /// allowance gauge — a display helper over the rule's own thresholds, so the legend cannot drift
    /// from the bands the rule applies (D112). Inclusive at each band's lower edge, as the rule is.
    var shareBand: LocalizedStringResource {
        switch self {
        case .treat:
            LocalizedStringResource(
                "Treat from \(CheatMealAllowanceRule.treatShare.formatted(.percent))",
                comment: "Allowance gauge legend: a treat dinner from this share of today left upward. Use the same word as the Treat category."
            )
        case .balanced:
            LocalizedStringResource(
                "Balanced from \(CheatMealAllowanceRule.balancedShare.formatted(.percent))",
                comment: "Allowance gauge legend: a balanced dinner from this share of today left up to the treat band. Use the same word as the Balanced category."
            )
        case .light:
            LocalizedStringResource(
                "Light below \(CheatMealAllowanceRule.balancedShare.formatted(.percent))",
                comment: "Allowance gauge legend: a light dinner below this share of today left, negative included. Use the same word as the Light category."
            )
        }
    }
}
