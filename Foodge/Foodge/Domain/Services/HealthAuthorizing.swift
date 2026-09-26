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

    /// Whether asking for authorization would actually put Apple's sheet on screen.
    ///
    /// The one thing HealthKit *will* tell an app about permission, and the only way to explain
    /// a request that returns without the user seeing anything (D137).
    ///
    /// Deliberately non-throwing: a status the system cannot determine is a
    /// ``HealthRequestStatus/undetermined``, not a failure, because not knowing whether the sheet
    /// would appear must never be the reason the user is denied the chance to see it.
    func readRequestStatus() async -> HealthRequestStatus

    /// - Throws: ``FoodgeError/healthUnavailable`` when the device has no Health data, or the
    ///   framework's own error when the request itself does not complete.
    func requestReadAuthorization() async throws
}

/// What the system says about a *future* authorization request.
///
/// Note what it is not: an answer about what was granted. `alreadyAnswered` says the user has
/// been asked about every type Foodge reads and iOS will not ask again — it says nothing about
/// which way they answered, and this app never claims to know.
enum HealthRequestStatus: Hashable, Sendable {
    /// At least one type has never been put to the user. Requesting shows the sheet.
    case shouldRequest
    /// Every type has been asked about already. Requesting returns silently, with no sheet.
    case alreadyAnswered
    /// The system could not say. Treated exactly like ``shouldRequest``, because asking again is
    /// harmless and refusing to ask on a guess is not.
    case undetermined

    /// The case name, which is the whole value — there is no payload here to leak.
    ///
    /// This one is worth logging: on a physical device the console is the only instrument (D21),
    /// and it is the line that says whether the sheet was ever going to appear.
    var logLabel: String {
        switch self {
        case .shouldRequest: "shouldRequest"
        case .alreadyAnswered: "alreadyAnswered"
        case .undetermined: "undetermined"
        }
    }
}
