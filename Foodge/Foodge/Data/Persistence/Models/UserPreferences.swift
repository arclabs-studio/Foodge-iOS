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
    /// The body basics behind an estimated resting figure, stored as four separate optionals
    /// (D117).
    ///
    /// Four columns rather than one encoded blob, and each one optional, because a half-answered
    /// questionnaire has to stay readable as half-answered: ``bodyBasics`` returns `nil` unless all
    /// four parse, the same idiom as ``dinnerRoutineRawValue``. `trackingRepresentative` went the
    /// other way in the same edit; V1 is edited in place and the store is discarded by a dev
    /// reinstall rather than migrated, so the app must be deleted before the first run after this
    /// change (D110).
    var bodySexRawValue: String?
    var bodyAgeYears: Int?
    var bodyHeightCentimetres: Double?
    var bodyWeightKilograms: Double?
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
        bodyBasics: BodyBasics? = nil,
        onboardingCompletedAt: Date? = nil,
        narrationEnabled: Bool = true,
        reminderHour: Int? = nil,
        reminderMinute: Int? = nil
    ) {
        self.dietProfileRawValue = dietProfile.rawValue
        self.excludedIngredientIDs = excludedIngredientIDs
        self.favouriteFamilyRawValues = favouriteFamilies.map(\.rawValue)
        self.dinnerRoutineRawValue = dinnerRoutine?.rawValue
        self.bodySexRawValue = bodyBasics?.sex.rawValue
        self.bodyAgeYears = bodyBasics?.ageYears
        self.bodyHeightCentimetres = bodyBasics?.heightCentimetres
        self.bodyWeightKilograms = bodyBasics?.weightKilograms
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

    /// The stored basics, or `nil` unless all four parse into a plausible `BodyBasics`.
    ///
    /// A partly filled row is not a body: it produces no estimate rather than a maintenance figure
    /// computed from three answers and a guess.
    var bodyBasics: BodyBasics? {
        guard
            let sexRawValue = bodySexRawValue,
            let sex = BiologicalSex(rawValue: sexRawValue),
            let ageYears = bodyAgeYears,
            let heightCentimetres = bodyHeightCentimetres,
            let weightKilograms = bodyWeightKilograms
        else { return nil }

        return BodyBasics(
            sex: sex,
            ageYears: ageYears,
            heightCentimetres: heightCentimetres,
            weightKilograms: weightKilograms
        )
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
        bodySexRawValue = draft.bodyBasics?.sex.rawValue
        bodyAgeYears = draft.bodyBasics?.ageYears
        bodyHeightCentimetres = draft.bodyBasics?.heightCentimetres
        bodyWeightKilograms = draft.bodyBasics?.weightKilograms
        narrationEnabled = draft.narrationEnabled
        reminderHour = draft.reminderHour
        reminderMinute = draft.reminderMinute
        if let completedAt = draft.onboardingCompletedAt {
            onboardingCompletedAt = completedAt
        }
    }
}
