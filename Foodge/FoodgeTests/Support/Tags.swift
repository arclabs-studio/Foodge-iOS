//
//  Tags.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Testing

extension Tag {
    /// Pure, in-process, no I/O.
    @Tag static var unit: Self
    /// Crosses a real boundary such as a store or a container.
    @Tag static var integration: Self
    /// Drives the interface. Declared for completeness; the UI tests themselves stay in XCTest.
    @Tag static var ui: Self
    /// A decision branch the product's correctness depends on.
    @Tag static var critical: Self
    /// Exercises domain rules rather than plumbing.
    @Tag static var domain: Self
}
