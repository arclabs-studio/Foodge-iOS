//
//  LocalDataErasing.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// Deletes everything Foodge stores on this device.
///
/// Its own seam rather than a method on ``PreferencesStore``: that protocol is about reading and
/// writing one person's preferences, and deletion is the opposite operation over a different
/// scope — every case and every revision as well. Keeping them apart means a screen that only
/// edits preferences cannot reach the delete path at all.
///
/// Apple Health records are never touched. Foodge reads Health; it does not own it.
protocol LocalDataErasing: Sendable {
    /// - Throws: ``FoodgeError/saveFailed`` if the deletion does not complete. Nothing may report
    ///   data as deleted when it is still there.
    func eraseLocalData() async throws
}
