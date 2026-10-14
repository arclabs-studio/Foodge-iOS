//
//  MealPortion+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

extension MealPortion {
    /// How a portion is named for the person answering.
    ///
    /// No figures: the kilocalorie buckets behind these words are editorial (D116), and printing
    /// them beside the choice would present an invented number as a measurement.
    var displayName: LocalizedStringResource {
        switch self {
        case .skipped:
            LocalizedStringResource("Skipped it", comment: "Meal portion: the meal was not eaten at all")
        case .light:
            LocalizedStringResource("Light", comment: "Meal portion: a small meal")
        case .normal:
            LocalizedStringResource("Normal", comment: "Meal portion: an ordinary meal")
        case .heavy:
            LocalizedStringResource("Heavy", comment: "Meal portion: a large meal")
        }
    }
}

extension MealSlot {
    /// How a meal is named for the person answering.
    var displayName: LocalizedStringResource {
        switch self {
        case .breakfast:
            LocalizedStringResource("Breakfast", comment: "Meal slot: breakfast")
        case .lunch:
            LocalizedStringResource("Lunch", comment: "Meal slot: lunch")
        case .snacks:
            LocalizedStringResource("Snacks", comment: "Meal slot: anything eaten between meals")
        }
    }
}

extension Optional where Wrapped == MealPortion {
    /// Every answer a meal row offers, "Not answered" first. It is not "Skipped it": a skipped meal is
    /// an answer worth zero, an unanswered one is no basis at all (D114).
    static var answers: [MealPortion?] {
        [nil] + MealPortion.allCases.map(Optional.some)
    }

    /// An answer as the person reads it — the one source for the row's value and its menu entry, so
    /// VoiceOver never announces a value the menu does not list.
    var displayName: LocalizedStringResource {
        switch self {
        case let .some(portion):
            portion.displayName
        case .none:
            LocalizedStringResource(
                "Not answered",
                comment: "Meal portion: no answer given yet — not the same as having skipped the meal"
            )
        }
    }
}
