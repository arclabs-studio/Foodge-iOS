//
//  PreferencesDraft.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation

/// The preferences a screen has gathered, in a form that can cross an actor boundary.
///
/// Live `@Model` objects are bound to the context that created them and must never be handed to
/// another actor, so the persistence actor is given this instead.
struct PreferencesDraft: Hashable, Sendable {
    var dietProfile: DietProfile
    var excludedIngredientIDs: Set<String>
    var favouriteFamilies: [DishFamily]
    var dinnerRoutine: DinnerTime?
    /// Set when the draft is the one that finishes onboarding; left `nil` by later edits so a
    /// change of diet cannot rewrite when onboarding happened.
    var onboardingCompletedAt: Date?
    var narrationEnabled: Bool
    var reminderHour: Int?
    var reminderMinute: Int?

    init(
        dietProfile: DietProfile = .omnivore,
        excludedIngredientIDs: Set<String> = [],
        favouriteFamilies: [DishFamily] = [],
        dinnerRoutine: DinnerTime? = nil,
        onboardingCompletedAt: Date? = nil,
        narrationEnabled: Bool = true,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil
    ) {
        self.dietProfile = dietProfile
        self.excludedIngredientIDs = excludedIngredientIDs
        self.favouriteFamilies = favouriteFamilies
        self.dinnerRoutine = dinnerRoutine
        self.onboardingCompletedAt = onboardingCompletedAt
        self.narrationEnabled = narrationEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }
}
