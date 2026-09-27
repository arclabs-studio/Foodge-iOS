//
//  TodayRoute.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation

/// The destinations the Today flow can push.
///
/// Before-verdict is the stack's root rather than a case, matching `OnboardingRoute`'s reasoning:
/// a route that can be pushed on top of itself is a route someone will eventually push on top of
/// itself.
enum TodayRoute: Hashable, Sendable {
    case verdict
    case evidenceDetails
}
