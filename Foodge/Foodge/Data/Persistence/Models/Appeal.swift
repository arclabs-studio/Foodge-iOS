//
//  Appeal.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation
import SwiftData

/// One appeal attached to a specific revision.
///
/// Exactly one of a catalogue choice (variant + family) or free text is ever populated — the
/// two named appeal outcomes `foodge-plan.md` describes.
@Model
final class Appeal {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var revision: VerdictRevision?

    var chosenVariantID: String?
    var chosenFamilyRawValue: String?
    var chosenFreeText: String?

    init(id: UUID = UUID(), createdAt: Date, choice: AppealChoice) {
        self.id = id
        self.createdAt = createdAt

        switch choice {
        case let .catalogue(variantID, family):
            self.chosenVariantID = variantID
            self.chosenFamilyRawValue = family.rawValue
            self.chosenFreeText = nil
        case let .freeText(text):
            self.chosenVariantID = nil
            self.chosenFamilyRawValue = nil
            self.chosenFreeText = text
        }
    }
}

extension Appeal {
    /// Decodes the three columns back to an ``AppealChoice``, or `nil` if none of the expected
    /// shapes is populated — which never happens through ``PersistenceActor``'s own write path.
    var choice: AppealChoice? {
        if let chosenVariantID,
           let chosenFamilyRawValue,
           let family = DishFamily(rawValue: chosenFamilyRawValue) {
            return .catalogue(variantID: chosenVariantID, family: family)
        }
        if let chosenFreeText {
            return .freeText(chosenFreeText)
        }
        return nil
    }

    /// `nil` when none of the three column shapes resolves to a choice — never happens through
    /// `PersistenceActor`'s own write path. Deliberately silent rather than throwing
    /// `FoodgeError.caseCorrupted` the way `decodedDecision()`/`decodedEvidence()` do: losing one
    /// stray appeal is a smaller footprint than failing the whole revision it is attached to.
    func asSavedAppeal() -> SavedAppeal? {
        guard let choice else { return nil }
        return SavedAppeal(id: id, createdAt: createdAt, choice: choice)
    }
}
