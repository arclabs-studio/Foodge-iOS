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
    /// Whether the recorded days may be used as a baseline at all.
    ///
    /// The standing answer, not a per-day one: `false` means "these fourteen days do not reflect
    /// how I usually live". Defaults to `true` because unasked means "use my data", which is what
    /// someone who skipped the Health step expects. The separate per-day confirmation the
    /// category rule asks for is not this (D32).
    var trackingRepresentative: Bool
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
        trackingRepresentative: Bool = true,
        onboardingCompletedAt: Date? = nil,
        narrationEnabled: Bool = true,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil
    ) {
        self.dietProfile = dietProfile
        self.excludedIngredientIDs = excludedIngredientIDs
        self.favouriteFamilies = favouriteFamilies
        self.dinnerRoutine = dinnerRoutine
        self.trackingRepresentative = trackingRepresentative
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
