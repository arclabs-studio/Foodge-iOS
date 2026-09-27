//
//  ReminderService.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Manages the single optional evening reminder.
///
/// Its content is generic and carries no Health information. Tapping it opens Today; it promises
/// no background evaluation and no background generation.
protocol ReminderService: Sendable {
    /// Schedules the reminder at a local time of day, replacing any existing one.
    func schedule(at time: DateComponents) async throws
    func cancel() async
}
