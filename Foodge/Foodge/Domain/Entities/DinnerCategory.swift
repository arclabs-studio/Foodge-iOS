//
//  DinnerCategory.swift
//  Foodge
//
//  Created by ARC Labs Studio on 18/09/2026.
//

import Foundation

/// The three dinner categories Foodge can rule for.
///
/// These are editorial product categories, not validated nutritional advice. "Light" in
/// particular makes no claim about a verified calorie value.
enum DinnerCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case treat
    case balanced
    case light
}
