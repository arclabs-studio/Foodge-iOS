//
//  CalorieReferenceCatalogue.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

/// The initial set of verified calorie references (D50), mirroring ``DishCatalogue``'s own shape
/// (D36): a pure `Domain/Catalogue/` constant, no protocol, no `Data/` implementation.
///
/// None of ``DishCatalogue``'s 27 variants are wired to these — they are specific fast-food menu
/// items in one market, and the brief is explicit that a reference is never applied to a
/// different product. The dataset stands alone until a future flow lets a user attach one of
/// these to a specific meal.
enum CalorieReferenceCatalogue {
    private static let verifiedOn = date(year: 2026, month: 9, day: 17)

    static let bigMac = CalorieReference(
        id: "calorieReference.es.mcdonalds.bigMac",
        regionCode: "ES",
        productName: "McDonald's Spain Big Mac",
        portionDescription: "Sandwich only — excludes drinks and sides",
        kilocalories: 544,
        source: url("https://mcdonalds.es/productos/sandwiches-principales/bigmac"),
        verifiedOn: verifiedOn
    )

    static let hamburger = CalorieReference(
        id: "calorieReference.es.mcdonalds.hamburger",
        regionCode: "ES",
        productName: "McDonald's Spain hamburger",
        portionDescription: "Sandwich only — excludes drinks and sides",
        kilocalories: 258,
        source: url("https://mcdonalds.es/productos/happy-meal/hamburguesa-happy-meal1"),
        verifiedOn: verifiedOn
    )

    static let cheeseburger = CalorieReference(
        id: "calorieReference.es.mcdonalds.cheeseburger",
        regionCode: "ES",
        productName: "McDonald's Spain cheeseburger",
        portionDescription: "Sandwich only — excludes drinks and sides",
        kilocalories: 306,
        source: url("https://mcdonalds.es/productos/happy-meal/hamburguesa-con-queso-happy-meal1-new"),
        verifiedOn: verifiedOn
    )

    static let all: [CalorieReference] = [bigMac, hamburger, cheeseburger]

    /// The fallback is unreachable for the literal strings used here; it exists so this file never
    /// force-unwraps, the same reasoning as `SyntheticScenarios.date`'s `?? .distantPast`.
    private static func url(_ string: String) -> URL {
        URL(string: string) ?? URL(fileURLWithPath: "/")
    }

    /// Same unreachable-fallback idiom as `SyntheticScenarios.date` — no force-unwrap.
    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return calendar.date(from: components) ?? .distantPast
    }
}
