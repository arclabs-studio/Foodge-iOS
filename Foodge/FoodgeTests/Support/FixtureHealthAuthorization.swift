//
//  FixtureHealthAuthorization.swift
//  FoodgeTests
//
//  Created by ARC Labs Studio on 19/09/2026.
//

@testable import Foodge
import Foundation

/// A stand-in for the system authorization sheet.
///
/// An `actor` rather than a class with mutable state, because `@unchecked Sendable` is
/// forbidden (D11). `requestCount` is what proves the ViewModel did not ask on a device that
/// has no Health data.
actor FixtureHealthAuthorization: HealthAuthorizing {
    nonisolated let isHealthDataAvailable: Bool
    private let failure: (any Error)?
    private let requestStatus: HealthRequestStatus
    private(set) var requestCount = 0
    private(set) var statusCount = 0

    init(
        isHealthDataAvailable: Bool = true,
        requestStatus: HealthRequestStatus = .shouldRequest,
        failure: (any Error)? = nil
    ) {
        self.isHealthDataAvailable = isHealthDataAvailable
        self.requestStatus = requestStatus
        self.failure = failure
    }

    func readRequestStatus() async -> HealthRequestStatus {
        statusCount += 1
        return requestStatus
    }

    func requestReadAuthorization() async throws {
        requestCount += 1
        if let failure {
            throw failure
        }
    }
}
