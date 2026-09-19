//
//  NarrationAvailability.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation
import FoundationModels

/// Whether the on-device model can narrate right now, and why not when it cannot.
///
/// Every case other than ``available`` leads to the same place — the reviewed template — so the
/// app works identically with Apple Intelligence off, unsupported or still downloading. The
/// distinction exists only so Settings can explain the situation honestly.
///
/// **No caller until WU-23-A**, which is its named consumer. The feasibility probe that
/// exercised it on device was removed in WU-19-D; this type is a deliberate stub, not dead code
/// left behind. It was device-proven on Day 18.
enum NarrationAvailability: Hashable, Sendable {
    case available
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    /// A reason this version of the app does not know about. Treated exactly like the others.
    case unavailableForAnotherReason

    /// Reads the system model's current availability.
    static var current: NarrationAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            .available
        case .unavailable(.deviceNotEligible):
            .deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            .appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            .modelNotReady
        case .unavailable:
            .unavailableForAnotherReason
        }
    }

    var canNarrate: Bool { self == .available }
}
