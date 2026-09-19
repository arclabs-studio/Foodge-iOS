//
//  UserPreferences.swift
//  Foodge
//
//  Created by ARC Labs Studio on 19/09/2026.
//

import Foundation
import SwiftData

/// Everything the user has told Foodge about themselves.
///
/// Under the SwiftData carve-out this `@Model` *is* the domain model — there is no parallel
/// entity for it. None of it is ever inferred from Health: a diet and an exclusion only ever
/// come from the person.
@Model
final class UserPreferences {
    /// Stored as the raw value so a rename in the enum cannot silently change what is persisted.
    private(set) var dietProfileRawValue: String
    /// Ingredient identifiers, never localized names, so changing a translation cannot change
    /// what someone excluded.
    var excludedIngredientIDs: [String]
    var favouriteFamilyRawValues: [String]
    var dinnerRoutineRawValue: String?
    /// Whether the recorded days may be used as a baseline at all (D32).
    ///
    /// Stored rather than recomputed because the answer is the user's, and asking again on every
    /// launch would quietly re-enable a fortnight they have already disowned. `true` by default:
    /// unasked means "use my data".
    var trackingRepresentative: Bool = true
    /// When onboarding was completed. `nil` means it has not been, and this is the single source
    /// of that truth — deleted along with the rest of the local data (D9).
    var onboardingCompletedAt: Date?
    var narrationEnabled: Bool
    /// The local time of day for the optional evening reminder, or `nil` when there is none.
    var reminderHour: Int?
    var reminderMinute: Int?

    init(
        dietProfile: DietProfile = .omnivore,
        excludedIngredientIDs: [String] = [],
        favouriteFamilies: [DishFamily] = [],
        dinnerRoutine: DinnerTime? = nil,
        trackingRepresentative: Bool = true,
        onboardingCompletedAt: Date? = nil,
        narrationEnabled: Bool = true,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil
    ) {
        self.dietProfileRawValue = dietProfile.rawValue
        self.excludedIngredientIDs = excludedIngredientIDs
        self.favouriteFamilyRawValues = favouriteFamilies.map(\.rawValue)
        self.dinnerRoutineRawValue = dinnerRoutine?.rawValue
        self.trackingRepresentative = trackingRepresentative
        self.onboardingCompletedAt = onboardingCompletedAt
        self.narrationEnabled = narrationEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
    }
}

extension UserPreferences {
    /// The stored diet, falling back to omnivore if the stored value is not one this version
    /// knows — which is the honest reading of "we cannot tell", and never silently narrows what
    /// someone is offered.
    var dietProfile: DietProfile {
        DietProfile(rawValue: dietProfileRawValue) ?? .omnivore
    }

    var favouriteFamilies: [DishFamily] {
        favouriteFamilyRawValues.compactMap(DishFamily.init(rawValue:))
    }

    var dinnerRoutine: DinnerTime? {
        dinnerRoutineRawValue.flatMap(DinnerTime.init(rawValue:))
    }

    var hasCompletedOnboarding: Bool {
        onboardingCompletedAt != nil
    }

    var constraints: DietaryConstraints {
        DietaryConstraints(
            profile: dietProfile,
            excludedIngredientIDs: Set(excludedIngredientIDs)
        )
    }

    /// Applies a draft, which is the only way these values change.
    func apply(_ draft: PreferencesDraft) {
        dietProfileRawValue = draft.dietProfile.rawValue
        excludedIngredientIDs = draft.excludedIngredientIDs.sorted()
        favouriteFamilyRawValues = draft.favouriteFamilies.map(\.rawValue)
        dinnerRoutineRawValue = draft.dinnerRoutine?.rawValue
        trackingRepresentative = draft.trackingRepresentative
        narrationEnabled = draft.narrationEnabled
        reminderHour = draft.reminderHour
        reminderMinute = draft.reminderMinute
        if let completedAt = draft.onboardingCompletedAt {
            onboardingCompletedAt = completedAt
        }
    }
}
