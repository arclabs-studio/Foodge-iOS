//
//  VerdictRevision.swift
//  Foodge
//
//  Created by ARC Labs Studio on 21/09/2026.
//

import Foundation
import SwiftData

/// One immutable revision of a case's verdict.
///
/// `sequence`, not `createdAt`, is the canonical order: two revisions created in the same
/// instant could tie on a timestamp but never on sequence.
@Model
final class VerdictRevision {
    @Attribute(.unique) var id: UUID
    var sequence: Int
    var createdAt: Date
    var dailyCase: DailyCase?

    /// `VerdictDecision` JSON-encoded whole. `CategoryBasis`'s associated values don't map to
    /// flat SwiftData columns without a second entity hierarchy, which the constitution forbids.
    var decisionData: Data
    /// `EvidenceSnapshot` JSON-encoded whole, byte-exact so a reopened case reproduces the exact
    /// evidence it was decided from.
    var evidenceData: Data
    var catalogueVersion: String

    // `PersistedDishOutcome` flattened to columns.
    var recommendedVariantID: String?
    var recommendedFamilyRawValue: String?
    var alternativeVariantID: String?
    var alternativeFamilyRawValue: String?
    var blockingIngredientIDs: [String]

    /// A validated on-device model line, written once by `attachNarration(_:to:)` and never
    /// overwritten. Stays `nil` whenever no model line was produced — the reviewed template is
    /// never persisted.
    var narrationText: String?

    @Relationship(deleteRule: .cascade, inverse: \Appeal.revision)
    var appeals: [Appeal] = []

    init(
        id: UUID = UUID(),
        sequence: Int,
        createdAt: Date,
        decisionData: Data,
        evidenceData: Data,
        catalogueVersion: String,
        dishOutcome: PersistedDishOutcome,
        narrationText: String? = nil
    ) {
        self.id = id
        self.sequence = sequence
        self.createdAt = createdAt
        self.decisionData = decisionData
        self.evidenceData = evidenceData
        self.catalogueVersion = catalogueVersion
        self.narrationText = narrationText

        switch dishOutcome {
        case let .selected(variantID, family, alternativeVariantID, alternativeFamily):
            self.recommendedVariantID = variantID
            self.recommendedFamilyRawValue = family.rawValue
            self.alternativeVariantID = alternativeVariantID
            self.alternativeFamilyRawValue = alternativeFamily?.rawValue
            self.blockingIngredientIDs = []
        case let .noMatch(blockingIngredientIDs):
            self.recommendedVariantID = nil
            self.recommendedFamilyRawValue = nil
            self.alternativeVariantID = nil
            self.alternativeFamilyRawValue = nil
            self.blockingIngredientIDs = Array(blockingIngredientIDs).sorted()
        }
    }
}

extension VerdictRevision {
    /// - Throws: ``FoodgeError/caseCorrupted`` if the stored blob does not decode.
    func decodedDecision() throws -> VerdictDecision {
        do {
            return try JSONDecoder().decode(VerdictDecision.self, from: decisionData)
        } catch {
            throw FoodgeError.caseCorrupted
        }
    }

    /// - Throws: ``FoodgeError/caseCorrupted`` if the stored blob does not decode.
    func decodedEvidence() throws -> EvidenceSnapshot {
        do {
            return try JSONDecoder().decode(EvidenceSnapshot.self, from: evidenceData)
        } catch {
            throw FoodgeError.caseCorrupted
        }
    }

    /// Reassembles the flattened columns into a ``PersistedDishOutcome``.
    ///
    /// Falls back to `.noMatch(blockingIngredientIDs: [])` only if `recommendedFamilyRawValue`
    /// somehow fails to parse as a `DishFamily` — unreachable in practice, since this project
    /// writes the raw value itself, but never force-unwrapped regardless.
    var dishOutcome: PersistedDishOutcome {
        if let recommendedVariantID,
           let recommendedFamilyRawValue,
           let family = DishFamily(rawValue: recommendedFamilyRawValue) {
            let alternativeFamily = alternativeFamilyRawValue.flatMap(DishFamily.init(rawValue:))
            return .selected(
                variantID: recommendedVariantID,
                family: family,
                alternativeVariantID: alternativeVariantID,
                alternativeFamily: alternativeFamily
            )
        }
        return .noMatch(blockingIngredientIDs: Set(blockingIngredientIDs))
    }

    /// - Throws: ``FoodgeError/caseCorrupted`` if either stored blob does not decode.
    func asSavedRevision() throws -> SavedRevision {
        SavedRevision(
            id: id,
            sequence: sequence,
            createdAt: createdAt,
            decision: try decodedDecision(),
            evidence: try decodedEvidence(),
            catalogueVersion: catalogueVersion,
            dishOutcome: dishOutcome,
            narrationText: narrationText,
            appeals: appeals.compactMap { $0.asSavedAppeal() }
        )
    }
}
