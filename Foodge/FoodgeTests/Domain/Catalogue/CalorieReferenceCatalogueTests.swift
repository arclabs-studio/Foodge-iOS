//
//  CalorieReferenceCatalogueTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation
import Testing
@testable import Foodge

/// Pins the shape of the reference dataset against values re-typed by hand from the product
/// brief (docs/foodge-plan.md), independently of the production constants themselves.
@Suite("Calorie reference catalogue", .tags(.unit, .domain))
struct CalorieReferenceCatalogueTests {
    @Test("The initial reference set is the three verified Spanish McDonald's items")
    func theInitialReferenceSetIsTheThreeVerifiedSpanishItems() throws {
        // Given the compiled-in reference dataset
        let all = CalorieReferenceCatalogue.all

        // Then it holds exactly the three verified items from the brief, with country, product,
        // portion, URL and kilocalorie figure all preserved (docs/foodge-plan.md:222-229)
        #expect(all.count == 3)

        let bigMac = try #require(all.first { $0.id == "calorieReference.es.mcdonalds.bigMac" })
        #expect(bigMac.regionCode == "ES")
        #expect(bigMac.productName == "McDonald's Spain Big Mac")
        #expect(bigMac.portionDescription == "Sandwich only — excludes drinks and sides")
        #expect(bigMac.kilocalories == 544)
        #expect(bigMac.source.absoluteString == "https://mcdonalds.es/productos/sandwiches-principales/bigmac")

        let hamburger = try #require(all.first { $0.id == "calorieReference.es.mcdonalds.hamburger" })
        #expect(hamburger.regionCode == "ES")
        #expect(hamburger.productName == "McDonald's Spain hamburger")
        #expect(hamburger.portionDescription == "Sandwich only — excludes drinks and sides")
        #expect(hamburger.kilocalories == 258)
        #expect(hamburger.source.absoluteString == "https://mcdonalds.es/productos/happy-meal/hamburguesa-happy-meal1")

        let cheeseburger = try #require(all.first { $0.id == "calorieReference.es.mcdonalds.cheeseburger" })
        #expect(cheeseburger.regionCode == "ES")
        #expect(cheeseburger.productName == "McDonald's Spain cheeseburger")
        #expect(cheeseburger.portionDescription == "Sandwich only — excludes drinks and sides")
        #expect(cheeseburger.kilocalories == 306)
        #expect(
            cheeseburger.source.absoluteString
                == "https://mcdonalds.es/productos/happy-meal/hamburguesa-con-queso-happy-meal1-new"
        )

        // And every reference was verified on the same date the brief names: 17 September 2026
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        let expectedVerifiedOn = DateComponents(year: 2026, month: 9, day: 17)
        for reference in all {
            let components = calendar.dateComponents([.year, .month, .day], from: reference.verifiedOn)
            #expect(components.year == expectedVerifiedOn.year)
            #expect(components.month == expectedVerifiedOn.month)
            #expect(components.day == expectedVerifiedOn.day)
        }
    }

    @Test("No catalogue dish variant is wired to one of these references")
    func noCatalogueDishVariantIsWiredToAReference() {
        // Given the compiled-in dish catalogue and the calorie reference set
        // Then no variant claims one of these ids — the brief forbids applying a specific
        // product's figure to a different product (D50); wiring is deferred to a future flow
        let referenceIDs = Set(CalorieReferenceCatalogue.all.map(\.id))
        for entry in DishCatalogue.entries {
            if let referenceID = entry.variant.calorieReferenceID {
                #expect(!referenceIDs.contains(referenceID), "\(entry.id) should not claim a reference id yet")
            }
        }
    }
}
