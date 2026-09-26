//
//  SettingsRoute.swift
//  Foodge
//
//  Created by ARC Labs Studio on 24/09/2026.
//

import Foundation

/// Where Settings can push to, as a value.
///
/// Same shape as `OnboardingRoute` and `TodayRoute`: a typed route driven by
/// `NavigationLink(value:)` and `navigationDestination(for:)`, never a router object.
enum SettingsRoute: Hashable, Sendable {
    /// The diet profile — all that is left of what used to be four preference controls (D138).
    case preferences
    case demonstration
}
