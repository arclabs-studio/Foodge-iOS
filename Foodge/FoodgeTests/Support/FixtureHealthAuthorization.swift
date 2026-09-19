//
//  FixtureHealthAuthorization.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
@testable import Foodge

/// A stand-in for the system authorization sheet.
///
/// An `actor` rather than a class with mutable state, because `@unchecked Sendable` is
/// forbidden (D11). `requestCount` is what proves the ViewModel did not ask on a device that
/// has no Health data.
actor FixtureHealthAuthorization: HealthAuthorizing {
    nonisolated let isHealthDataAvailable: Bool
    private let failure: (any Error)?
    private(set) var requestCount = 0

    init(isHealthDataAvailable: Bool = true, failure: (any Error)? = nil) {
        self.isHealthDataAvailable = isHealthDataAvailable
        self.failure = failure
    }

    func requestReadAuthorization() async throws {
        requestCount += 1
        if let failure {
            throw failure
        }
    }
}
