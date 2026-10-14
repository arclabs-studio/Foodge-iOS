//
//  BiologicalSex+DisplayName.swift
//  Foodge
//
//  Created by ARC Labs Studio on 25/09/2026.
//

import Foundation

extension BiologicalSex {
    /// How the formula's parameter is named for the person answering.
    ///
    /// Named plainly, without explaining the equation: what it selects is the version of
    /// Mifflin–St Jeor used, and the screen's own copy says the figures are only ever an estimate.
    var displayName: LocalizedStringResource {
        switch self {
        case .female:
            LocalizedStringResource("Female", comment: "Body basics: the female form of the resting-energy equation")
        case .male:
            LocalizedStringResource("Male", comment: "Body basics: the male form of the resting-energy equation")
        }
    }
}

extension Optional where Wrapped == BiologicalSex {
    /// Every answer the sex row offers, "Not given" first: declining is an answer, not a gap.
    static var answers: [BiologicalSex?] {
        [nil] + BiologicalSex.allCases.map(Optional.some)
    }

    /// An answer as the person reads it — the one source for the row's value and its menu entry, so
    /// VoiceOver never announces a value the menu does not list.
    var displayName: LocalizedStringResource {
        switch self {
        case let .some(sex):
            sex.displayName
        case .none:
            LocalizedStringResource("Not given", comment: "Body basics: the person chose not to give their sex")
        }
    }
}
