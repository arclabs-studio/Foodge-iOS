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
/// another actor, so the persistence actor is given this instead. It lives in Domain rather than
/// Data because ``PreferencesStore`` names it, and Presentation may not depend on Data (D34).
struct PreferencesDraft: Hashable, Sendable {
    var dietProfile: DietProfile
    var excludedIngredientIDs: Set<String>
    var favouriteFamilies: [DishFamily]
    var dinnerRoutine: DinnerTime?
    /// The body basics behind an estimated resting figure, or `nil` when they have not been given.
    ///
    /// Load-bearing rather than decorative (D117): without `basalEnergyBurned` these are the only
    /// way maintenance can be estimated at all, and `nil` means the allowance has no resting basis
    /// rather than a resting figure of zero.
    var bodyBasics: BodyBasics?
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
        bodyBasics: BodyBasics? = nil,
        onboardingCompletedAt: Date? = nil,
        narrationEnabled: Bool = true,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil
    ) {
        self.dietProfile = dietProfile
        self.excludedIngredientIDs = excludedIngredientIDs
        self.favouriteFamilies = favouriteFamilies
        self.dinnerRoutine = dinnerRoutine
        self.bodyBasics = bodyBasics
        self.onboardingCompletedAt = onboardingCompletedAt
        self.narrationEnabled = narrationEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }

    /// What the user will and will not eat, in the form the Health and catalogue layers take.
    var constraints: DietaryConstraints {
        DietaryConstraints(profile: dietProfile, excludedIngredientIDs: excludedIngredientIDs)
    }
}
