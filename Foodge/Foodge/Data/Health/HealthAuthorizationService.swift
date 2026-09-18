//
//  HealthAuthorizationService.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation
import HealthKit

/// Presents Apple's own Health authorization sheet and reports only whether it completed.
///
/// It deliberately cannot tell you whether the user granted anything: HealthKit does not expose
/// read authorization, and pretending otherwise would let the interface claim a denial that may
/// simply be absent data. Whether data is readable is answered by trying to read it.
///
/// The `Sendable` conformance is spelled out rather than left implicit — normally redundant on a
/// struct, but this one stores a class reference, so writing it down turns "someone puts a
/// non-Sendable type in here" from a silent loss of the guarantee into a compile error.
struct HealthAuthorizationService: Sendable {
    private let store: HKHealthStore

    init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Asks for read access to the six types in ``HealthReadTypes``, sharing nothing.
    ///
    /// - Throws: ``FoodgeError/healthUnavailable`` when the device has no Health data at all,
    ///   or the framework's own error when the request itself fails.
    func requestReadAuthorization() async throws {
        guard isHealthDataAvailable else {
            throw FoodgeError.healthUnavailable
        }
        try await store.requestAuthorization(toShare: [], read: HealthReadTypes.all)
    }
}
