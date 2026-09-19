//
//  HealthAuthorizing.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// Asks for read access to Health, and reports only whether the request completed.
///
/// It deliberately cannot say whether anything was granted: HealthKit does not expose read
/// authorization, so an implementation that claimed a denial would be inventing one. Whether
/// data is readable is answered by trying to read it.
///
/// The seam exists because the real implementation presents Apple's own system sheet, which
/// nothing can drive off-device — so a ViewModel that named the concrete type would have an
/// untestable first step (D34).
protocol HealthAuthorizing: Sendable {
    /// Whether this device has Health data at all. Provable, unlike permission.
    var isHealthDataAvailable: Bool { get }

    /// - Throws: ``FoodgeError/healthUnavailable`` when the device has no Health data, or the
    ///   framework's own error when the request itself does not complete.
    func requestReadAuthorization() async throws
}
