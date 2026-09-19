//
//  OnboardingRoute.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// The destinations the onboarding flow can push.
///
/// Welcome is the stack's root rather than a case: a route that can be pushed on top of itself
/// is a route someone will eventually push on top of itself.
enum OnboardingRoute: Hashable, Sendable {
    case healthConnection
    case preferences
}
