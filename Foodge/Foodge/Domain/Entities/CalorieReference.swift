//
//  CalorieReference.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// A verified calorie value for one named product portion in one country.
///
/// Foodge shows a dish calorie figure only when the user picks a reference like this or supplies
/// a known value with its source. A generic burger has no automatic calorie value, and a
/// reference is never applied to a different product or read as an endorsement.
struct CalorieReference: Hashable, Codable, Sendable, Identifiable {
    let id: String
    /// ISO region code the product is sold in, because portions differ by market.
    let regionCode: String
    let productName: String
    let portionDescription: String
    let kilocalories: Double
    let source: URL
    let verifiedOn: Date
}
