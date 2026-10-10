//
//  DinnerCategoryAppearanceTests.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 10/10/2026.
//

@testable import Foodge
import Foundation
import Testing
import UIKit

/// The symbol drawn on a verdict's category stamp must exist, and must belong to one category only.
///
/// A symbol name is a bare string: a typo compiles, builds and ships, and `Image(systemName:)`
/// silently draws nothing. And the stamp cannot lean on colour alone — tomato and basil measure the
/// same luminance in the light appearance — so each category needs a symbol of its own to stay
/// distinguishable (D145: colour is never the only carrier of meaning).
///
/// The oracle for both is outside the code under test: the first asks UIKit's own SF Symbols
/// catalogue whether the name resolves, and the second compares the three names with one another.
/// Neither test names a symbol, so changing which symbol a category uses is free as long as it is
/// real and unshared.
@Suite("Dinner category appearance", .tags(.unit))
@MainActor
struct DinnerCategoryAppearanceTests {
    @Test("Every category's symbol name is a real SF Symbol", arguments: DinnerCategory.allCases)
    func symbolNameResolvesToARealSymbol(category: DinnerCategory) {
        // Given a category and the symbol name it draws on its stamp
        let name = category.symbolName

        // When the system is asked for that symbol
        let image = UIImage(systemName: name)

        // Then it exists — a typo'd name would otherwise draw nothing, with no build error
        #expect(image != nil, "\(category.rawValue) names the symbol \"\(name)\", which is not an SF Symbol.")
    }

    @Test("No two categories share a symbol, so the stamp never relies on colour alone")
    func categoriesNeverShareASymbol() {
        // Given every category's symbol name
        let names = DinnerCategory.allCases.map(\.symbolName)

        // When the names are compared with one another
        let distinct = Set(names)

        // Then each category has its own: three categories, three different symbols
        #expect(
            distinct.count == names.count,
            "Categories must not share a stamp symbol, got \(names) for \(DinnerCategory.allCases.map(\.rawValue))."
        )
    }
}
