//
//  FixtureFailure.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// An error that is deliberately none of Foodge's own.
///
/// Used where the point is that the code must handle *any* error, not just the ones it knows
/// the names of — a catch that only recognises `FoodgeError` would pass with a Foodge error and
/// fail here.
struct FixtureFailure: Error, Hashable {
    let label: String

    init(_ label: String = "fixture") {
        self.label = label
    }
}
