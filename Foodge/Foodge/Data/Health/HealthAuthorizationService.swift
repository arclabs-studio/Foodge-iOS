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
struct HealthAuthorizationService: HealthAuthorizing, Sendable {
    private let store: HKHealthStore

    init(store: HKHealthStore = HKHealthStore()) {
        self.store = store
    }

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// Asks the system whether a request would present its sheet.
    ///
    /// `getRequestStatusForAuthorization(toShare:read:completion:)` is the only shape Apple
    /// ships — there is no `async` overload — so the continuation is the bridge, not a
    /// preference. It is resumed exactly once on every path: an error, a status, or both
    /// present (in which case the status wins, because it is the answer that was asked for).
    ///
    /// An error is reported as ``HealthRequestStatus/undetermined`` rather than thrown: not
    /// knowing whether the sheet would appear must never be the reason the user is denied the
    /// chance to see it.
    func readRequestStatus() async -> HealthRequestStatus {
        await withCheckedContinuation { continuation in
            store.getRequestStatusForAuthorization(toShare: [], read: HealthReadTypes.all) { status, _ in
                continuation.resume(returning: HealthRequestStatus(status))
            }
        }
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

/// Translates HealthKit's own answer, keeping `HKAuthorizationRequestStatus` out of the domain.
///
/// `@unknown default` rather than a wildcard: a status Apple adds later lands on
/// ``HealthRequestStatus/undetermined`` — asking again — and the compiler still says so.
private extension HealthRequestStatus {
    init(_ status: HKAuthorizationRequestStatus) {
        switch status {
        case .shouldRequest: self = .shouldRequest
        case .unnecessary: self = .alreadyAnswered
        case .unknown: self = .undetermined
        @unknown default: self = .undetermined
        }
    }
}
