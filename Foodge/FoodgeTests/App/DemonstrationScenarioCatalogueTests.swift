//
//  DemonstrationScenarioCatalogueTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 24/09/2026.
//

@testable import Foodge
import Foundation
import Testing

/// The Domain enum and the Data catalogue are two hand-maintained lists of the same ten things
/// (D99). This suite is what stops them drifting.
@Suite("Demonstration scenario catalogue", .tags(.unit, .critical))
struct DemonstrationScenarioCatalogueTests {
    @Test("Every scenario is offered, in the order the catalogue declares them")
    func theEnumMatchesTheCatalogueExactly() {
        // Given the two lists, maintained separately
        let offered = DemonstrationScenarioID.allCases.map(\.rawValue)
        let catalogued = SyntheticScenarios.all.map(\.id)

        // Then they are the same ten ids in the same order. Adding a scenario to one side only —
        // or reordering either — fails here rather than silently dropping it from the list the
        // user is shown.
        #expect(offered == catalogued)
    }

    @Test("Every id resolves to the scenario it names")
    func eachIDResolvesToItsOwnScenario() {
        // Given each offered scenario
        for id in DemonstrationScenarioID.allCases {
            // When Data is asked for it
            let scenario = SyntheticScenarios.scenario(for: id)

            // Then the lookup returns that one, not a neighbour — the failure a copy-pasted switch
            // branch produces
            #expect(scenario.id == id.rawValue)
        }
    }

    @Test("No two scenarios are described with the same words")
    func everyTitleAndDetailIsDistinct() {
        // Given the rendered English copy for all ten
        let titles = DemonstrationScenarioID.allCases.map { String(localized: $0.displayName) }
        let details = DemonstrationScenarioID.allCases.map { String(localized: $0.detail) }

        // Then each scenario says something of its own — a duplicated line means a branch was
        // copied and never edited, which is invisible in a list until someone reads it on stage
        #expect(Set(titles).count == titles.count)
        #expect(Set(details).count == details.count)
    }
}
