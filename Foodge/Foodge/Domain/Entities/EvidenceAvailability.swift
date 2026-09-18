//
//  EvidenceAvailability.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// The kinds of Health data Foodge reads. It reads nothing else and writes nothing at all.
enum HealthKind: String, Codable, CaseIterable, Hashable, Sendable {
    case activeEnergy
    case restingEnergy
    case steps
    case sleep
    case workouts
    case dietaryEnergy
}

/// How much of the evidence Foodge was actually able to read.
///
/// `readable(missing:)` lists the kinds that came back with nothing. HealthKit cannot tell an app
/// whether a read was denied or the data simply is not there, so the missing set only ever means
/// "no readable data" — never "permission denied".
enum EvidenceAvailability: Hashable, Codable, Sendable {
    /// Health is not available on this device at all.
    case healthUnavailable
    /// The user has not been through the Health connection step yet.
    case notRequested
    /// Authorization was requested; these kinds produced no readable data.
    case readable(missing: Set<HealthKind>)
}
