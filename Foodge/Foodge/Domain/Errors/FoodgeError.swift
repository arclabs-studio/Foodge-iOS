//
//  FoodgeError.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// The failures Foodge can surface to a user.
///
/// Deliberately coarse: an error shown to someone must never leak internals, a Health value or a
/// query detail. In particular there is no "authorization denied" case, because HealthKit cannot
/// tell an app that.
enum FoodgeError: Error, Hashable, Sendable {
    /// Health is not available on this device.
    case healthUnavailable
    /// The authorization request itself could not be completed.
    case healthAuthorizationFailed
    /// Evidence could not be read for this evaluation.
    case evidenceUnreadable
    /// The local store could not be opened.
    case storeUnavailable
    /// A write did not complete. The result stays visible with a retry; it is never reported saved.
    case saveFailed
    /// No catalogue dish satisfies the user's constraints. Exclusions are never relaxed to avoid this.
    case noCompatibleDish
    /// An appeal was addressed to a revision id that does not exist.
    case revisionNotFound
    /// A stored blob failed to decode. Real corruption, not a foreseeable rename with a safe
    /// fallback, so this throws rather than silently defaulting.
    case caseCorrupted
}
