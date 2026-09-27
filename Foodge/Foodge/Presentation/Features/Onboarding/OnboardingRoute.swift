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
///
/// Two destinations, where there were four. The preferences step and the ingredient-exclusions
/// screen left with D138; body basics is now the last step and carries the diet profile and the
/// single write.
enum OnboardingRoute: Hashable, Sendable {
    case healthConnection
    /// Sex, age, height and mass — load-bearing since D117, because they are the only way resting
    /// energy can be estimated when Health has none.
    case bodyBasics
}
