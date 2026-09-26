//
//  HealthEvidenceProvider.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// Reads a dated evidence snapshot.
///
/// The real implementation talks to HealthKit; synthetic scenarios and tests supply their own.
/// Nothing above this protocol knows HealthKit exists.
protocol HealthEvidenceProvider: Sendable {
    func snapshot(
        at date: Date,
        calendar: Calendar,
        context: DailyContext,
        constraints: DietaryConstraints
    ) async throws -> EvidenceSnapshot
}
