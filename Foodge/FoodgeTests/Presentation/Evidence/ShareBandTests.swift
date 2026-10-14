//
//  ShareBandTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 13/10/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The legend under the allowance gauge names where each band starts. It must quote the rule's own
/// thresholds — a legend that said "Treat from 20 %" would explain a rule the app does not apply.
///
/// The oracle is the threshold each band is defined by in D112 (treat from `treatShare`, balanced from
/// `balancedShare`, light below `balancedShare`), formatted the way the legend is. The tests read the
/// resolved string, so they hold in either language the test host runs in.
@Suite("Allowance gauge legend", .tags(.unit))
struct ShareBandTests {
    private let treat = CheatMealAllowanceRule.treatShare.formatted(.percent)
    private let balanced = CheatMealAllowanceRule.balancedShare.formatted(.percent)

    @Test("Treat quotes the treat threshold, and only that one")
    func treatQuotesTheTreatThreshold() {
        // When the treat band is resolved
        let text = String(localized: DinnerCategory.treat.shareBand)

        // Then it names where treat starts, not where balanced does
        #expect(text.contains(treat))
        #expect(!text.contains(balanced))
    }

    @Test("Balanced and light both quote the balanced threshold, and not the treat one", arguments: [
        DinnerCategory.balanced,
        .light,
    ])
    func balancedAndLightQuoteTheBalancedThreshold(category: DinnerCategory) {
        // When the band is resolved
        let text = String(localized: category.shareBand)

        // Then it names the one edge between balanced and light
        #expect(text.contains(balanced))
        #expect(!text.contains(treat))
    }

    @Test("The three bands read differently")
    func theBandsAreDistinct() {
        // When every band is resolved
        let texts = DinnerCategory.allCases.map { String(localized: $0.shareBand) }

        // Then no two say the same thing — balanced "from" and light "below" share a threshold
        #expect(Set(texts).count == DinnerCategory.allCases.count)
    }
}
